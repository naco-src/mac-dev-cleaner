#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

require_cmd dart
ROOT="$(root_dir)"
cd "${ROOT}"

echo "==> dart test (mac_dev_cleaner_core)"
dart test packages/mac_dev_cleaner_core

if command -v flutter >/dev/null 2>&1; then
  echo "==> flutter test (mac_dev_cleaner)"
  (cd "${ROOT}/apps/mac_dev_cleaner" && flutter test)
else
  echo "==> skip flutter test (flutter not on PATH)"
fi

echo "==> done"
