#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=package-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package-common.sh"

require_env TAG
require_env MACOS_ARCH

APP="${APP_PATH:-${STAGE_DIR:-${ROOT}/.macos-staging/${MACOS_ARCH}}/${APP_BUNDLE_NAME}}"
slug="$(arch_file_slug "${MACOS_ARCH}")"
out_dir="$(default_out_dir)"
mkdir -p "${out_dir}"
archive="${out_dir}/${ASSET_PREFIX}-${TAG}-macos-${slug}.zip"

validate_app_bundle "${APP}"
ditto -c -k --sequesterRsrc --keepParent "${APP}" "${archive}"
echo "Wrote ${archive}"
ls -lh "${archive}"
