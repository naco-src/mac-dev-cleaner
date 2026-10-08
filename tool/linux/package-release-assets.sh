#!/usr/bin/env bash
# Build release Linux bundle and produce selected packaging formats.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="${ROOT}/apps/mac_dev_cleaner"
TOOL="${APP_DIR}/tool/linux"
export BUILD_NAME="${BUILD_NAME:?Set BUILD_NAME}"
export BUILD_NUMBER="${BUILD_NUMBER:?Set BUILD_NUMBER}"
export TAG="${TAG:?Set TAG}"
export OUT_DIR="${OUT_DIR:-${ROOT}}"
export BUNDLE_DIR="${BUNDLE_DIR:-${APP_DIR}/build/linux/x64/release/bundle}"
eval "$(cd "${ROOT}" && ./tool/release-version.sh)"
export DEB_VERSION="${DEB_VERSION}"

chmod +x "${TOOL}"/package-*.sh

MDC_FLUTTER="${MDC_FLUTTER:-fvm flutter}"
DART_CMD="${DART_CMD:-fvm dart}"
(cd "${ROOT}" && ${DART_CMD} pub get)
(
  cd "${APP_DIR}"
  ${MDC_FLUTTER} pub get
  ${MDC_FLUTTER} build linux --release \
    --build-name="${BUILD_NAME}" \
    --build-number="${BUILD_NUMBER}"
)

if [[ "${LINUX_TARBALL:-true}" == "true" ]]; then
  "${TOOL}/package-tarball.sh"
fi
if [[ "${LINUX_DEB:-false}" == "true" ]]; then
  "${TOOL}/package-deb.sh"
fi
if [[ "${LINUX_APPIMAGE:-false}" == "true" ]]; then
  "${TOOL}/package-appimage.sh"
fi

shopt -s nullglob
assets=(
  "${OUT_DIR}"/mac-dev-cleaner-"${TAG}"-linux-*
  "${OUT_DIR}"/mac-dev-cleaner_*.deb
)
if [[ "${#assets[@]}" -eq 0 ]]; then
  echo "No Linux release assets under ${OUT_DIR}" >&2
  exit 1
fi
ls -lh "${assets[@]}"
