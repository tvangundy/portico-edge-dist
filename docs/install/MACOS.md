# Install PME Edge on macOS

Customer guide — no Windsor or Task required. More troubleshooting: [website /troubleshooting/#install](https://web.porticoworks.dev/troubleshooting/#install).

Everything lives under one **home directory** (`EDGE_HOME`):

```text
~/PorticoEdge/
  bin/edge     # the application
  data/        # agent state, WireGuard, logs
```

A signed `.pkg` is planned next. Until then: create that tree, download into `bin/`, then `sudo … install --prefix`.

## 1. Prerequisites

```bash
brew install wireguard-tools dnsmasq
```

Use an always-on Mac on your LAN (Mac mini recommended). Note your chip:

- **Apple Silicon** → download `darwin_arm64`
- **Intel** → download `darwin_amd64`

## 2. Create your Edge home

Expand `$HOME` **before** any `sudo` (sudo may change home to `/var/root`):

```bash
export EDGE_HOME="${HOME}/PorticoEdge"
mkdir -p "${EDGE_HOME}/bin" "${EDGE_HOME}/data"
```

## 3. Get the binary into `bin/`

**Option A — helper script**

```bash
curl -fsSL -o /tmp/install-edge.sh \
  https://web.porticoworks.dev/install.sh
chmod +x /tmp/install-edge.sh
/tmp/install-edge.sh -o "${EDGE_HOME}/bin"
```

**Option B — curl the binary asset**

On the GitHub release, use an **`edge_*_darwin_arm64.tar.gz`** (or `darwin_amd64`) link under **Assets**. Do **not** use **Source code** zip/tar.gz — GitHub always lists those, and they are not the Edge binary.

Paste the asset URL (or use Option A, which resolves latest for you):

```bash
curl -fsSL -o /tmp/edge.tgz "PASTE_ASSET_URL"
rm -rf /tmp/portico-edge-extract
mkdir -p /tmp/portico-edge-extract "${EDGE_HOME}/bin"
tar -xzf /tmp/edge.tgz -C /tmp/portico-edge-extract
cp /tmp/portico-edge-extract/edge "${EDGE_HOME}/bin/edge"
chmod +x "${EDGE_HOME}/bin/edge"
xattr -d com.apple.quarantine "${EDGE_HOME}/bin/edge" 2>/dev/null || true
```

## 4. Install (LaunchDaemon)

`edge install --prefix` copies/keeps the binary at `$EDGE_HOME/bin/edge`, sets `EDGE_DATA_DIR` to `$EDGE_HOME/data`, writes `/etc/default/edge`, and installs a **root** LaunchDaemon (`com.portico.edge`).

```bash
sudo "${EDGE_HOME}/bin/edge" install --prefix "${EDGE_HOME}"
```

Optional flags: `--dry-run`, `--no-split-dns`, `--lan-interface en0`, `--pme-server-url URL`, `--listen-addr 127.0.0.1:9191`.

Defaults (filled only when missing in `/etc/default/edge`):

| Key | With `--prefix` |
|-----|-----------------|
| `EDGE_DATA_DIR` | `$EDGE_HOME/data` |
| `PME_RELAY_ENABLED` | `true` |
| `VPN_LAN_INTERFACE` | `en0` |
| `PME_AGENT_UI_LISTEN_ADDR` | `127.0.0.1:9191` |
| `PME_SERVER_URL` | `https://pme.pmenetwork.com` |

Validate:

```bash
"${EDGE_HOME}/bin/edge" doctor
sudo launchctl print system/com.portico.edge | head -20
```

## 5. Register

Open **http://127.0.0.1:9191**

1. Set **PME Server URL** to `https://pme.pmenetwork.com` (if not already)
2. Sign in with your PME account
3. Tap **Register with PME Server**
4. Confirm the dashboard shows relay connected (when entitled)
5. Create an invite under **Invitations**

## 6. Uninstall

```bash
sudo "${EDGE_HOME}/bin/edge" uninstall --prefix "${EDGE_HOME}"
# also remove env, binary, and data/:
# sudo "${EDGE_HOME}/bin/edge" uninstall --purge --prefix "${EDGE_HOME}"
```

## Foreground (optional)

Without LaunchDaemon (laptop / debug):

```bash
export EDGE_DATA_DIR="${EDGE_HOME}/data"
export PME_RELAY_ENABLED=true
"${EDGE_HOME}/bin/edge" run
```

Operator Windsor fleet path (`task edge:run`) remains separate — see [macOS runbook](../runbooks/edge/MACOS.md).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `tar: …tar.gz: m: No such file or directory` | macOS bsdtar for “file not found”. You used GitHub **Source code** or a path that does not exist. Use Option A, or curl an `edge_*_*.tar.gz` **Assets** URL. |
| “damaged” / cannot open | `xattr -d com.apple.quarantine "${EDGE_HOME}/bin/edge"` |
| missing `wg` / `dnsmasq` | `brew install wireguard-tools dnsmasq` |
| UI not loading | `"${EDGE_HOME}/bin/edge" doctor`; `sudo tail -f "${EDGE_HOME}/data/launchd.err.log"` |
| Relay disconnected | Ensure `PME_RELAY_ENABLED=true` in `/etc/default/edge` and account has trial or Mesh Pro |
| `--prefix` rejected | Use an absolute path; run `export EDGE_HOME="$HOME/PorticoEdge"` before `sudo` |

More: website `/troubleshooting/#install`.
