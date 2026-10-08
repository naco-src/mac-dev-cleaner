#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

require_cmd flutter
ROOT="$(root_dir)"
APP="${ROOT}/apps/mac_dev_cleaner"
RELEASE_VERSION_SH="${ROOT}/tool/release-version.sh"

MODE="${1:-release}"
shift || true

BUILD_NAME="${BUILD_NAME:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"
if [[ -f "${RELEASE_VERSION_SH}" && ( -z "${BUILD_NAME}" || -z "${BUILD_NUMBER}" ) ]]; then
  BUILD_NAME="$( "${RELEASE_VERSION_SH}" BUILD_NAME )"
  BUILD_NUMBER="$( "${RELEASE_VERSION_SH}" BUILD_NUMBER )"
fi

FLAGS=()
if [[ -n "${BUILD_NAME}" && -n "${BUILD_NUMBER}" ]]; then
  FLAGS+=(--build-name="${BUILD_NAME}" --build-number="${BUILD_NUMBER}")
fi

cd "${APP}"
flutter pub get

case "${MODE}" in
  debug)
    exec flutter build macos --debug "${FLAGS[@]}" "$@"
    ;;
  release)
    exec flutter build macos --release "${FLAGS[@]}" "$@"
    ;;
  *)
    echo "usage: $0 [debug|release] [extra flutter build args...]" >&2
    exit 2
    ;;
esac
