#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

require_fvm
ROOT="$(root_dir)"
fvm_install_if_needed "${ROOT}"
cd "${ROOT}/apps/mac_dev_cleaner"

exec fvm flutter run -d macos "$@"
