SHELL=bash
.DEFAULT_GOAL := help

# See https://tech.davis-hansson.com/p/make/
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.PHONY: help
help:
	@printf "\033[33mUsage:\033[0m\n  make TARGET\n\n\033[32m#\n# Commands\n#---------------------------------------------------------------------------\033[0m\n\n"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//' | awk 'BEGIN {FS = ":"}; {printf "\033[33m%s:\033[0m%s\n", $$1, $$2}'


#
# Variables
#---------------------------------------------------------------------------

CODECEPTION_ADAPTER = codeception-adpater/README.md
PHPSPEC_ADAPTER = phpspec-adpater/README.md
INFECTION = infection/README.md
INFECTION_BIN = infection/bin/infection


#
# Commands (phony targets)
#---------------------------------------------------------------------------

.PHONY: compile
test-phpspec:	 	## Test the PHPSpec Adapter
compile:
	rm $(INFECTION) || true
	make $(INFECTION)

.PHONY: compile-docker
compile-docker:	 	## Bundles Infection into a PHAR using docker
compile-docker: $(DOCKER_FILE_IMAGE)
	$(DOCKER_RUN_82) make compile

.PHONY: sbx-image-build
sbx-image-build:	## Builds the PHP sbx image
sbx-image-build:
	./devTools/sbx/build-image.sh
	./devTools/sbx/load-template.sh

.PHONY: _sbx-image-build
_sbx-image-build:
	FORCE_REBUILD=1 ./devTools/sbx/build-image.sh
	./devTools/sbx/load-template.sh

.PHONY: sbx-image-test
sbx-image-test:	## Verifies the PHP sbx image contains the expected tooling
sbx-image-test:
	container-structure-test test --image=infection-sbx-php-8.4:latest --config=./devTools/sbx/test.yaml

.PHONY: check_trailing_whitespaces
check_trailing_whitespaces:
	./devTools/check_trailing_whitespaces.sh

.PHONY: cs
cs:	  	 	## Runs PHP-CS-Fixer
cs: $(PHP_CS_FIXER)
	$(PHP_CS_FIXER) fix -v --diff
	LC_ALL=C sort -u .gitignore -o .gitignore
	$(MAKE) check_trailing_whitespaces

.PHONY: cs-docker
cs-docker:		## Runs PHP-CS-Fixer in docker
cs-docker: $(DOCKER_FILE_IMAGE) $(PHP_CS_FIXER)
	$(DOCKER_RUN_82) $(PHP_CS_FIXER) fix -v --diff
	LC_ALL=C sort -u .gitignore -o .gitignore
	$(MAKE) check_trailing_whitespaces

.PHONY: cs-check
cs-check:		## Runs PHP-CS-Fixer in dry-run mode
cs-check: $(PHP_CS_FIXER)
	$(PHP_CS_FIXER) fix -v --diff --dry-run
	LC_ALL=C sort -c -u .gitignore
	$(MAKE) check_trailing_whitespaces

.PHONY: phpstan
phpstan: vendor $(PHPSTAN)
	$(PHPSTAN) analyse --configuration devTools/phpstan.neon --no-interaction --no-progress

.PHONY: phpstan-baseline
phpstan-baseline: vendor $(PHPSTAN)
	$(PHPSTAN) analyse --configuration devTools/phpstan.neon --no-interaction --no-progress --generate-baseline devTools/phpstan-baseline.neon || true

.PHONY: mago
mago: vendor $(MAGO)
	$(MAGO) analyze

.PHONY: mago-baseline
mago-baseline: vendor $(MAGO)
	$(MAGO) analyze --generate-baseline || true

.PHONY: detect-collisions
detect-collisions: vendor $(PHPSTAN)
	$(COLLISION_DETECTOR) --configuration devTools/collision-detector.json

.PHONY: rector
rector: vendor $(RECTOR)
	$(RECTOR) process

.PHONY: rector-check
rector-check: vendor $(RECTOR)
	$(RECTOR) process --dry-run

.PHONY: validate
validate:
	composer validate --strict

.PHONY: profile
profile: 	 	## Runs Blackfire
profile:
	$(MAKE) profile_mutation_generator
	$(MAKE) profile_parse_git_diff
	$(MAKE) profile_tracing

.PHONY: benchmark
benchmark: vendor \
		$(BENCHMARK_MUTATION_GENERATOR_SOURCES) \
		$(BENCHMARK_PARSE_GIT_DIFF_SOURCE) \
		$(BENCHMARK_TRACING_SUBMODULE) \
		$(BENCHMARK_TRACING_COVERAGE_DIR)
	composer dump --classmap-authoritative --quiet
	vendor/bin/phpbench run tests/benchmark $(PHPBENCH_REPORTS)
	composer dump

.PHONY: profile_mutation_generator
profile_mutation_generator: vendor $(BENCHMARK_MUTATION_GENERATOR_SOURCES)
	composer dump --classmap-authoritative --quiet
	blackfire run \
		--title="MutationGenerator" \
		--metadata="commit=$(COMMIT_HASH)" \
		php tests/benchmark/MutationGenerator/profile.php
	composer dump

.PHONY: benchmark_mutation_generator
benchmark_mutation_generator: vendor $(BENCHMARK_MUTATION_GENERATOR_SOURCES)
	composer dump --classmap-authoritative --quiet
	vendor/bin/phpbench run tests/benchmark/MutationGenerator $(PHPBENCH_REPORTS)
	composer dump

