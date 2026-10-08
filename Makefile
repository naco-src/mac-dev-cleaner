# mac-dev-cleaner — run `make` or `make help` for targets.
SHELL := /bin/bash
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS := $(ROOT)/scripts

.DEFAULT_GOAL := help

.PHONY: help bootstrap get test analyze clean check
.PHONY: cli-scan cli-plan-safe cli-clean-safe cli-doctor cli-history
.PHONY: run-app build-macos build-macos-debug install-cli

help:
	@echo "mac-dev-cleaner"
	@echo ""
	@echo "Setup:"
	@echo "  make bootstrap    pub get (Dart workspace + Flutter app)"
	@echo "  make get          alias for bootstrap"
	@echo ""
	@echo "Quality:"
	@echo "  make analyze      dart + flutter analyze"
	@echo "  make test         dart + flutter test"
	@echo "  make check        bootstrap, analyze, test"
	@echo "  make clean        remove build artifacts"
	@echo ""
	@echo "CLI (mdc):"
	@echo "  make cli-scan"
	@echo "  make cli-plan-safe"
	@echo "  make cli-clean-safe   destructive — uses --yes"
	@echo "  make cli-doctor"
	@echo "  make cli-history"
	@echo "  make mdc ARGS='scan -v'   arbitrary mdc subcommand"
	@echo ""
	@echo "Flutter app:"
	@echo "  make run-app"
	@echo "  make build-macos"
	@echo "  make build-macos-debug"
	@echo ""
	@echo "  make install-cli  dart pub global activate (path)"

bootstrap get:
	@$(SCRIPTS)/bootstrap.sh

analyze:
	@$(SCRIPTS)/analyze.sh

test:
	@$(SCRIPTS)/test.sh

check: bootstrap analyze test

clean:
	rm -rf "$(ROOT)/.dart_tool"
	rm -rf "$(ROOT)/packages/mac_dev_cleaner_core/.dart_tool"
	rm -rf "$(ROOT)/apps/mac-dev-cleaner-cli/.dart_tool"
	rm -rf "$(ROOT)/apps/mac_dev_cleaner/build"
	rm -rf "$(ROOT)/apps/mac_dev_cleaner/.dart_tool"

cli-scan:
	@$(SCRIPTS)/mdc.sh scan

cli-plan-safe:
	@$(SCRIPTS)/mdc.sh plan --safe

cli-clean-safe:
	@$(SCRIPTS)/mdc.sh clean --safe --yes

cli-doctor:
	@$(SCRIPTS)/mdc.sh doctor

cli-history:
	@$(SCRIPTS)/mdc.sh history

mdc:
	@$(SCRIPTS)/mdc.sh $(ARGS)

run-app:
	@$(SCRIPTS)/run_app.sh

build-macos:
	@$(SCRIPTS)/build_macos.sh release

build-macos-debug:
	@$(SCRIPTS)/build_macos.sh debug

install-cli:
	cd "$(ROOT)/apps/mac-dev-cleaner-cli" && dart pub global activate --source path .
