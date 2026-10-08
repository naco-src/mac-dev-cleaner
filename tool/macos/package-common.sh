#!/usr/bin/env bash
# Shared paths for macOS release packaging (CI and local).
set -euo pipefail

macos_tool_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${macos_tool_dir}/../.." && pwd)"
APP_DIR="${ROOT}/apps/mac_dev_cleaner"
APP_BUNDLE_NAME="Mac Dev Cleaner.app"
DEFAULT_APP="${APP_DIR}/build/macos/Build/Products/Release/${APP_BUNDLE_NAME}"
ASSET_PREFIX="mac-dev-cleaner"

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Set ${name}" >&2
    exit 1
  fi
}

arch_file_slug() {
  case "$1" in
    arm64) echo arm64 ;;
    x86_64 | x64) echo x64 ;;
    *)
      echo "Unsupported MACOS_ARCH: $1 (use arm64 or x86_64)" >&2
      exit 1
      ;;
  esac
}

default_out_dir() {
  echo "${OUT_DIR:-${ROOT}}"
}

validate_app_bundle() {
  local app="${1:?app path}"
  if [[ ! -d "${app}" ]]; then
    echo "Missing macOS app bundle: ${app}" >&2
    exit 1
  fi
}
