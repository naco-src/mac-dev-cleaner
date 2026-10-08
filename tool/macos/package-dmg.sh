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
dmg="${out_dir}/${ASSET_PREFIX}-${TAG}-macos-${slug}.dmg"
volname="${DMG_VOLUME_NAME:-Mac Dev Cleaner}"

validate_app_bundle "${APP}"
rm -f "${dmg}"
hdiutil create -volname "${volname}" -srcfolder "${APP}" -ov -format UDZO "${dmg}"
echo "Wrote ${dmg}"
ls -lh "${dmg}"
