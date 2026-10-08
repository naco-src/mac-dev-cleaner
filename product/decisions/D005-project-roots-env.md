# D005 — Project roots via environment

**Status:** Accepted (2026-10-08)

## Context

Stale project sweeps and NDK pinning need discoverable project trees.

## Decision

**`MDC_PROJECT_ROOTS`** — comma-separated absolute paths. Defaults: `~/Projects`, `~/AndroidStudioProjects`, `~/Developer`, `~/StudioProjects`.

## Consequences

Document in README/DEVELOPMENT; no interactive root picker in v1.
