#!/usr/bin/env bash
# Shared helpers for mac-dev-cleaner scripts.
set -euo pipefail

root_dir() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd "${script_dir}/.." && pwd
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

require_fvm() {
  require_cmd fvm
}

# Pin Flutter SDK from .fvmrc when present (no-op if already installed).
fvm_install_if_needed() {
  local root="${1:?}"
  if [[ -f "${root}/.fvmrc" ]]; then
    (cd "${root}" && fvm install)
  fi
}

mdc_dart() {
  fvm dart "$@"
}

mdc_flutter() {
  fvm flutter "$@"
}
