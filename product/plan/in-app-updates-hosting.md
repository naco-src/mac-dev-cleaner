# Future plan: in-app update hosting (private source repo)

Status: **deferred** — not implemented. Tracked as [O6](../decisions/open-deferred.md).

## Problem

`desktop_updater` publish signs **nested** artifact URLs, for example:

`…/releases/stable/<version>/build-<n>/macos/release.json`

Today CI pushes the publish tree to git branch `updates` on the **same** repo as source ([`tool/macos/desktop-updater-upload-github.sh`](../../tool/macos/desktop-updater-upload-github.sh)) and serves them via `raw.githubusercontent.com`.

That breaks in two known ways:

1. **GitHub Release assets** — flat names only (`gh release upload` uses basename; API turns `/` into `.`). Does not match signed paths. Already rejected; branch + raw was chosen instead.
2. **Private repository** — `raw.githubusercontent.com` returns **404** for unauthenticated GET. Publish-time HTTP validation and shipped apps both use unauthenticated GET. Pushes to branch `updates` can succeed while validation still fails.

## Target outcome

In-app updates work when the **application source repo stays private**, without embedding tokens in the app or signed manifests.

## Proposed approach (when implemented)

1. **Public updates-only repo** (for example `naco-src/mac-dev-cleaner-updates`), branch `updates`, no app source — only signed `app-archive.json`, `release.json`, and zip artifacts.
2. **Align URLs** — `updates.baseUrl`, `feedUrl` in `desktop_updater.keys.json`, and `kDesktopUpdaterAppArchiveUrl` in the app all point at  
   `https://raw.githubusercontent.com/naco-src/mac-dev-cleaner-updates/updates`.
3. **CI push token** — secret `DESKTOP_UPDATER_UPDATES_PUSH_TOKEN` (PAT with Contents write on the public updates repo only). `GITHUB_TOKEN` cannot push across repos.
4. **Upload script** — `DESKTOP_UPDATER_UPDATES_REPOSITORY` (default public updates repo); fail fast if that repo is private.
5. **Release workflow** — pass the token and repository env vars into `publish-desktop-updater.sh`.
6. **Keys** — after `feedUrl` change, re-export `release-key.dukey` and refresh `DESKTOP_UPDATER_KEY_BUNDLE_*` secrets.

## Alternatives (not chosen yet)

| Option | Pros | Cons |
| --- | --- | --- |
| Make main repo public | Simplest raw URLs | Exposes source |
| S3 / R2 public bucket | Native path layout; `desktop_updater` S3 provider | Extra infra and secrets |
| GitHub Pages (public site URL) | May work with private repo on paid plans | Path/layout constraints; plan-dependent |

## Verification checklist (when implemented)

- [ ] Unauthenticated `curl -sfI` on `app-archive.json` and a sample `release.json` URL returns 200.
- [ ] Release workflow with **Publish in-app update** passes “Validating hosted release descriptor…”.
- [ ] App **Check for updates** finds a published build.

## References

- [docs/DEVELOPMENT.md](../../docs/DEVELOPMENT.md) — current updater secrets and release inputs (today assumes same-repo `updates` branch).
- Commit `fix(release): host desktop_updater feed on updates branch` — branch upload vs Release assets.
