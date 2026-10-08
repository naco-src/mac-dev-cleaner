# D006 — Disk space: macOS Data volume

**Status:** Accepted (2026-10-08)

## Context

APFS `df` output is misleading if summed naively.

## Decision

Report **`/System/Volumes/Data`** via `df -k` in `MacOSDiskSpaceProvider`. Show before/after around scan/clean in app/CLI where implemented.

## Consequences

Other OS providers must pick an equivalent primary data mount.
