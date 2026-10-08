# D003 — Dart core package as single source of truth

**Status:** Accepted (2026-10-08)

## Context

PLAN proposed `packages/core` + CLI + desktop.

## Decision

One library **`packages/mac_dev_cleaner_core`** exports scan, plan, execute, doctor, history. Workspace root `pubspec.yaml` includes core + CLI; Flutter app is a sibling app with path dependency.

## Consequences

`FileSystem` + `ProcessRunner` abstractions stay in core for tests; CLI is a thin `mdc.dart` wrapper.
