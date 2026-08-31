# Portico Edge downloads

Public install helpers and [GitHub Releases](https://github.com/tvangundy/portico-edge-dist/releases/latest) for **Portico Edge**.

This is a distribution repo only. It does not contain operator tooling, Windsor contexts, or product source.

## Install

```bash
curl -fsSL -o install-edge.sh \
  https://web.porticoworks.dev/install.sh
chmod +x install-edge.sh
./install-edge.sh -o "$HOME/bin"   # put $HOME/bin on your PATH
# Linux always-on host:
#   sudo ./install-edge.sh -o /usr/local/bin
#   sudo edge install --lan-interface eth0
```

Then open **http://127.0.0.1:9191** (or the URL printed by `edge install`).

If the website is not reachable yet, the same script is:

```bash
curl -fsSL -o install-edge.sh \
  https://raw.githubusercontent.com/tvangundy/portico-edge-dist/main/install-edge.sh
```

Onboarding checklist: [web.porticoworks.dev/download](https://web.porticoworks.dev/download/).

## What’s in a release

Archives are named `edge_{Version}_{Os}_{Arch}.tar.gz` (linux/darwin/windows, amd64/arm64). Each archive includes the `edge` binary, these install docs, and optional service templates under `packaging/`.

GitHub always lists **Source code** zip/tar.gz on the same page. Those are a snapshot of this dist repo (docs/scripts), **not** the Edge binary — do not install from them.

## Docs

| Platform | Guide |
|----------|-------|
| macOS | [docs/install/MACOS.md](docs/install/MACOS.md) |
| Ubuntu / Linux | [docs/install/UBUNTU.md](docs/install/UBUNTU.md) |
| Incus (homelab) | [docs/install/INCUS.md](docs/install/INCUS.md) |

## Maintainers

Install scripts here are mirrored from the private Portico Edge source repo. After editing `scripts/install-edge.sh` (or customer `docs/install/`) there, run `task edge:sync-dist`. A `v*` tag on that source repo publishes binaries to this repo’s Releases (Goreleaser). `REPO_ACCESS` needs `contents:write` on this repository.
