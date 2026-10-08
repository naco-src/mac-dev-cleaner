# D007 — No sudo in tool

**Status:** Accepted (2026-10-08)

## Context

npm cache failures on root-owned files; ChatGPT scripts used broad sudo.

## Decision

Core, CLI, and app **never** invoke `sudo`. Doctor prints **`chown`** / setup hints; user runs manually.

## Consequences

Some fixes cannot be one-click; acceptable for trust and safety.
