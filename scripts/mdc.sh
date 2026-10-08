#!/usr/bin/env bash
# Run the mdc CLI from the repo (any subcommand).
# Usage: scripts/mdc.sh scan
#        scripts/mdc.sh plan --safe
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

require_cmd dart
ROOT="$(root_dir)"
CLI="${ROOT}/apps/mac-dev-cleaner-cli"

cd "${CLI}"
exec dart run bin/mdc.dart "$@"
