#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

require_cmd flutter
ROOT="$(root_dir)"
cd "${ROOT}/apps/mac_dev_cleaner"

MODE="${1:-release}"
shift || true

case "${MODE}" in
  debug)
    exec flutter build macos --debug "$@"
    ;;
  release)
    exec flutter build macos --release "$@"
    ;;
  *)
    echo "usage: $0 [debug|release] [extra flutter build args...]" >&2
    exit 2
    ;;
esac
