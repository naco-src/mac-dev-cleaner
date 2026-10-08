#!/usr/bin/env bash
# Release macOS build (unsigned / ad-hoc). Set MACOS_ARCH=arm64 or x86_64.
set -euo pipefail

# shellcheck source=package-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package-common.sh"

BUILD_NAME="${BUILD_NAME:?Set BUILD_NAME}"
BUILD_NUMBER="${BUILD_NUMBER:?Set BUILD_NUMBER}"
MACOS_ARCH="${MACOS_ARCH:-arm64}"
export STAGE_DIR="${STAGE_DIR:-${ROOT}/.macos-staging/${MACOS_ARCH}}"

MDC_FLUTTER="${MDC_FLUTTER:-fvm flutter}"
read -ra FLUTTER <<< "${MDC_FLUTTER}"

run_flutter_build() {
  local -a cmd=(
    "${FLUTTER[@]}"
    build macos --release
    --build-name="${BUILD_NAME}"
    --build-number="${BUILD_NUMBER}"
  )
  if [[ "${MACOS_ARCH}" == "x86_64" ]]; then
    arch -x86_64 "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
}

cd "${APP_DIR}"
"${FLUTTER[@]}" pub get
run_flutter_build

release_app="${APP_DIR}/build/macos/Build/Products/Release/${APP_BUNDLE_NAME}"
validate_app_bundle "${release_app}"
rm -rf "${STAGE_DIR}/${APP_BUNDLE_NAME}"
mkdir -p "${STAGE_DIR}"
ditto "${release_app}" "${STAGE_DIR}/${APP_BUNDLE_NAME}"
echo "Staged ${STAGE_DIR}/${APP_BUNDLE_NAME} (${MACOS_ARCH})"
