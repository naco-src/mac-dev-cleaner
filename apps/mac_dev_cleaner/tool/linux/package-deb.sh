#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=package-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package-common.sh"

require_env DEB_VERSION
validate_bundle

out_dir="$(default_out_dir)"
mkdir -p "${out_dir}"

staging="$(mktemp -d)"
trap 'rm -rf "${staging}"' EXIT

root="${staging}/mac-dev-cleaner_${DEB_VERSION}_amd64"
mkdir -p "${root}/DEBIAN" \
  "${root}/opt/mac-dev-cleaner" \
  "${root}/usr/bin" \
  "${root}/usr/share/applications" \
  "${root}/usr/share/icons/hicolor/256x256/apps"

cp -a "${BUNDLE_DIR}/." "${root}/opt/mac-dev-cleaner/"

cat >"${root}/usr/bin/mac_dev_cleaner" <<'EOF'
#!/bin/sh
exec /opt/mac-dev-cleaner/mac_dev_cleaner "$@"
EOF
chmod 755 "${root}/usr/bin/mac_dev_cleaner"

cp "${DESKTOP_SRC}" "${root}/usr/share/applications/${APP_ID}.desktop"
write_desktop_icon_256 \
  "${root}/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png"

installed_size="$(du -sk "${root}/opt/mac-dev-cleaner" | awk '{print $1}')"

cat >"${root}/DEBIAN/control" <<EOF
Package: mac-dev-cleaner
Version: ${DEB_VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Mac Dev Cleaner <${APP_ID}@local>
Installed-Size: ${installed_size}
Depends: libgtk-3-0, libblkid1, liblzma5
Description: Mac Dev Cleaner
 Scan and clean developer caches safely.
EOF

deb="${out_dir}/mac-dev-cleaner_${DEB_VERSION}_amd64.deb"
dpkg-deb --root-owner-group --build "${root}" "${deb}"
ls -lh "${deb}"
