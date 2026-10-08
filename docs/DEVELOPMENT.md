# Development

## Prerequisites

- macOS (for app and current scan rules)
- [FVM](https://fvm.app) on `PATH`
- Xcode + CocoaPods (Flutter macOS builds)
- Optional: Android SDK paths for conditional Android rules during local scan

## First-time setup

```bash
fvm install          # reads .fvmrc (Flutter pin)
make bootstrap       # workspace pub get + Flutter app pub get
make check           # analyze + test
```

All Makefile and `scripts/*` targets use **`fvm dart`** and **`fvm flutter`** via `scripts/lib.sh` (`mdc_dart`, `mdc_flutter`).

## Common commands

| Goal | Command |
| --- | --- |
| CLI scan | `make cli-scan` or `make mdc ARGS='scan -v'` |
| Run app | `make run-app` |
| Release .app | `make macos-release` |
| arm64 + x64 zip/dmg | `make macos-packaging` |
| Version env vars | `make release-version` |
| Clean artifacts | `make clean` |

## Environment

- **`MDC_PROJECT_ROOTS`** — comma-separated roots for project index and stale `build/` sweeps.

## Testing

- **Core:** `fvm dart test` in `packages/mac_dev_cleaner_core` (or `make test`).
- **App:** `fvm flutter test` in `apps/mac_dev_cleaner`.
- Widget tests inject `CleanerController` with fake items; avoid live disk scan in unit tests.

## Analyze

```bash
make analyze
```

Analyzes Dart workspace (core + CLI) and Flutter app separately.

## CI and release (GitHub Actions)

Both workflows are **`workflow_dispatch` only**.

| Workflow | Runner | Steps |
| --- | --- | --- |
| **CI** | `[self-hosted, macOS, MYRUNNER]` | `fvm install` → `make check` |
| **Release** | same | meta → build macOS assets → publish release |

Release uses `MDC_FLUTTER=fvm flutter`, workspace cleanup actions under `.github/actions/`, and `tool/ci/gh-release-upload.sh`.

Local packaging mirrors CI: `tool/macos/package-release-assets.sh` with `BUILD_NAME`, `BUILD_NUMBER`, `TAG`.

## Project conventions

- **CalVer** — `tool/release-version.sh` exports `BUILD_NAME`, `BUILD_NUMBER`, `TAG`.
- **Commits** — concise imperative subject; explain why in body when non-obvious.
- **Core changes** — prefer interfaces in `lib/src/platform/` for anything OS-specific.
- **App changes** — keep widgets dumb; state in `CleanerController`.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Scan sizes too small | Full Disk Access for app/Terminal; Doctor tab |
| npm clean fails | Doctor → root-owned `~/.npm`; run suggested `chown` yourself |
| FVM not found | Install FVM; run from repo root after `fvm install` |
| Release job fails | Runner has FVM, Flutter SDK for `.fvmrc`, Xcode, `gh` auth |

See [ARCHITECTURE.md](./ARCHITECTURE.md) for design detail.
