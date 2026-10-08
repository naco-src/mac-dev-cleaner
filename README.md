# Mac Dev Cleaner

CLI tool to **scan**, **plan**, and **clean** macOS developer caches (Xcode, Android, Flutter, Node, IDEs) with safety labels and Trash-by-default.

## Quick start

```bash
cd apps/mac-dev-cleaner-cli
dart pub get
dart run bin/mdc.dart scan
dart run bin/mdc.dart plan --safe
dart run bin/mdc.dart clean --safe --yes
```

Activate globally (optional):

```bash
dart pub global activate --source path apps/mac-dev-cleaner-cli
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
