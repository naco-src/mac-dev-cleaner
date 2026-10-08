#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

require_cmd dart
ROOT="$(root_dir)"
cd "${ROOT}"

echo "==> dart pub get (workspace)"
dart pub get

if command -v flutter >/dev/null 2>&1; then
  echo "==> flutter pub get (${ROOT}/apps/mac_dev_cleaner)"
  (cd "${ROOT}/apps/mac_dev_cleaner" && flutter pub get)
else
  echo "==> skip flutter pub get (flutter not on PATH)"
fi

echo "==> done"
