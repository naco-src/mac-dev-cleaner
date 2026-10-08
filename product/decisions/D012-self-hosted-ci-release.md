# D012 — CI and release on self-hosted MYRUNNER

**Status:** Accepted (2026-10-08)

## Context

LaneLift pattern: pre-provisioned Mac with Xcode, FVM, `gh`.

## Decision

**`workflow_dispatch`** only for CI and Release. Runner labels: **`self-hosted`, `macOS`, `MYRUNNER`**. CI runs `fvm install` + `make check`. Release builds arm64 + x64 assets and publishes GitHub Release.

## Consequences

No `ubuntu-latest` CI in default workflows; contributors need local `make check` or access to MYRUNNER.
