# mac_dev_cleaner_core

Platform-aware library for scanning, planning, and cleaning developer caches. Used by the `mdc` CLI and the Flutter app.

## API

```dart
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

final mdc = MacDevCleaner();
final items = await mdc.scan(onProgress: (e) => print(e.message));
final plan = mdc.plan(items, safeOnly: true);
await mdc.doctorCheck(onProgress: (e) => print(e.message));
```

## Platform support

| OS | Status |
| --- | --- |
| macOS | Full (`MacOSDevCleanerHost`) |
| Linux | Full (`LinuxDevCleanerHost`; no Xcode rules) |
| Windows | Not implemented — `createDevCleanerHost()` throws |

Extension points: `HostPaths`, `ScanEngine`, `DoctorEngine`, `DiskSpaceProvider`, `DevCleanerHost`.

## Docs

- Repo [ARCHITECTURE.md](../../docs/ARCHITECTURE.md)
- [PLAN.md](../../product/plan/PLAN.md) — scan rule catalog

## Develop

From repo root: `make test` / `fvm dart test packages/mac_dev_cleaner_core`.
