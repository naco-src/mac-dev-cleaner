#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=package-common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package-common.sh"

require_env TAG
validate_bundle

out_dir="$(default_out_dir)"
mkdir -p "${out_dir}"
archive="${out_dir}/mac-dev-cleaner-${TAG}-linux-x64.tar.gz"

tar -C "${BUNDLE_DIR}" -czf "${archive}" .
ls -lh "${archive}"
