#!/usr/bin/env bash
# Build arm64 + x86_64 release apps and produce .zip + .dmg per architecture.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOL="${ROOT}/tool/macos"
export BUILD_NAME="${BUILD_NAME:?Set BUILD_NAME}"
export BUILD_NUMBER="${BUILD_NUMBER:?Set BUILD_NUMBER}"
export TAG="${TAG:?Set TAG}"
export OUT_DIR="${OUT_DIR:-${ROOT}}"

chmod +x "${TOOL}"/build-release-unsigned.sh \
  "${TOOL}"/package-zip.sh \
  "${TOOL}"/package-dmg.sh

for arch in arm64 x86_64; do
  echo "=== macOS ${arch} ==="
  MACOS_ARCH="${arch}" "${TOOL}/build-release-unsigned.sh"
  MACOS_ARCH="${arch}" "${TOOL}/package-zip.sh"
  MACOS_ARCH="${arch}" "${TOOL}/package-dmg.sh"
done

shopt -s nullglob
assets=("${OUT_DIR}"/mac-dev-cleaner-"${TAG}"-macos-*.{zip,dmg})
if [[ "${#assets[@]}" -eq 0 ]]; then
  echo "No macOS release assets under ${OUT_DIR}" >&2
  exit 1
fi
ls -lh "${assets[@]}"
