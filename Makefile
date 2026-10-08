# mac-dev-cleaner — run `make` or `make help` for targets.
SHELL := /bin/bash
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS := $(ROOT)/scripts
APP_DIR := apps/mac_dev_cleaner
MACOS_OUT := $(APP_DIR)/build/macos/Build/Products/Release
RELEASE_VERSION_SH := $(CURDIR)/tool/release-version.sh
BUILD_NAME := $(shell $(RELEASE_VERSION_SH) BUILD_NAME)
BUILD_NUMBER := $(shell $(RELEASE_VERSION_SH) BUILD_NUMBER)
RELEASE_TAG ?= $(shell $(RELEASE_VERSION_SH) TAG)
FLUTTER ?= fvm flutter
DART ?= fvm dart
FLUTTER_RELEASE_FLAGS := --build-name=$(BUILD_NAME) --build-number=$(BUILD_NUMBER)

.DEFAULT_GOAL := help

.PHONY: help bootstrap get test analyze clean check
.PHONY: cli-scan cli-plan-safe cli-clean-safe cli-doctor cli-history
.PHONY: run-app build-macos build-macos-debug macos-release macos-packaging linux-packaging install-cli
.PHONY: release-version

help:
	@echo "mac-dev-cleaner"
	@echo ""
	@echo "Version (CalVer + build number, from tool/release-version.sh):"
	@echo "  BUILD_NAME=$(BUILD_NAME)  BUILD_NUMBER=$(BUILD_NUMBER)"
	@echo "  RELEASE_TAG=$(RELEASE_TAG)  (override: make macos-packaging RELEASE_TAG=v2026.01.01+1)"
	@echo ""
	@echo "Setup:"
	@echo "  make bootstrap    pub get (Dart workspace + Flutter app)"
	@echo "  make get          alias for bootstrap"
	@echo ""
	@echo "Quality:"
	@echo "  make analyze      fvm dart + fvm flutter analyze"
	@echo "  make test         fvm dart + fvm flutter test"
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
	@echo "  make macos-release     release .app with BUILD_NAME/BUILD_NUMBER"
	@echo "  make macos-packaging   arm64+x64 .zip/.dmg for RELEASE_TAG"
	@echo "  make linux-packaging   Linux tarball (and optional deb/appimage via env)"
	@echo "  make build-macos       alias for macos-release"
	@echo "  make build-macos-debug"
	@echo ""
	@echo "  make install-cli  fvm dart pub global activate (path)"
	@echo "  make release-version  print eval-able version exports"

release-version:
	@./tool/release-version.sh

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
	rm -rf "$(ROOT)/.macos-staging"
	rm -f "$(ROOT)"/mac-dev-cleaner-*-macos-*.{zip,dmg}
	rm -f "$(ROOT)"/mac-dev-cleaner-*-linux-*
	rm -f "$(ROOT)"/mac-dev-cleaner_*.deb

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

macos-release:
	cd "$(APP_DIR)" && $(FLUTTER) pub get && $(FLUTTER) build macos --release $(FLUTTER_RELEASE_FLAGS)
	@echo ""
	@echo "macOS:"
	@ls -ld "$(MACOS_OUT)/Mac Dev Cleaner.app"

macos-packaging:
	BUILD_NAME=$(BUILD_NAME) BUILD_NUMBER=$(BUILD_NUMBER) \
		TAG=$(RELEASE_TAG) OUT_DIR=$(CURDIR) \
		./tool/macos/package-release-assets.sh

linux-packaging:
	BUILD_NAME=$(BUILD_NAME) BUILD_NUMBER=$(BUILD_NUMBER) \
		TAG=$(RELEASE_TAG) OUT_DIR=$(CURDIR) \
		LINUX_TARBALL=$${LINUX_TARBALL:-true} \
		LINUX_DEB=$${LINUX_DEB:-false} \
		LINUX_APPIMAGE=$${LINUX_APPIMAGE:-false} \
		./tool/linux/package-release-assets.sh

build-macos: macos-release

build-macos-debug:
	@$(SCRIPTS)/build_macos.sh debug

install-cli:
	cd "$(ROOT)/apps/mac-dev-cleaner-cli" && $(DART) pub global activate --source path .
