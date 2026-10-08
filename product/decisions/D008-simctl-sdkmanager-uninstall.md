# D008 — Simulator runtimes and NDK uninstall commands

**Status:** Accepted (2026-10-08)

## Context

Runtimes are APFS volumes; NDK has a package manager.

## Decision

- iOS runtimes: **`xcrun simctl runtime delete <id>`** only.
- Unavailable simulators: **`xcrun simctl delete unavailable`**.
- NDK: **`sdkmanager --uninstall "ndk;<version>"`** for versions not referenced in projects.

## Consequences

Scan items use `CleanMethod.runCommand` with documented `commandDescription`; never `rm` on runtime bundle paths.
