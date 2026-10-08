# D001 — Product and command name

**Status:** Accepted (2026-10-08)

## Context

PLAN used `mdc` as a placeholder; repo and binary need stable naming.

## Decision

- Product name: **Mac Dev Cleaner**
- CLI command: **`mdc`**
- Flutter app display name: **Mac Dev Cleaner**
- Config/history directory: **`~/.mdc/`**

## Consequences

Package names (`mac_dev_cleaner_core`, `mac-dev-cleaner-cli`) and release asset prefix `mac-dev-cleaner-*` follow the product name, not the command.
