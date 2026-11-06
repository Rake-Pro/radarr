# radarr

Radarr on the shared [alpine-base](https://github.com/Rake-Pro/alpine-base) image, built in-house from the upstream release.

```
ghcr.io/rake-pro/radarr
```

## Tags / releases

| Tag | Meaning |
| --- | --- |
| `X.Y.Z` | Immutable release, built from git tag `vX.Y.Z` |
| `X.Y` | Latest patch of that minor |
| `latest` | Latest release |
| `<upstream-version>` | The exact upstream Radarr version baked into that release (currently `6.4.4.10685`) |
| `sha-<short>` | Commit the image was built from |

- `dev` is the integration branch (default); `ci.yml` builds, smoke-tests and Trivy-scans on every push and PR.
- `version-check.yml` polls upstream daily and opens a PR into `dev` bumping the pinned `VERSION` build arg.
- `sync-main.yml` opens a promotion PR from `dev` to `main`. Merging it (merge commit) mints the next patch tag and `release.yml` builds, scans and pushes the image. A fixable CRITICAL finding blocks the push.
- Label the promotion PR `release:minor` or `release:major` to change the bump.
- `trivy-rescan.yml` re-scans the released image weekly (CRITICAL+HIGH) so CVEs disclosed after release still surface.
- Dependabot bumps the base image digest and the GitHub Actions weekly.
- Pin `X.Y.Z` in deployments; `latest` is a convenience pointer.

## Image facts

| Item | Value |
| --- | --- |
| Base | `ghcr.io/rake-pro/alpine-base` (Alpine, patched weekly) |
| Init | `catatonit` as PID 1 |
| User | `65534:65534` from the first process (no s6, no privilege drop, no added capabilities) |
| Data | `/config` (Radarr data dir: config.xml, radarr.db, logs, Backups) |
| Port | `7878` |
| Upstream | <https://github.com/Radarr/Radarr> |
| Upstream version | `6.4.4.10685` (build arg `VERSION`) |
| Platform | linux/amd64 |

## Run

```
docker run -d --name radarr \
  -p 7878:7878 \
  -v /path/to/config:/config \
  ghcr.io/rake-pro/radarr:latest
```

- The `/config` mount must be writable by uid 65534 (`chown -R 65534:65534 /path/to/config`).

## Notes

- Self-contained upstream build: the .NET runtime inside the tarball is upstream's choice (v6 is on .NET 8). Runtime CVEs are not fixable here; they retire with the Radarr v7 line.
- `UpdateMethod=docker` in `/app/package_info` disables in-app updates; bump the image instead.
