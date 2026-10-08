# D002 — CLI + Flutter app (not CLI-only)

**Status:** Accepted (2026-10-08)

## Context

PLAN listed Flutter macOS app as optional M8; Nhã ships both CLI and GUI.

## Decision

Ship **Dart CLI** and **Flutter macOS app** sharing `mac_dev_cleaner_core`. CLI remains the automation/reference surface; app adds treemap, tabs, FDA onboarding, and activity logs.

## Consequences

UI must not duplicate scan rules; all behavior changes start in core. CI runs core + app tests.
