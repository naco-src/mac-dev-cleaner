# Mac Dev Cleaner — agent guide

Dart workspace + Flutter macOS app for scanning and cleaning **developer caches** safely. Product: [`product/product.md`](product/product.md). Rule catalog: [`product/plan/PLAN.md`](product/plan/PLAN.md). Decisions: [`product/decisions/README.md`](product/decisions/README.md).

## Layout

| Path | Role |
| --- | --- |
| `packages/mac_dev_cleaner_core` | Scan, plan, execute, doctor, history; platform abstractions |
| `apps/mac-dev-cleaner-cli` | `mdc` CLI (`bin/mdc.dart`) |
| `apps/mac_dev_cleaner` | Flutter desktop UI (macOS today) |
| `scripts/` + `Makefile` | Bootstrap, test, analyze, run app, packaging |
| `tool/` | CalVer (`release-version.sh`), macOS release scripts, CI helpers |

Root `pubspec.yaml` is a **Dart workspace** (core + CLI only). The Flutter app has its own `pubspec.yaml`.

## Read first

1. [`product/product.md`](product/product.md) — users, journeys, scope
2. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — platform layer, scan pipeline, safety model
3. [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) — FVM, Make targets, CI/release, testing
4. [`product/plan/PLAN.md`](product/plan/PLAN.md) — detailed rule catalog (v1 spec)
5. [`product/decisions/README.md`](product/decisions/README.md) — decision index (one file per ADR)

## Tooling (required)

- **FVM** — all Dart/Flutter via `fvm dart` / `fvm flutter` (`.fvmrc` pins Flutter). Use `make` or `scripts/`; do not call bare `dart`/`flutter` in docs or scripts.
- **Self-hosted CI/Release** — GitHub workflows expect runner labels `self-hosted`, `macOS`, `MYRUNNER` with FVM, Xcode, and `gh` preinstalled.

## Non-negotiables

| Topic | Rule |
| --- | --- |
| Safety | No `sudo` in core or app. Destructive ops default to **Trash**; simulators via `xcrun simctl`, NDK via `sdkmanager --uninstall`. |
| Protected items | `RiskLevel.protected` — report size only, never select for clean. |
| Platform | New OS support = new `DevCleanerHost` + `HostPaths` + `ScanEngine` + `DoctorEngine` in `core/lib/src/platform/`. Keep macOS rules in `ScanService` / `DoctorService` until split. |
| Scope | Minimal diffs; match existing patterns; no drive-by refactors. |
| Tests | Run `make check` (or `make analyze` + `make test`) before claiming done. |

## Cursor rules

Always-on and file-scoped rules live in [`.cursor/rules/`](.cursor/rules/). Update the matching rule when you change a convention documented here.
