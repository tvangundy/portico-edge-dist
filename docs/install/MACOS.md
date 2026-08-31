# Install PME Edge on macOS

Customer guide — no Windsor or Task required. More troubleshooting: [website /troubleshooting/#install](https://web.porticoworks.dev/troubleshooting/#install).

A signed `.pkg` installer is planned next. Until then, use **`sudo edge install`** (root LaunchDaemon) after downloading the binary.

## 1. Prerequisites

```bash
brew install wireguard-tools dnsmasq
```

Use an always-on Mac on your LAN (Mac mini recommended). Note your chip:

- **Apple Silicon** → download `darwin_arm64`
- **Intel** → download `darwin_amd64`

## 2. Download

**Option A — helper script**

```bash
curl -fsSL -o install-edge.sh \
  https://web.porticoworks.dev/install.sh
chmod +x install-edge.sh
./install-edge.sh -o /tmp/edge-download
```

**Option B — manual**

1. Open [Portico Edge releases](https://github.com/tvangundy/portico-edge-dist/releases/latest)
2. Download `edge_*_darwin_arm64.tar.gz` or `edge_*_darwin_amd64.tar.gz`
3. Extract:

```bash
tar -xzf edge_*_darwin_*.tar.gz
chmod +x edge
# If macOS blocks the binary (Gatekeeper):
xattr -d com.apple.quarantine edge 2>/dev/null || true
```

## 3. Install (LaunchDaemon)

`edge install` copies the binary to `/usr/local/bin/edge`, writes `/etc/default/edge`, installs a **root** LaunchDaemon (`com.portico.edge`), and starts it. No sudoers file is required for the customer path.

```bash
# From the extract dir or /tmp/edge-download:
sudo ./edge install
# or, if already on PATH:
sudo edge install
```

Optional flags: `--dry-run`, `--no-split-dns`, `--lan-interface en0`, `--pme-server-url URL`, `--data-dir DIR`, `--listen-addr 127.0.0.1:9191`.

Defaults (filled only when missing in `/etc/default/edge`):

| Key | Default |
|-----|---------|
| `EDGE_DATA_DIR` | `/Library/Application Support/PorticoEdge` |
| `PME_RELAY_ENABLED` | `true` |
| `VPN_LAN_INTERFACE` | `en0` |
| `PME_AGENT_UI_LISTEN_ADDR` | `127.0.0.1:9191` |
| `PME_SERVER_URL` | `https://pme.pmenetwork.com` |

Validate:

```bash
edge doctor
sudo launchctl print system/com.portico.edge | head -20
```

## 4. Register

Open **http://127.0.0.1:9191**

1. Set **PME Server URL** to `https://pme.pmenetwork.com` (if not already)
2. Sign in with your PME account
3. Tap **Register with PME Server**
4. Confirm the dashboard shows relay connected (when entitled)
5. Create an invite under **Invitations**

## 5. Uninstall

```bash
sudo edge uninstall          # stop/unload LaunchDaemon; keep env and data
sudo edge uninstall --purge  # also remove env, binary, data dir
```

## Operator / foreground (optional)

For Windsor fleet work on a laptop (`task edge:run`), you may still use a user session + passwordless sudoers — see the operator [macOS runbook](../runbooks/edge/MACOS.md). That path is not required for household install.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| “damaged” / cannot open | `xattr -d com.apple.quarantine edge` |
| missing `wg` / `dnsmasq` | `brew install wireguard-tools dnsmasq` |
| UI not loading | `edge doctor`; check `sudo tail -f "/Library/Application Support/PorticoEdge/launchd.err.log"` |
| Relay disconnected | Ensure `PME_RELAY_ENABLED=true` in `/etc/default/edge` and account has trial or Mesh Pro |

More: website `/troubleshooting/#install`.
