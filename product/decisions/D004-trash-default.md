# D004 — Trash as default delete semantics

**Status:** Accepted (2026-10-08)

## Context

PLAN asked Trash vs permanent delete as open.

## Decision

**`CleanMethod.moveToTrash`** is default for folder deletes. Permanent delete requires explicit user choice (`--delete` / app toggle). Executor uses `~/.Trash` on macOS.

## Consequences

Reclaim estimates assume Trash move; user can recover from Finder. Cross-platform hosts must implement their own recycle API later.
