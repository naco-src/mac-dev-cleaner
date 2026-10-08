# MDC decisions

Product and technical decisions for **Mac Dev Cleaner** (`mdc`). Each file: context → decision → consequences. Supersedes [plan/PLAN.md](../plan/PLAN.md) §9 where noted.

## Accepted

| ID | Title |
| --- | --- |
| [D001](./D001-product-and-command-name.md) | Product and command name |
| [D002](./D002-cli-and-flutter-app.md) | CLI + Flutter app (not CLI-only) |
| [D003](./D003-dart-core-package.md) | Dart core package as single source of truth |
| [D004](./D004-trash-default.md) | Trash as default delete semantics |
| [D005](./D005-project-roots-env.md) | Project roots via environment |
| [D006](./D006-disk-space-data-volume.md) | Disk space: macOS Data volume |
| [D007](./D007-no-sudo.md) | No sudo in tool |
| [D008](./D008-simctl-sdkmanager-uninstall.md) | Simulator runtimes and NDK uninstall commands |
| [D009](./D009-macos-app-fda-non-sandbox.md) | macOS app: non-sandboxed + FDA onboarding |
| [D010](./D010-platform-abstraction.md) | Platform abstraction for future OS |
| [D011](./D011-fvm-tooling.md) | FVM for all Dart/Flutter tooling |
| [D012](./D012-self-hosted-ci-release.md) | CI and release on self-hosted MYRUNNER |
| [D013](./D013-calver-release-tags.md) | Versioning and release tags (CalVer) |
| [D014](./D014-parallel-scan.md) | Scan performance: parallel phases and bounded I/O |
| [D015](./D015-repo-layout.md) | Repository layout vs PLAN diagram |

## Open / deferred

See [open-deferred.md](./open-deferred.md).

## Add a decision

1. Create **`D0xx-short-slug.md`** (next number) with status, context, decision, consequences.
2. Add a row to the table above.
3. If user-visible, update [product.md](../product.md).
4. If rules change, update [plan/PLAN.md](../plan/PLAN.md).
5. If architecture shifts, update [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md) and `.cursor/rules/` as needed.
