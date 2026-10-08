#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

require_fvm
ROOT="$(root_dir)"
fvm_install_if_needed "${ROOT}"
cd "${ROOT}"

echo "==> fvm dart test (mac_dev_cleaner_core)"
mdc_dart test packages/mac_dev_cleaner_core

echo "==> fvm flutter test (mac_dev_cleaner)"
(cd "${ROOT}/apps/mac_dev_cleaner" && mdc_flutter test)
