# Open / deferred decisions

Not yet accepted or not implemented.

| ID | Topic | Notes |
| --- | --- | --- |
| O1 | Homebrew tap | GitHub Releases only for now |
| O2 | M9 scheduled scan + notification | Not implemented |
| O3 | Windows host | Factory throws `UnsupportedError` (Linux: `LinuxDevCleanerHost`) |
| O4 | Notarization / Apple Developer ID | Release scripts produce unsigned builds; signing policy TBD |
| O5 | Rename command from `mdc` | Keep unless collision with another global CLI |
| O6 | In-app update hosting with private source | Branch `updates` + raw URLs 404 when repo is private; plan in [in-app-updates-hosting.md](../plan/in-app-updates-hosting.md) (public updates repo or other host) |

When an item is decided, move it to a new **D0xx** file and remove the row here.
