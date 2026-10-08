# D009 — macOS app: non-sandboxed + FDA onboarding

**Status:** Accepted (2026-10-08)

## Context

Sandboxed Mac App Store apps cannot read many dev paths; accurate sizes need visibility.

## Decision

Flutter macOS app runs **without App Sandbox**; onboard user to grant **Full Disk Access** to the app (or Terminal when using CLI). Doctor includes FDA reminder.

## Consequences

Distribution via **signed/unsigned DMG/zip + GitHub Releases**, not MAS v1. Notarization is a release hygiene step, not a product gate in repo docs.
