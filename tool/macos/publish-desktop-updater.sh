#!/usr/bin/env bash
# Package a staged .app into signed desktop_updater artifacts and upload via GitHub Release.
set -euo pipefail

# shellcheck source=package-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package-common.sh"

require_env TAG
require_env BUILD_NAME
require_env BUILD_NUMBER

MACOS_ARCH="${MACOS_ARCH:-arm64}"
STAGE_DIR="${STAGE_DIR:-${ROOT}/.macos-staging/${MACOS_ARCH}}"
artifact_root="${STAGE_DIR}/${APP_BUNDLE_NAME}"
validate_app_bundle "${artifact_root}"

base_url="https://github.com/naco-src/mac-dev-cleaner/releases/download/${TAG}"
export GITHUB_RELEASE_TAG="${TAG}"

MDC_FLUTTER="${MDC_FLUTTER:-fvm flutter}"
read -ra FLUTTER <<< "${MDC_FLUTTER}"

if [ -n "${DESKTOP_UPDATER_KEY_BUNDLE_PATH:-}" ]; then
  if [ -z "${DESKTOP_UPDATER_KEY_BUNDLE_PASSPHRASE:-}" ]; then
    echo "Set DESKTOP_UPDATER_KEY_BUNDLE_PASSPHRASE when DESKTOP_UPDATER_KEY_BUNDLE_PATH is set." >&2
    exit 1
  fi
  export DESKTOP_UPDATER_KEY_BUNDLE_PASSPHRASE
  fvm dart run desktop_updater:release keys import \
    --input "${DESKTOP_UPDATER_KEY_BUNDLE_PATH}" \
    --passphrase-env DESKTOP_UPDATER_KEY_BUNDLE_PASSPHRASE
fi

cd "${APP_DIR}"
"${FLUTTER[@]}" pub get

existing_archive=""
if gh release view "${TAG}" --json assets --jq '.assets[]?.name' 2>/dev/null | grep -qx 'app-archive.json'; then
  tmp="$(mktemp -d)"
  gh release download "${TAG}" --pattern 'app-archive.json' --dir "${tmp}"
  existing_archive="${tmp}/app-archive.json"
fi

publish_args=(
  run desktop_updater:release publish
  --platform macos
  --project-type manual
  --artifact-root "${artifact_root}"
  --app-name "${APP_BUNDLE_NAME}"
  --package-id io.github.nguyenhoangvannha.macDevCleaner
  --version "${BUILD_NAME}"
  --build-number "${BUILD_NUMBER}"
  --base-url "${base_url}"
)
if [ -n "${existing_archive}" ]; then
  publish_args+=(--existing-app-archive "${existing_archive}")
else
  publish_args+=(--initialize-feed)
fi

case "${DESKTOP_UPDATER_MANDATORY:-false}" in
  true | True | 1 | yes | YES) publish_args+=(--mandatory) ;;
esac

fvm dart "${publish_args[@]}"
