#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

require_cmd flutter
ROOT="$(root_dir)"
cd "${ROOT}/apps/mac_dev_cleaner"
exec flutter run -d macos "$@"
