# D011 — FVM for all Dart/Flutter tooling

**Status:** Accepted (2026-10-08)

## Context

Reproducible Flutter SDK across dev machines and self-hosted runner.

## Decision

**`.fvmrc`** pins Flutter; **`fvm dart`** / **`fvm flutter`** in Makefile, `scripts/`, and macOS release build (`MDC_FLUTTER=fvm flutter`).

## Consequences

Docs and CI assume FVM installed on runner; no `setup-flutter` in GitHub workflows.
