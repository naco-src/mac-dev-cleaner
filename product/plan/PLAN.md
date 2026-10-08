# Mac Dev Cleaner: Plan v1

Date: 2026-10-08
Source: the shared ChatGPT chat "macos clear cache and storage for dev command" (Nhã's MacBook, 228 GB disk).

## 1. Goal

A tool for a macOS developer machine (Flutter, Xcode, Android, Node, AI IDEs) that:

1. Scans the known space hogs and shows real sizes, sorted biggest first.
2. Labels every item **Safe**, **Conditional** (needs a check or a choice), or **Protected** (never touched).
3. Explains what each item is and what it costs to delete (for example, "re-downloaded on next build").
4. Cleans only what the user picks, with a dry run by default and the tool's own command where one exists (`xcrun simctl`, `sdkmanager`, `brew`, `npm`) instead of `rm -rf`.

## 2. What the chat taught us (requirements)

Findings from the real machine:

| Location | Size | Notes |
| --- | --- | --- |
| `~/Library/Application Support` | 46 GB | Cursor 18 GB, Google 12 GB, JetBrains 5.6 GB, Code 3.6 GB, Antigravity 3 GB, Figma 1.6 GB |
| `~/Library/Android/sdk` | 31 GB | `ndk` 16 GB, `system-images` 12 GB, everything else about 3 GB |
| iOS simulator runtimes (APFS mounts) | about 42 GB | `iOS_22D8075` 18 GB, `iOS_23C54` 16 GB, Cryptex runtime 8.4 GB |
| `~/.gradle` | 5.2 GB | after `caches` was already wiped |
| `~/Library/Developer` | 4.5 GB | DerivedData and Archives already cleared |
| `~/Library/Caches`, `~/.pub-cache` | under 0.5 GB each | already clean |

Lessons that become rules:

- **Blanket cache wipes free little.** The generic script cleared caches, but 141 GB stayed used. The tool must find the biggest items first, not delete a fixed list.
- **Download caches are cheap to lose but cost time.** `~/.pub-cache`, `~/.gradle/caches`, and npm caches come back on the next build. Show that cost instead of hiding it.
- **Some things must never be removed with `rm`.** Simulator runtimes are mounted APFS volumes; remove them with `xcrun simctl runtime delete`. Android packages go through `sdkmanager --uninstall`.
- **Versions can be pinned by projects.** An NDK version referenced by `ndkVersion` in a project, or the Flutter default, must be kept.
- **Ownership problems happen.** `npm cache clean` failed on root-owned files in `~/.npm`. The tool should detect this and print the `chown` fix, never run `sudo` by itself.
- **`df` is misleading on APFS.** Report the Data volume (`/System/Volumes/Data`) and free space, not a sum of all lines.
- **Problems in the ChatGPT script to avoid:** it ran `flutter clean` in whatever folder the user was in (it was run from `actions-runner`), deleted all Xcode Archives (these hold dSYMs for crash symbolication), and wiped all of `~/Library/Caches` and `~/.pub-cache` for little gain.

## 3. Shape of the product

**Phase 1 is a Dart CLI**, because Nhã is a Flutter developer and the scanning and rules can live in a pure Dart package that a Flutter macOS app reuses later.

```
mac-dev-cleaner/
  packages/core/        # pure Dart: rules, scanner, planner, executor
  apps/cli/             # `mdc` command
  apps/desktop/         # (later) Flutter macOS app on top of core
```

Commands:

- `mdc scan` lists items with size, label, and reason. Read-only.
- `mdc plan [--safe | --select id,id]` shows exactly what would be deleted or run, and the total reclaimable size.
- `mdc clean [--select ...] [--trash | --delete] [--yes]` executes the plan. Without `--yes` it asks per group.
- `mdc doctor` checks npm ownership, `sudo npm` leftovers, Homebrew health, and Full Disk Access.
- `mdc history` shows past cleanups from the log.

## 4. Core design

**Rule** (one entry per cleanable thing):

- `id`, `name`, `group` (Xcode, Android, Flutter, Node, Homebrew, IDE, Browser, Projects, macOS)
- `paths` (globs under `~`), or a `detector` function for smart rules
- `risk`: safe, conditional, protected
- `method`: delete contents, move to Trash, or run a command
- `precondition`: for example "Cursor is not running" (checked with `pgrep`)
- `regenerates`: "automatically", "on next build", "re-download", "never (user data)"
- `explain`: one or two plain sentences shown to the user

**Pipeline:** Rules, then Scanner (sizes in parallel, does not follow symlinks, stays on one volume), then Classifier (applies smart checks), then Planner (dry run), then Executor (does the work and logs it), then Report (before and after free space).

**Abstractions for testing:** a `FileSystem` interface (use `package:file`, with `MemoryFileSystem` in tests) and a `CommandRunner` interface so `xcrun`, `sdkmanager`, `brew`, and `npm` calls can be faked.

## 5. Rule catalog v1

### Safe (cleanable by default)

| Item | Path or command | Comes back |
| --- | --- | --- |
| Xcode DerivedData | `~/Library/Developer/Xcode/DerivedData/*` | on next build |
| Unavailable simulators | `xcrun simctl delete unavailable` | n/a |
| CocoaPods cache | `~/Library/Caches/CocoaPods` | re-download |
| Homebrew | `brew cleanup` (preview with `brew cleanup -n`) | n/a |
| npm cache | `npm cache clean --force` after the ownership check | re-download |
| pnpm, Yarn | `pnpm store prune`, `yarn cache clean` | re-download |
| Gradle caches | `~/.gradle/caches`, old `~/.gradle/daemon` logs | on next build |
| Android build cache | `~/.android/build-cache` | on next build |
| Editor caches (Cursor, Code, Antigravity) | `Cache`, `CachedData`, `Code Cache`, `GPUCache`, `CachedExtensionVSIXs`, `logs` inside each app's Application Support folder; app must be closed | automatically |
| User logs | `~/Library/Logs/*` | automatically |

### Conditional (needs a smart check or user choice)

| Item | Smart check |
| --- | --- |
| Android NDK versions (16 GB) | Keep versions referenced by `ndkVersion` in `build.gradle`/`build.gradle.kts` under project roots, plus the default from the installed Flutter SDK. Offer the rest via `sdkmanager --uninstall "ndk;<ver>"`. |
| Android system images (12 GB) | Parse `~/.android/avd/*.avd/config.ini` (`image.sysdir.1`). Images not used by any AVD are candidates. Offer to delete old AVDs too. |
| Android platforms and build-tools | Keep the newest few and any version referenced by projects (`compileSdk`, `buildToolsVersion`). |
| iOS simulator runtimes (about 42 GB) | `xcrun simctl runtime list -j` and `xcrun simctl list devices -j`. Show which runtimes have devices. Delete with `xcrun simctl runtime delete <id>`, never `rm`. |
| Xcode Archives | Group by app, keep the newest N per app (they hold dSYMs). |
| iOS DeviceSupport | Keep versions matching devices recently connected; offer older ones. |
| JetBrains (5.6 GB) | Folders for old IDE versions (for example an older `AndroidStudio20xx.x` when a newer one exists) are candidates; caches inside the current version are safe. |
| Editor workspace storage | `User/workspaceStorage/*` entries for folders that no longer exist or have not been opened for 90+ days. Large items in `User/globalStorage` are shown, not auto-deleted. |
| Chrome / Google (12 GB) | Break down by profile. Show `Cache`, `Code Cache`, `Service Worker/CacheStorage` as cleanable with Chrome closed. Other large folders (for example on-device model data) are shown for the user to decide after checking what they are. |
| Gradle wrappers and JDKs | Keep wrapper versions used by project `gradle-wrapper.properties`; offer the rest. |
| `~/.pub-cache` | Offer only when large; warn that everything re-downloads. |
| Project build output | Under configured roots (for example `~/Projects`, `~/AndroidStudioProjects`): `build/`, `.dart_tool/`, `ios/Pods`, `android/.gradle`, `node_modules/` in projects not modified for 30+ days. Listed per project. Never touches `Podfile.lock` or source. |

### Protected (never touched, only reported)

Whole Application Support folders, editor `User/settings` and `extensions`, browser profile data (cookies, logins, history, bookmarks), Keychains, `~/.ssh`, mounted CoreSimulator volumes, `~/Library/Android/sdk/licenses`, `platform-tools`, project source, and anything inside iCloud Drive or other sync folders.

## 6. Safety rules

- Dry run is the default. Destructive actions need `clean` plus a confirmation or `--yes`.
- Move to Trash is the default for folders; permanent delete is opt-in.
- Never runs `sudo`. Prints the exact command instead.
- Only acts on paths matched by a rule; refuses anything outside the allowlist, and never follows symlinks.
- Checks that the owning app is closed before touching its caches.
- Logs every action (path, size, method, time) to `~/.mdc/history.jsonl`.
- Prints free space on the Data volume before and after.

## 7. Milestones

1. **M0 Setup.** Dart workspace (`packages/core`, `apps/cli`), lints, CI running tests, `MemoryFileSystem` fixtures.
2. **M1 Scan (read-only).** Rule model, scanner, `mdc scan` table. Done when it reproduces the sizes from the chat on the real Mac.
3. **M2 Safe clean.** Safe rules, planner, executor with Trash, history log, before/after report.
4. **M3 Smart Android.** NDK pinning, AVD to system-image mapping, platforms and build-tools, all through `sdkmanager`.
5. **M4 Smart Xcode.** Simulator runtimes, Archives keep-N, DeviceSupport.
6. **M5 IDE and browser.** Cursor, Code, Antigravity, JetBrains, Chrome breakdowns and cache rules.
7. **M6 Project sweeper.** Configurable roots, age filter, per-project listing.
8. **M7 Doctor.** npm ownership, Homebrew, Full Disk Access check.
9. **M8 (optional) Flutter macOS app.** List or treemap view, checkboxes, onboarding for Full Disk Access. Not sandboxed, so ship as a notarized DMG or Homebrew cask rather than the Mac App Store.
10. **M9 (optional) Scheduled report.** A `launchd` job runs `mdc scan` weekly and notifies when reclaimable space passes a threshold.

## 8. Testing

- Unit tests for every rule and smart check against fake file trees and faked command output (`simctl` JSON, `sdkmanager --list_installed`, AVD `config.ini`).
- An integration test that runs `clean` against a throwaway folder tree, never the real home folder.
- A manual checklist on the real Mac: run `scan` and `plan` first, compare with the numbers above, then clean one group at a time.

## 9. Open decisions (for implementation time)

**Resolved** — see [decisions/README.md](../decisions/README.md) (D001–D015). Remaining open items: [open-deferred.md](../decisions/open-deferred.md).

Historical prompts (answered in decision log):

- Name of the tool and command (`mdc` is a placeholder).
- CLI only, or also the Flutter macOS app.
- Which folders count as project roots.
- Trash or permanent delete as the default.
- Where the repo lives and how it is distributed (GitHub Releases, Homebrew tap).
