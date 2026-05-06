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

CODECEPTION_ADAPTER = sources/codeception-adapter/tests/e2e/Codeception_Basic/composer.json
CODECEPTION_COPY_HASH = tests/Codeception/source.hash
CODECEPTION_COPY_SOURCES = $(shell find sources/codeception-adapter/tests/e2e/Codeception_Basic -type f 2>/dev/null)
PHPSPEC_ADAPTER = sources/phpspec-adapter/tests/e2e/PhpSpec/README.md
PHPSPEC_COPY_HASH = tests/PhpSpec/source.hash
PHPSPEC_COPY_SOURCES = $(shell find sources/phpspec-adapter/tests/e2e/PhpSpec -type f 2>/dev/null)
INFECTION = sources/infection/README.md
INFECTION_BIN = sources/infection/bin/infection
INFECTION_VENDOR = sources/infection/vendor
EXTENSION_INSTALLER = sources/extension-installer/composer.json
ABSTRACT_TESTFRAMEWORK_ADAPTER = sources/abstract-testframework-adapter/composer.json


#
# Commands (phony targets)
#---------------------------------------------------------------------------

.PHONY: test
test: 	## Test the adapters
test: test-phpspec test-codeception

.PHONY: test-phpspec
test-phpspec: tests/PhpSpec/vendor	## Test the PHPSpec Adapter
	cd tests/PhpSpec && vendor/bin/infection --test-framework=phpspec

.PHONY: test-codeception
test-codeception: tests/Codeception/vendor	## Test the Codeception Adapter
	cd tests/Codeception && vendor/bin/infection --test-framework=codeception


#
# Rules from files (non-phony targets)
#---------------------------------------------------------------------------

$(INFECTION):
	git submodule update --init sources/infection
	touch -c $@

$(INFECTION_BIN): sources/infection/vendor
	touch -c $@

sources/infection/vendor:
	composer install --working-dir=sources/infection
	touch -c $@

$(CODECEPTION_ADAPTER):
	git submodule update --init sources/codeception-adapter
	touch -c $@

$(PHPSPEC_ADAPTER):
	git submodule update --init sources/phpspec-adapter
	touch -c $@

$(EXTENSION_INSTALLER):
	git submodule update --init sources/extension-installer
	touch -c $@

$(ABSTRACT_TESTFRAMEWORK_ADAPTER):
	git submodule update --init sources/abstract-testframework-adapter
	touch -c $@

tests/Codeception/vendor: $(CODECEPTION_COPY_HASH) | $(EXTENSION_INSTALLER) $(ABSTRACT_TESTFRAMEWORK_ADAPTER)
	composer update --working-dir=tests/Codeception --ignore-platform-req=ext-curl
	touch -c $@

$(CODECEPTION_COPY_HASH): $(CODECEPTION_ADAPTER) $(CODECEPTION_COPY_SOURCES)
	./bin/sync-codeception-copy.sh
	touch -c $@

tests/PhpSpec/vendor: $(PHPSPEC_COPY_HASH) | $(EXTENSION_INSTALLER) $(ABSTRACT_TESTFRAMEWORK_ADAPTER)
	composer update --working-dir=tests/PhpSpec
	touch -c $@

$(PHPSPEC_COPY_HASH): $(PHPSPEC_ADAPTER) $(PHPSPEC_COPY_SOURCES)
	./bin/sync-phpspec-copy.sh
	touch -c $@
