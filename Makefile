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

CODECEPTION_ADAPTER = codeception-adapter/tests/e2e/Codeception_Basic/composer.json
CODECEPTION_COPY_HASH = Codeception/.codeception-adapter-copy.hash
CODECEPTION_COPY_SOURCES = $(shell find codeception-adapter/tests/e2e/Codeception_Basic -type f 2>/dev/null)
PHPSPEC_ADAPTER = phpspec-adapter/tests/e2e/PhpSpec/README.md
PHPSPEC_COPY_HASH = PhpSpec/.phpspec-adapter-copy.hash
PHPSPEC_COPY_SOURCES = $(shell find phpspec-adapter/tests/e2e/PhpSpec -type f 2>/dev/null)
INFECTION = infection/README.md
INFECTION_BIN = infection/bin/infection
INFECTION_VENDOR = infection/vendor


#
# Commands (phony targets)
#---------------------------------------------------------------------------

.PHONY: test
test: 	## Test the adapters
test: test-phpspec test-codeception

.PHONY: test-phpspec
test-phpspec: PhpSpec/vendor	## Test the PHPSpec Adapter
	cd PhpSpec && vendor/bin/infection --test-framework=phpspec

.PHONY: test-codeception
test-codeception: Codeception/vendor	## Test the Codeception Adapter
	cd Codeception && vendor/bin/infection --test-framework=codeception


#
# Rules from files (non-phony targets)
#---------------------------------------------------------------------------

$(INFECTION):
	git submodule update --init infection
	touch -c $@

$(INFECTION_BIN): infection/vendor
	touch -c $@

infection/vendor:
	composer install --working-dir=infection
	touch -c $@

$(CODECEPTION_ADAPTER):
	git submodule update --init codeception-adapter
	touch -c $@

$(PHPSPEC_ADAPTER):
	git submodule update --init phpspec-adapter
	touch -c $@

Codeception/vendor: $(CODECEPTION_COPY_HASH)
	composer update --working-dir=Codeception --ignore-platform-req=ext-curl
	touch -c $@

$(CODECEPTION_COPY_HASH): $(CODECEPTION_ADAPTER) $(CODECEPTION_COPY_SOURCES)
	./scripts/sync-codeception-copy.sh
	touch -c $@

PhpSpec/vendor: $(PHPSPEC_COPY_HASH)
	composer update --working-dir=PhpSpec
	touch -c $@

$(PHPSPEC_COPY_HASH): $(PHPSPEC_ADAPTER) $(PHPSPEC_COPY_SOURCES)
	./scripts/sync-phpspec-copy.sh
	touch -c $@
