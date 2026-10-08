#!/usr/bin/env bash
# Publish desktop_updater artifacts to the repo `updates` branch (customCommand provider).
#
# desktop_updater signs nested URLs (releases/stable/…/macos/release.json). GitHub
# Release assets are flat: `gh release upload` keeps only the basename, and the API
# turns slashes in asset names into dots. Those URLs never match signed manifests.
# Push the publish tree to a git branch and serve it via raw.githubusercontent.com.
set -euo pipefail

local_root="${DESKTOP_UPDATER_LOCAL_ROOT:?DESKTOP_UPDATER_LOCAL_ROOT is required}"
tag="${GITHUB_RELEASE_TAG:-${TAG:-unknown}}"
phase="${DESKTOP_UPDATER_UPLOAD_PHASE:-versioned}"
receipt_path="${DESKTOP_UPDATER_INDEX_PUBLISH_RECEIPT:-}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to publish desktop_updater artifacts." >&2
  exit 127
fi

branch="${DESKTOP_UPDATER_UPDATES_BRANCH:-updates}"
repo="${GITHUB_REPOSITORY:-}"
if [ -z "${repo}" ]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "Set GITHUB_REPOSITORY or install gh to resolve the repository." >&2
    exit 64
  fi
  repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [ -z "${token}" ]; then
  echo "Set GH_TOKEN or GITHUB_TOKEN to push the updates branch." >&2
  exit 64
fi

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

git -C "${work}" init -q
git -C "${work}" remote add origin "https://x-access-token:${token}@github.com/${repo}.git"
git -C "${work}" config user.email "github-actions[bot]@users.noreply.github.com"
git -C "${work}" config user.name "github-actions[bot]"

if git -C "${work}" fetch --depth 1 origin "${branch}" 2>/dev/null; then
  git -C "${work}" checkout -q FETCH_HEAD
else
  git -C "${work}" checkout -q --orphan "${branch}"
  git -C "${work}" rm -rf . >/dev/null 2>&1 || true
fi

rsync -a "${local_root}/" "${work}/"
git -C "${work}" add -A
if git -C "${work}" diff --staged --quiet; then
  echo "No changes to publish on branch ${branch} (${phase})"
else
  git -C "${work}" commit -q -m "desktop_updater ${tag} (${phase})"
  git -C "${work}" push origin "HEAD:${branch}"
  echo "Pushed desktop_updater ${phase} payload to ${repo}@${branch}"
  # raw.githubusercontent.com can lag briefly after a push.
  sleep 5
fi

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
