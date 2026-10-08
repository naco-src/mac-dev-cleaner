# Mac Dev Cleaner — product overview

**Command:** `mdc`  
**Platforms:** macOS and Linux (CLI + desktop app); Windows planned via core platform layer  
**Distribution:** GitHub Releases (unsigned macOS `.zip` / `.dmg`); global CLI via `dart pub global activate`

## Problem

Developer Macs accumulate tens of gigabytes under Xcode, Android SDK, Gradle, pub, npm, and IDE caches. Generic “clean my Mac” scripts and ad-hoc `rm -rf` lists:

- Free little space relative to risk (blanket cache wipes).
- Break simulators, NDK pinning, or crash symbolication (Archives, runtimes).
- Require `sudo` or hide what will happen.

Developers need **visibility first** (sizes, labels, explanations), then **controlled cleanup** with sensible defaults.

## Vision

One tool that **scans → labels → plans → cleans** using explicit rules, official commands where they exist, and Trash by default—never silent `sudo`.

## Primary users

- **Flutter / mobile developers** (Xcode + Android SDK + Gradle + pub).
- **Full-stack / Node developers** (npm, pnpm, Yarn, browser IDE caches).
- **Power users** comfortable with CLI; optional GUI for scan/select/clean and onboarding (Full Disk Access).

## User journeys

### 1. Discover space (read-only)

1. Run **Scan** (`mdc scan` or app Home → Scan).
2. See items sorted by size with **Safe / Conditional / Protected** badges.
3. Read short **explain** text and **regenerates** hint (e.g. “on next build”, “re-download”).
4. Optional: **Details** tab / verbose log for phases and per-item paths.

**Success:** User understands where ~GB live before deleting anything.

### 2. Clean safely

1. Default selection: **Safe** items that pass preconditions (e.g. editor quit).
2. **Plan** (`mdc plan --safe`) or app selection + plan summary.
3. **Clean** moves paths to **Trash** unless user opts into permanent delete.
4. **History** records actions in `~/.mdc/history.jsonl`.

**Success:** Reclaimed space with recoverable Trash and an audit trail.

### 3. Advanced / conditional

1. Review **Conditional** items (unused NDK, system images, simulator runtimes, old Archives, stale project `build/`).
2. Opt in per item; NDK/simulator use **`sdkmanager`** / **`simctl`**, not raw delete.
3. **Protected** rows (e.g. whole Application Support totals) are **report-only**.

**Success:** Large wins (NDK, runtimes, Archives) without breaking active projects.

### 4. Preflight (Doctor)

1. Run **Doctor** before trusting sizes or npm clean.
2. Surface npm cache ownership, suspicious global npm, Homebrew doctor, Full Disk Access reminder.
3. Copy suggested fix commands; tool does **not** run them.

**Success:** Fewer failed cleans and under-reported scan sizes explained.

## Feature set (v1)

| Area | CLI | App |
| --- | --- | --- |
| Scan all rule groups | ✓ | ✓ |
| List + treemap views | — | ✓ |
| Filter / search / select | `--select` | ✓ |
| Plan dry-run | ✓ | Plan dialog |
| Clean (Trash / delete) | ✓ | ✓ |
| Doctor | ✓ | ✓ + activity log |
| History | ✓ | ✓ |
| Disk space (Data volume) | ✓ | ✓ |
| Parallel scan / doctor | ✓ | ✓ |

## Rule groups

Xcode, Android, Flutter, Node, Homebrew, IDE, Browser, Projects, macOS (protected totals).

Full path/command catalog: [plan/PLAN.md](./plan/PLAN.md) §5.

## Safety principles (product)

1. **No sudo** — print fixes; user runs elevated commands if needed.
2. **Allowlist only** — only paths/commands defined by rules.
3. **Trash default** — permanent delete is explicit.
4. **Smart commands** — simulator runtimes and NDK uninstall via Apple/Google tooling.
5. **Preconditions** — don’t clean IDE caches while the app is running.
6. **Protected** — never delete whole profile/settings/source trees; report context sizes only.

## Out of scope (v1)

- Mac App Store distribution (app is non-sandboxed for accurate scans).
- Cleaning non-developer categories (Photos, Mail, system caches outside dev rules).
- Automatic scheduled clean without user review (optional future: scan-only report).
- Windows support (core + UI).
- Linux GitHub Release / in-app update artifacts (macOS-only today).

## Success metrics (informal)

- Scan totals on a “typical” dev Mac align with manual `du` / PLAN reference machine within reasonable tolerance (FDA permitting).
- Safe clean reclaim without breaking next `flutter build`, Gradle sync, or npm install.
- Zero automatic privileged operations.

## Related

- Engineering architecture: [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)
- Decision log: [decisions/README.md](./decisions/README.md)
- Implementation plan: [plan/PLAN.md](./plan/PLAN.md)
