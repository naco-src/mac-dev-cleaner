#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

require_fvm
ROOT="$(root_dir)"
fvm_install_if_needed "${ROOT}"
cd "${ROOT}"

echo "==> fvm dart pub get (workspace)"
mdc_dart pub get

echo "==> fvm flutter pub get (${ROOT}/apps/mac_dev_cleaner)"
(cd "${ROOT}/apps/mac_dev_cleaner" && mdc_flutter pub get)

echo "==> done"
