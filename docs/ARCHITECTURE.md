# Architecture

## Purpose

Mac Dev Cleaner **discover**s reclaimable developer disk usage, **labels** each item by risk, lets the user **plan** a subset, and **executes** cleanup (Trash by default). It does not replace system cleaners or delete arbitrary user data.

## Packages

### `mac_dev_cleaner_core`

Single library consumed by CLI and Flutter app.

```
MacDevCleaner
  └── DevCleanerHost          (platform bundle; factory: createDevCleanerHost)
        ├── HostPaths         (home, trash, ~/.mdc, Gradle/pub/npm/Android, …)
        ├── ScanEngine        (macOS: ScanService; Linux: LinuxScanService)
        ├── DoctorEngine      (macOS: DoctorService; Linux: LinuxDoctorService)
        └── DiskSpaceProvider (macOS / Linux providers)
```

**Cross-platform code** should depend on `HostPaths`, `ScanEngine`, and `DoctorEngine`, not macOS path types.

**macOS-only code** today:

- `MacOSHostPaths` / `MacOSPaths` — `~/Library`, Xcode, Application Support
- `ScanService` — rule groups (Xcode, Android, IDE, projects, …)
- `DoctorService` — npm ownership, Homebrew, FDA hint

Shared pieces: `Planner`, `Executor`, `HistoryLog`, `SizeScanner`, `ProjectRefs`, models (`ScanItem`, `CleanPlan`, …).

### Scan pipeline

1. **Index projects** — Gradle `ndkVersion`, project paths from `MDC_PROJECT_ROOTS` / defaults.
2. **Parallel phases** — safe, Android, Xcode, IDE/browser, stale projects, protected totals (see `ScanService.scanAll`).
3. **Size** — `SizeScanner` with bounded concurrency (`mapConcurrent`).
4. **Sort** — largest `sizeBytes` first.

Progress: `ScanProgressCallback` → `ScanLogEntry` (info / warning / error).

### Clean pipeline

1. `Planner.buildPlan` — selected ids, skips non-cleanable / protected.
2. `Executor.execute` — per item: `runCommand`, `moveToTrash`, or delete contents; append `~/.mdc/history.jsonl`.

### Risk model

| Level | Meaning |
| --- | --- |
| `safe` | Regenerates or re-downloads; often selected by default |
| `conditional` | User judgment (NDK not in projects, old archives, pub cache, …) |
| `protected` | Context only; never cleaned |

`ScanItem.cleanable` requires `cleanAction`, not protected, and preconditions met (e.g. editor not running).

## Flutter app (`mac_dev_cleaner`)

- **Provider** + `CleanerController` — scan state, selection, filters, treemap drill-down, doctor/history logs.
- **Home** — Results (list/treemap) + Details (activity log, item dump).
- **Doctor / History** — separate tabs; doctor uses same core `DoctorEngine` with UI logging.
- **macOS** — non-sandboxed entitlements, FDA onboarding via `url_launcher`.

UI must not embed scan rules; call `MacDevCleaner` only.

## CLI (`mdc`)

Thin wrapper around `MacDevCleaner`: `scan`, `plan`, `clean`, `doctor`, `history`. Entry: `apps/mac-dev-cleaner-cli/bin/mdc.dart`.

## Adding a new platform (Linux / Windows)

1. Implement `HostPaths` (and OS-specific sub-interface if needed).
2. Implement `ScanEngine` + `DoctorEngine` + `DiskSpaceProvider`.
3. Add `*DevCleanerHost` and a branch in `createDevCleanerHost()` (`host_factory.dart`).
4. Flutter: new runner target when UI is ported; keep core free of `dart:io` UI assumptions where possible.

Do not fork `Planner` / `Executor` unless trash or command semantics differ materially.

## Related docs

- [PLAN.md](../product/plan/PLAN.md) — full rule list
- [DEVELOPMENT.md](./DEVELOPMENT.md) — build and release
