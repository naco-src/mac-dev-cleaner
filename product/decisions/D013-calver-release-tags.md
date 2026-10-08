# D013 — Versioning and release tags (CalVer)

**Status:** Accepted (2026-10-08)

## Context

Align with LaneLift release hygiene.

## Decision

**`tool/release-version.sh`** defines **`BUILD_NAME`** (UTC `YYYY.MM.DD`), **`BUILD_NUMBER`**, **`TAG`** = `v{BUILD_NAME}+{BUILD_NUMBER}`. Flutter `--build-name` / `--build-number` follow these.

## Consequences

Release workflow inputs can override tag; default tag is CalVer-based.
