#!/usr/bin/env bash
# Upload desktop_updater publish payloads to the current GitHub Release (customCommand provider).
set -euo pipefail

local_root="${DESKTOP_UPDATER_LOCAL_ROOT:?DESKTOP_UPDATER_LOCAL_ROOT is required}"
tag="${GITHUB_RELEASE_TAG:-${TAG:-}}"
if [ -z "${tag}" ]; then
  echo "Set GITHUB_RELEASE_TAG or TAG to the GitHub release tag." >&2
  exit 64
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required to upload update assets." >&2
  exit 127
fi

phase="${DESKTOP_UPDATER_UPLOAD_PHASE:-versioned}"
receipt_path="${DESKTOP_UPDATER_INDEX_PUBLISH_RECEIPT:-}"

upload_tree() {
  local root="$1"
  local -a args=()
  while IFS= read -r -d '' file; do
    rel="${file#"${root}/"}"
    args+=("${file}#${rel}")
  done < <(find "${root}" -type f -print0)
  if [ "${#args[@]}" -eq 0 ]; then
    echo "No files to upload under ${root}" >&2
    exit 1
  fi
  echo "Uploading ${#args[@]} file(s) to GitHub release ${tag} (${phase})"
  gh release upload "${tag}" "${args[@]}" --clobber
}

upload_tree "${local_root}"

if [ "${phase}" = "index" ]; then
  if [ -z "${receipt_path}" ]; then
    echo "DESKTOP_UPDATER_INDEX_PUBLISH_RECEIPT is required for index phase." >&2
    exit 64
  fi
  absent="${DESKTOP_UPDATER_EXPECTED_REMOTE_INDEX_ABSENT:-false}"
  index_file="${local_root}/app-archive.json"
  if [ ! -f "${index_file}" ]; then
    echo "Missing app-archive.json in ${local_root}" >&2
    exit 1
  fi
  published_sha256="$(shasum -a 256 "${index_file}" | awk '{print $1}')"
  prior_sha256="null"
  prior_etag="null"
  if [ "${absent}" != "true" ]; then
    prior_sha256="\"${DESKTOP_UPDATER_EXPECTED_REMOTE_INDEX_SHA256:-}\""
    prior_etag="\"${DESKTOP_UPDATER_EXPECTED_REMOTE_INDEX_ETAG:-}\""
  fi
  mkdir -p "$(dirname "${receipt_path}")"
  cat >"${receipt_path}" <<EOF
{"schemaVersion":1,"observedPriorRevision":{"absent":${absent},"sha256":${prior_sha256},"etag":${prior_etag}},"publishedSha256":"${published_sha256}","mechanism":"conditionalWrite","leaseEvidenceSha256":null}
EOF
fi
