# D015 — Repository layout vs PLAN diagram

**Status:** Accepted (2026-10-08)

## Context

PLAN §3 shows `packages/core`, `apps/cli`, `apps/desktop`.

## Decision

Actual paths:

| PLAN | Repo |
| --- | --- |
| `packages/core` | `packages/mac_dev_cleaner_core` |
| `apps/cli` | `apps/mac-dev-cleaner-cli` |
| `apps/desktop` | `apps/mac_dev_cleaner` |

## Consequences

Update PLAN references in new docs to actual paths; PLAN.md left as historical spec with this decision as mapping.