.PHONY: profile_parse_git_diff
profile_parse_git_diff: vendor $(BENCHMARK_PARSE_GIT_DIFF_SOURCE)
	composer dump --classmap-authoritative --quiet
	blackfire run \
		--title="ParseGitDiff" \
		--metadata="commit=$(COMMIT_HASH)" \
		php tests/benchmark/ParseGitDiff/profile.php
	composer dump

.PHONY: benchmark_parse_git_diff
benchmark_parse_git_diff: vendor $(BENCHMARK_PARSE_GIT_DIFF_SOURCE)
	composer dump --classmap-authoritative --quiet
	vendor/bin/phpbench run tests/benchmark/ParseGitDiff $(PHPBENCH_REPORTS)
	composer dump

.PHONY: profile_tracing
profile_tracing: vendor $(BENCHMARK_TRACING_SUBMODULE) $(BENCHMARK_TRACING_COVERAGE_DIR)
	composer dump --classmap-authoritative --quiet
	blackfire run \
		--title="Tracing" \
		--metadata="commit=$(COMMIT_HASH)" \
		php tests/benchmark/Tracing/profile.php
	composer dump

.PHONY: benchmark_tracing
benchmark_tracing: vendor $(BENCHMARK_TRACING_SUBMODULE) $(BENCHMARK_TRACING_COVERAGE_DIR)
	composer dump --classmap-authoritative --quiet
	vendor/bin/phpbench run tests/benchmark/Tracing $(PHPBENCH_REPORTS)
	composer dump


.PHONY: autoreview
autoreview: 	 	## Runs various checks (static analysis & AutoReview test suite)
autoreview: cs-check phpstan mago validate test-autoreview rector-check detect-collisions

.PHONY: test
test:		 	## Runs all the tests
test: autoreview test-unit test-benchmark test-e2e test-infection

.PHONY: test-docker
test-docker:		## Runs all the tests on the different Docker platforms
test-docker: autoreview test-unit-docker test-e2e-docker test-infection-docker

.PHONY: test-autoreview
test-autoreview: $(PHPUNIT_BIN) vendor
	$(PHPUNIT) --configuration=phpunit_autoreview.xml

.PHONY: test-unit
test-unit:	 	## Runs the unit tests
test-unit: $(PHPUNIT_BIN) vendor
	$(PHPUNIT) --group $(PHPUNIT_GROUP) --exclude-group e2e

.PHONY: test-unit-parallel
test-unit-parallel:	## Runs the unit tests in parallel
test-unit-parallel: $(PARATEST) vendor
	$(PARATEST) --runner=WrapperRunner

.PHONY: test-unit-docker
test-unit-docker:	## Runs the unit tests on the different Docker platforms
test-unit-docker: test-unit-82-docker

test-unit-82-docker: $(DOCKER_FILE_IMAGE) $(PHPUNIT_BIN)
	$(DOCKER_RUN_82) $(PHPUNIT) --group $(PHPUNIT_GROUP)

.PHONY: test-benchmark
test-benchmark:	 	## Runs the benchmark tests
test-benchmark: $(PHPUNIT_BIN) \
		vendor \
		$(BENCHMARK_MUTATION_GENERATOR_SOURCES) \
		$(BENCHMARK_TRACING_SUBMODULE) \
		$(BENCHMARK_TRACING_COVERAGE_DIR)
	$(PHPUNIT) --group=benchmark

.PHONY: test-e2e
test-e2e: 	 	## Runs the end-to-end tests
test-e2e: test-e2e-phpunit
	./tests/e2e_tests $(INFECTION)

.PHONY: test-e2e-phpunit
test-e2e-phpunit:	## Runs PHPUnit-enabled subset of end-to-end tests
test-e2e-phpunit: $(PHPUNIT_BIN) vendor
	@if [ -x $(PARATEST) ]; then \
		$(PARATEST) --group $(E2E_PHPUNIT_GROUP); \
	else \
		$(PHPUNIT) --group $(E2E_PHPUNIT_GROUP); \
	fi

.PHONY: test-e2e-docker
test-e2e-docker: 	## Runs the end-to-end tests on the different Docker platforms
test-e2e-docker: test-e2e-xdebug-docker

.PHONY: test-e2e-xdebug-docker
test-e2e-xdebug-docker: test-e2e-xdebug-82-docker

.PHONY: test-e2e-xdebug-82-docker
test-e2e-xdebug-82-docker: $(DOCKER_FILE_IMAGE) $(INFECTION)
	$(DOCKER_RUN_82) $(PHPUNIT) --group $(E2E_PHPUNIT_GROUP)
	$(DOCKER_RUN_82) ./tests/e2e_tests $(INFECTION)

.PHONY: test-infection
test-infection:		## Runs Infection against itself
test-infection: $(INFECTION) vendor
	$(INFECTION) --threads=max

.PHONY: test-infection-docker
test-infection-docker:	## Runs Infection against itself on the different Docker platforms
test-infection-docker: test-infection-xdebug-docker

.PHONY: test-infection-xdebug-docker
test-infection-xdebug-docker: test-infection-xdebug-82-docker

.PHONY: test-infection-xdebug-82-docker
test-infection-xdebug-82-docker: $(DOCKER_FILE_IMAGE)
	$(DOCKER_RUN_82) ./bin/infection --threads=max

#
# Rules from files (non-phony targets)
#---------------------------------------------------------------------------

$(INFECTION):
	git submodule update --init infection
	touch -c $@

$(CODECEPTION_ADAPTER):
	git submodule update --init codeception-adapter
	touch -c $@

$(PHPSPEC_ADAPTER):
	git submodule update --init phpspec-adapter
	touch -c $@
