# PME Edge — customer install

Download a pre-built binary from [GitHub Releases](https://github.com/tvangundy/portico-edge-dist/releases/latest), then follow the guide for your OS.

Public onboarding (checklist, troubleshooting) lives on the [download page](https://web.porticoworks.dev/download/).

## Release assets

Archives are named:

```text
ws-edge_{Version}_{Os}_{Arch}.tar.gz
```

| OS | Arch | Example |
|----|------|---------|
| macOS | Apple Silicon | `ws-edge_0.1.0_darwin_arm64.tar.gz` |
| macOS | Intel | `ws-edge_0.1.0_darwin_amd64.tar.gz` |
| Ubuntu / Linux | x86_64 | `ws-edge_0.1.0_linux_amd64.tar.gz` |
| Ubuntu / Linux | ARM64 | `ws-edge_0.1.0_linux_arm64.tar.gz` |
| Windows | x86_64 | `ws-edge_0.1.0_windows_amd64.tar.gz` |

Each archive includes the `edge` binary, these install docs, `install-edge.sh`, `install-edge-incus.sh`, and optional service unit templates under `packaging/`.

## Quick install (script)

```bash
curl -fsSL -o install-edge.sh \
  https://web.porticoworks.dev/install.sh
chmod +x install-edge.sh
./install-edge.sh -o .
sudo ./edge install   # Linux: packages + systemd (see UBUNTU.md)
# or: ./edge run      # foreground
```

Or after downloading a release archive, use the bundled `install-edge.sh` with `-t vX.Y.Z`.

## Guides

| Platform | Guide |
|----------|-------|
| macOS | [MACOS.md](./MACOS.md) |
| Ubuntu / Linux | [UBUNTU.md](./UBUNTU.md) |
| Incus (homelab) | [INCUS.md](./INCUS.md) |

## After install

1. Open **http://127.0.0.1:9191**
2. Set **PME Server URL** to `https://pme.pmenetwork.com`
3. Sign in with your PME account → **Register with PME Server**
4. Enable relay: start Edge with `PME_RELAY_ENABLED=true` (trial or Mesh Pro)
5. Create an invite and test from cellular

Operator / Windsor runbooks live in the private **ws-edge** repo (`docs/runbooks/edge/`), not this distribution tree.
