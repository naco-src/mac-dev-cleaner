#!/usr/bin/env bash
# Upload release asset globs to an existing GitHub Release (tag must exist).
# Usage: gh-release-upload.sh TAG glob [glob...]
set -euo pipefail

tag="${1:?tag}"
shift
if [ "$#" -eq 0 ]; then
  echo "Provide at least one glob pattern" >&2
  exit 1
fi

shopt -s nullglob
files=()
for pattern in "$@"; do
  for f in ${pattern}; do
    if [ -e "${f}" ]; then
      files+=("${f}")
    fi
  done
done

if [ "${#files[@]}" -eq 0 ]; then
  echo "No files matched for tag ${tag}" >&2
  exit 1
fi

echo "Uploading ${#files[@]} file(s) to release ${tag}"
ls -lh "${files[@]}"
gh release upload "${tag}" "${files[@]}"
