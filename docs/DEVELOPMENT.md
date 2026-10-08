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
| **Release** | same | meta → build macOS assets → upload → (optional in-app publish) → finalize release |

Release uses `MDC_FLUTTER=fvm flutter`, workspace cleanup actions under `.github/actions/`, `tool/ci/gh-release-upload.sh`, and `tool/ci/generate-release-notes.sh` (commit subjects since the previous `v*` tag when release notes are left blank).

In-app updates use [desktop_updater](https://pub.dev/packages/desktop_updater) with the feed at `https://raw.githubusercontent.com/naco-src/mac-dev-cleaner/updates/app-archive.json` (git branch `updates`, not GitHub Release assets). Updates are **optional** in the app (Check for updates in the toolbar; no check on launch). Release workflow: enable **Publish in-app update**; use **Mandatory update** only when you need a forced upgrade. Requires secrets:

- `DESKTOP_UPDATER_KEY_BUNDLE_BASE64` — output of `dart run desktop_updater:release keys export --output release-key.dukey`
- `DESKTOP_UPDATER_KEY_BUNDLE_PASSPHRASE`

Generate keys once in `apps/mac_dev_cleaner` (`desktop_updater.yaml` + `dart run desktop_updater:release keygen`). Commit `desktop_updater.keys.json`; keep `release-key.dukey` out of git. Publish `baseUrl` must match `feedUrl` (today both use the **`updates`** branch on `raw.githubusercontent.com`). After changing `feedUrl` in `desktop_updater.keys.json`, re-export `release-key.dukey` and refresh both GitHub secrets.

**Why not GitHub Release assets?** `desktop_updater` signs nested paths such as `releases/stable/…/macos/release.json`. Release uploads only support flat asset names (`gh release upload` keeps the basename; the API turns `/` into `.`), so `releases/latest/download/…/release.json` never matches the signed URL. [`tool/macos/desktop-updater-upload-github.sh`](tool/macos/desktop-updater-upload-github.sh) pushes the publish tree to branch `updates` instead.

**Release workflow:** When **Publish in-app update** is enabled, CI still undrafts the GitHub Release before publish (zip/dmg install artifacts). Do **not** combine **Pre-release** with **Publish in-app update** if you rely on draft/latest semantics elsewhere. The updater feed itself is branch-based and does not use `releases/latest/download`.

**Private source repo:** `raw.githubusercontent.com` is unauthenticated; a **private** app repo returns 404 for the feed even after a successful push to branch `updates`. **Publish in-app update will fail validation** until [O6](../product/decisions/open-deferred.md) is implemented — see [in-app-updates-hosting.md](../product/plan/in-app-updates-hosting.md) (public updates mirror repo; not built yet).

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
