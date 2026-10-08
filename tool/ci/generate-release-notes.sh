#!/usr/bin/env bash
# Write GitHub Release notes from commit subjects since the previous v* tag.
# Usage: generate-release-notes.sh TAG > notes.md
#   TAG — release tag being published (may not exist in git yet)
set -euo pipefail

tag="${1:?release tag required}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "generate-release-notes.sh must run inside a git repository." >&2
  exit 1
fi

find_previous_tag() {
  local current="$1"
  local t
  while IFS= read -r t; do
    if [ -n "${t}" ] && [ "${t}" != "${current}" ]; then
      printf '%s' "${t}"
      return 0
    fi
  done < <(git tag -l 'v*' --sort=-creatordate)
  return 1
}

previous=""
if previous="$(find_previous_tag "${tag}")"; then
  :
else
  previous=""
fi

repo="${GITHUB_REPOSITORY:-}"
if [ -z "${repo}" ]; then
  repo="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/]([^/]+\/[^/.]+)(\.git)?$#\1#' || true)"
fi

{
  printf '## Mac Dev Cleaner %s\n\n' "${tag}"
  if [ -n "${previous}" ]; then
    if [ -n "${repo}" ]; then
      printf 'Changes since [%s](https://github.com/%s/compare/%s...%s):\n\n' \
        "${previous}" "${repo}" "${previous}" "${tag}"
    else
      printf 'Changes since %s:\n\n' "${previous}"
    fi
  else
    printf 'Changes in this release:\n\n'
  fi

  if [ -n "${previous}" ]; then
    range="${previous}..HEAD"
  else
    range="HEAD"
  fi

  commits="$(git log "${range}" --no-merges --pretty=format:'- %s (%h)' || true)"
  if [ -z "${commits}" ]; then
    printf -- '- No commits found in range `%s`.\n' "${range}"
  else
    printf '%s\n' "${commits}"
  fi

  printf '\n\n---\n\nBuilt from commit `%s`.\n' "$(git rev-parse --short HEAD)"
}
