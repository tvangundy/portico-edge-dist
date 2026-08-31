# PME Edge — customer install

Download a pre-built binary from [GitHub Releases](https://github.com/tvangundy/portico-edge-dist/releases/latest), then follow the guide for your OS.

Public onboarding (checklist, troubleshooting) lives on the [download page](https://web.porticoworks.dev/download/).

## Layout

Pick one directory as your Edge home. Keep the binary and all agent data there:

```text
~/PorticoEdge/
  bin/edge
  data/
```

```bash
export EDGE_HOME="${HOME}/PorticoEdge"
mkdir -p "${EDGE_HOME}/bin" "${EDGE_HOME}/data"
```

## Release assets

Use **`edge_{Version}_{Os}_{Arch}.tar.gz`** from the release **Assets** list. GitHub always also shows **Source code** zip/tar.gz — those are this dist repo (docs/scripts), not the Edge binary.

Archives are named:

```text
edge_{Version}_{Os}_{Arch}.tar.gz
```

| OS | Arch | Example |
|----|------|---------|
| macOS | Apple Silicon | `edge_0.1.0_darwin_arm64.tar.gz` |
| macOS | Intel | `edge_0.1.0_darwin_amd64.tar.gz` |
| Ubuntu / Linux | x86_64 | `edge_0.1.0_linux_amd64.tar.gz` |
| Ubuntu / Linux | ARM64 | `edge_0.1.0_linux_arm64.tar.gz` |
| Windows | x86_64 | `edge_0.1.0_windows_amd64.tar.gz` |

Each archive includes the `edge` binary, these install docs, `install-edge.sh`, `install-edge-incus.sh`, and optional service unit templates under `packaging/`.

## Quick install (script)

```bash
export EDGE_HOME="${HOME}/PorticoEdge"
mkdir -p "${EDGE_HOME}/bin" "${EDGE_HOME}/data"

curl -fsSL -o /tmp/install-edge.sh \
  https://web.porticoworks.dev/install.sh
chmod +x /tmp/install-edge.sh
/tmp/install-edge.sh -o "${EDGE_HOME}/bin"

# Always-on (macOS LaunchDaemon / Linux systemd):
sudo "${EDGE_HOME}/bin/edge" install --prefix "${EDGE_HOME}" --add-to-path --port next
# Linux: add --lan-interface eth0 (your NIC from ip -br link)
```

Or after downloading a release archive, extract into `${EDGE_HOME}/bin` (or use the bundled `install-edge.sh` with `-t vX.Y.Z`).

## Guides

| Platform | Guide |
|----------|-------|
| macOS | [MACOS.md](./MACOS.md) |
| Ubuntu / Linux | [UBUNTU.md](./UBUNTU.md) |
| Incus (homelab) | [INCUS.md](./INCUS.md) |

## After install

1. Open **http://127.0.0.1:9191/host** (agent) and **http://127.0.0.1:9191/** (ShareAList)
2. Set **PME Server URL** to `https://api.porticoworks.dev`
3. Sign in with your PME account → **Register with PME Server**
4. Enable relay: start Edge with `PME_RELAY_ENABLED=true` (trial or Mesh Pro)
5. Create an invite and test from cellular

Operator / Windsor runbooks live in the private Edge source repo, not this distribution tree.
