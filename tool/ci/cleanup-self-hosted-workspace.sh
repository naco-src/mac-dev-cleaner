#!/usr/bin/env bash
# Empties GITHUB_WORKSPACE but keeps .git and .github/actions for post-job hooks.
set -euo pipefail

ws="${GITHUB_WORKSPACE:-}"
if [ -z "${ws}" ] || [ "${ws}" = "/" ] || [ "${ws}" = "${HOME}" ]; then
  exit 0
fi
case "${ws}" in
  "/"*"/_work/"*) ;;
  *)
    echo "Refusing to clean path outside _work: ${ws}" >&2
    exit 0
    ;;
esac
if [ ! -d "${ws}" ]; then
  mkdir -p "${ws}"
  exit 0
fi
cd "${ws}"
shopt -s dotglob nullglob
entries=( * )
for entry in "${entries[@]}"; do
  case "${entry}" in
    .git) continue ;;
    .github)
      if [ -d .github ]; then
        for sub in .github/*; do
          [ -e "${sub}" ] || continue
          base=$(basename "${sub}")
          if [ "${base}" = "actions" ]; then
            continue
          fi
          rm -rf "${sub}"
        done
      fi
      ;;
    *)
      rm -rf "${entry}"
      ;;
  esac
done
echo "Emptied workspace (kept .git and .github/actions for post-job hooks): ${ws}"
