#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

require_fvm
ROOT="$(root_dir)"
fvm_install_if_needed "${ROOT}"
cd "${ROOT}"

echo "==> fvm dart analyze (core + cli)"
mdc_dart analyze packages/mac_dev_cleaner_core apps/mac-dev-cleaner-cli

echo "==> fvm flutter analyze (mac_dev_cleaner)"
(cd "${ROOT}/apps/mac_dev_cleaner" && mdc_flutter analyze)
