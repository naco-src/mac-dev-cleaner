#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=package-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package-common.sh"

require_env TAG
validate_bundle

LINUXDEPLOY_VERSION="${LINUXDEPLOY_VERSION:-1-alpha-20251107-1}"
GTK_PLUGIN_REF="${GTK_PLUGIN_REF:-3b67a1d1c1b0c8268f57f2bce40fe2d33d409cea}"
CACHE_DIR="${LINUX_PACKAGING_CACHE:-${APP_DIR}/.cache/linux-packaging}"

out_dir="$(default_out_dir)"
mkdir -p "${out_dir}" "${CACHE_DIR}"

linuxdeploy="${CACHE_DIR}/linuxdeploy-x86_64.AppImage"
if [[ ! -x "${linuxdeploy}" ]]; then
  wget -q -O "${linuxdeploy}" \
    "https://github.com/linuxdeploy/linuxdeploy/releases/download/${LINUXDEPLOY_VERSION}/linuxdeploy-x86_64.AppImage"
  chmod +x "${linuxdeploy}"
fi

gtk_plugin="${CACHE_DIR}/linuxdeploy-plugin-gtk.sh"
if [[ ! -x "${gtk_plugin}" ]]; then
  wget -q -O "${gtk_plugin}" \
    "https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/${GTK_PLUGIN_REF}/linuxdeploy-plugin-gtk.sh"
  chmod +x "${gtk_plugin}"
fi

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

appdir="${work}/AppDir"
mkdir -p "${appdir}"
cp -a "${BUNDLE_DIR}/." "${appdir}/"
cp "${DESKTOP_SRC}" "${appdir}/${APP_ID}.desktop"
write_desktop_icon_256 "${appdir}/${APP_ID}.png"

export APPIMAGE_EXTRACT_AND_RUN=1
export LINUXDEPLOY="${linuxdeploy}"
export PATH="${CACHE_DIR}:${PATH}"
export DEPLOY_GTK_VERSION="${DEPLOY_GTK_VERSION:-3}"

pushd "${out_dir}" >/dev/null
"${linuxdeploy}" \
  --appdir "${appdir}" \
  --executable "${appdir}/${BINARY_NAME}" \
  --desktop-file "${appdir}/${APP_ID}.desktop" \
  --icon-file "${appdir}/${APP_ID}.png" \
  --plugin gtk \
  --output appimage
popd >/dev/null

appimage_src="$(find "${out_dir}" -maxdepth 1 -type f -name '*.AppImage' \
  ! -name 'linuxdeploy*' -print -quit)"
if [[ -z "${appimage_src}" ]]; then
  echo "linuxdeploy did not produce an AppImage" >&2
  exit 1
fi

dest="${out_dir}/mac-dev-cleaner-${TAG}-linux-x86_64.AppImage"
mv "${appimage_src}" "${dest}"
chmod +x "${dest}"
ls -lh "${dest}"
