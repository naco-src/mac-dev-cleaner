#!/usr/bin/env bash
# Shared helpers for Linux release packaging scripts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ICON_SRC="${APP_DIR}/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"
DESKTOP_SRC="${SCRIPT_DIR}/mac-dev-cleaner.desktop"
APP_ID="io.github.nguyenhoangvannha.macDevCleaner"
BINARY_NAME="mac_dev_cleaner"

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required env: ${name}" >&2
    exit 1
  fi
}

validate_bundle() {
  require_env BUNDLE_DIR
  if [[ ! -x "${BUNDLE_DIR}/${BINARY_NAME}" ]]; then
    echo "Bundle executable not found: ${BUNDLE_DIR}/${BINARY_NAME}" >&2
    exit 1
  fi
  if [[ ! -f "${ICON_SRC}" ]]; then
    echo "Icon not found: ${ICON_SRC}" >&2
    exit 1
  fi
  if [[ ! -f "${DESKTOP_SRC}" ]]; then
    echo "Desktop file not found: ${DESKTOP_SRC}" >&2
    exit 1
  fi
}

default_out_dir() {
  if [[ -n "${OUT_DIR:-}" ]]; then
    printf '%s\n' "${OUT_DIR}"
  else
    printf '%s\n' "$(pwd)"
  fi
}

write_desktop_icon_256() {
  local dest="$1"
  local size="${DESKTOP_ICON_SIZE:-256}"
  if command -v magick >/dev/null 2>&1; then
    magick "${ICON_SRC}" -resize "${size}x${size}" "${dest}"
  elif command -v convert >/dev/null 2>&1; then
    convert "${ICON_SRC}" -resize "${size}x${size}" "${dest}"
  elif command -v ffmpeg >/dev/null 2>&1; then
    ffmpeg -y -loglevel error -i "${ICON_SRC}" \
      -vf "scale=${size}:${size}" "${dest}"
  else
    echo "Install ImageMagick (magick/convert) or ffmpeg to resize ${ICON_SRC} for packaging." >&2
    exit 1
  fi
}
