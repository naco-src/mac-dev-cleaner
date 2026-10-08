#!/usr/bin/env bash
# CalVer build name + time-based Flutter/macOS build number for release builds.
#
# BUILD_NAME: UTC CalVer YYYY.MM.DD
# BUILD_NUMBER: minutes since VERSION_EPOCH, ×100 + (GITHUB_RUN_NUMBER % 100)
#
# Usage:
#   eval "$(./tool/release-version.sh)"
#   ./tool/release-version.sh BUILD_NAME
#
# Optional env:
#   VERSION_EPOCH — UTC start (default 2026-01-01 00:00:00)
#   GITHUB_RUN_NUMBER — CI disambiguator (default 0)
#   RELEASE_TAG — if set, TAG output uses this instead of auto v{name}+{number}

set -euo pipefail

utc_epoch_seconds() {
  local datetime="$1"
  if date -d "@0" +%s >/dev/null 2>&1; then
    date -u -d "${datetime}" +%s
  else
    date -u -j -f "%Y-%m-%d %H:%M:%S" "${datetime}" +%s
  fi
}

VERSION_EPOCH="${VERSION_EPOCH:-2026-01-01 00:00:00}"
SEQ="${GITHUB_RUN_NUMBER:-0}"

epoch_sec=$(utc_epoch_seconds "${VERSION_EPOCH}")
now_sec=$(date -u +%s)
minutes=$(( (now_sec - epoch_sec) / 60 ))
BUILD_NUMBER=$(( minutes * 100 + SEQ % 100 ))
BUILD_NAME=$(date -u +%Y.%m.%d)
DEB_VERSION="${BUILD_NAME}-${BUILD_NUMBER}"

if [ -n "${RELEASE_TAG:-}" ]; then
  TAG="${RELEASE_TAG}"
else
  TAG="v${BUILD_NAME}+${BUILD_NUMBER}"
fi

print_field() {
  case "$1" in
    BUILD_NAME) echo "${BUILD_NAME}" ;;
    BUILD_NUMBER) echo "${BUILD_NUMBER}" ;;
    DEB_VERSION) echo "${DEB_VERSION}" ;;
    TAG) echo "${TAG}" ;;
    *)
      echo "Unknown field: $1" >&2
      exit 1
      ;;
  esac
}

if [ $# -eq 0 ]; then
  printf 'BUILD_NAME=%q\n' "${BUILD_NAME}"
  printf 'BUILD_NUMBER=%q\n' "${BUILD_NUMBER}"
  printf 'DEB_VERSION=%q\n' "${DEB_VERSION}"
  printf 'TAG=%q\n' "${TAG}"
  exit 0
fi

print_field "$1"
