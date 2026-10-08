#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

require_cmd dart
ROOT="$(root_dir)"
cd "${ROOT}"

echo "==> dart analyze (core + cli)"
dart analyze packages/mac_dev_cleaner_core apps/mac-dev-cleaner-cli

if command -v flutter >/dev/null 2>&1; then
  echo "==> flutter analyze (mac_dev_cleaner)"
  (cd "${ROOT}/apps/mac_dev_cleaner" && flutter analyze)
else
  echo "==> skip flutter analyze (flutter not on PATH)"
fi

echo "==> done"
