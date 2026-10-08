# Mac Dev Cleaner

CLI tool to **scan**, **plan**, and **clean** macOS developer caches (Xcode, Android, Flutter, Node, IDEs) with safety labels and Trash-by-default.

## Quick start

From the repo root (recommended):

```bash
make bootstrap
make cli-scan
make cli-plan-safe
```

Requires [FVM](https://fvm.app) (`fvm install` reads `.fvmrc`). All Dart/Flutter CLI use **`fvm dart`** / **`fvm flutter`** (via `make` and `scripts/`).

Or directly:

```bash
fvm install
make bootstrap
make cli-scan
make cli-plan-safe
make cli-clean-safe   # destructive
```

Activate globally (optional):

```bash
fvm dart pub global activate --source path apps/mac-dev-cleaner-cli
mdc scan
```

## Commands

| Command | Purpose |
| --- | --- |
| `mdc scan` | Read-only list, largest first |
| `mdc plan [--safe \| --select id,id]` | Dry-run what would run |
| `mdc clean [--safe \| --select ...] [--yes] [--delete]` | Execute (Trash unless `--delete`) |
| `mdc doctor` | npm ownership, Homebrew, FDA hint |
| `mdc history` | Log at `~/.mdc/history.jsonl` |

## Environment

- `MDC_PROJECT_ROOTS` — comma-separated project roots for NDK pinning and stale `build/` sweeps (default: `~/Projects`, `~/AndroidStudioProjects`, `~/Developer`, `~/StudioProjects`).

## Safety

- Never runs `sudo`; prints fix commands instead.
- Simulator runtimes use `xcrun simctl runtime delete`.
- Android NDK uninstall uses `sdkmanager --uninstall`.
- Protected locations are report-only.

See [product/plan/PLAN.md](product/plan/PLAN.md) for the full rule catalog.

## Flutter macOS app

```bash
make run-app
# or: make build-macos
```

## Makefile

Run `make help` for targets (`test`, `analyze`, `check`, `mdc ARGS='…'`, etc.). Scripts live in [`scripts/`](scripts/).

Grant **Full Disk Access** to “Mac Dev Cleaner” when prompted (toolbar info icon to reopen the guide).

## Release (macOS)

Versioning uses the same **CalVer + build number** pattern as LaneLift via [`tool/release-version.sh`](tool/release-version.sh):

- **BUILD_NAME** — UTC `YYYY.MM.DD` (Flutter `CFBundleShortVersionString`)
- **BUILD_NUMBER** — minutes since epoch × 100 + CI run mod 100
- **TAG** — `v{BUILD_NAME}+{BUILD_NUMBER}` unless overridden

```bash
make release-version    # print BUILD_NAME, BUILD_NUMBER, TAG
make macos-release      # signed/unsigned Release .app locally
make macos-packaging    # arm64 + x64 .zip and .dmg at repo root
```

GitHub: **Actions → Release** and **CI** (workflow_dispatch) run on self-hosted **MYRUNNER** with FVM (no Flutter/Dart setup in the workflow). Requires `fvm`, `gh`, and Xcode on the runner.
