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

# Must match apps/mac_dev_cleaner/desktop_updater.yaml and desktop_updater.keys.json feedUrl.
base_url="${DESKTOP_UPDATER_PUBLISH_BASE_URL:-https://raw.githubusercontent.com/naco-src/mac-dev-cleaner/updates}"
export GITHUB_RELEASE_TAG="${TAG}"
export GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-naco-src/mac-dev-cleaner}"

MDC_FLUTTER="${MDC_FLUTTER:-fvm flutter}"
read -ra FLUTTER <<< "${MDC_FLUTTER}"

# desktop_updater:release is only a dependency of the Flutter app, not the repo workspace root.
cd "${APP_DIR}"
"${FLUTTER[@]}" pub get

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

existing_archive=""
archive_tmp="$(mktemp -d)"
feed_url="${base_url%/}/app-archive.json"
if curl -fsSL "${feed_url}" -o "${archive_tmp}/app-archive.json" 2>/dev/null; then
  existing_archive="${archive_tmp}/app-archive.json"
elif command -v gh >/dev/null 2>&1; then
  updates_branch="${DESKTOP_UPDATER_UPDATES_BRANCH:-updates}"
  updates_repo="${DESKTOP_UPDATER_UPDATES_REPOSITORY:-${GITHUB_REPOSITORY}}"
  if gh api "repos/${updates_repo}/contents/app-archive.json?ref=${updates_branch}" \
    --jq -r .content 2>/dev/null \
    | tr -d '\n' \
    | base64 --decode >"${archive_tmp}/app-archive.json" \
    && [ -s "${archive_tmp}/app-archive.json" ]; then
    existing_archive="${archive_tmp}/app-archive.json"
  fi
fi

publish_args=(
  desktop_updater:release publish
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

fvm dart run "${publish_args[@]}"
