# Install PME Edge on macOS

Customer guide — no Windsor or Task required. More troubleshooting: [website /troubleshooting/#install](https://web.porticoworks.dev/troubleshooting/#install).

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
./install-edge.sh -o "$HOME/bin"   # or another directory on your PATH
```

**Option B — manual**

1. Open [Portico Edge releases](https://github.com/tvangundy/portico-edge-dist/releases/latest)
2. Download `ws-edge_*_darwin_arm64.tar.gz` or `ws-edge_*_darwin_amd64.tar.gz`
3. Extract and place the `edge` binary somewhere on your PATH:

```bash
tar -xzf ws-edge_*_darwin_*.tar.gz
chmod +x edge
# If macOS blocks the binary (Gatekeeper):
xattr -d com.apple.quarantine edge 2>/dev/null || true
sudo mv edge /usr/local/bin/edge
```

## 3. One-time sudoers (WireGuard, dnsmasq, pf)

Edge runs as your user and calls `sudo -n` for WireGuard, dnsmasq (port 53), pf, routes, and sysctl. Run once:

```bash
MAC_USER="$(whoami)"
WG="$(command -v wg)"
DNSMASQ="$(command -v dnsmasq)"
test -n "${WG}" && test -n "${DNSMASQ}" || { echo "install: brew install wireguard-tools dnsmasq"; exit 1; }

echo "Installing sudoers for ${MAC_USER}"
echo "  wg:      ${WG}"
echo "  dnsmasq: ${DNSMASQ}"

sudo tee /etc/sudoers.d/ws-edge <<EOF
# PME Edge — passwordless wg, dnsmasq, pf
${MAC_USER} ALL=(root) NOPASSWD: ${WG}, ${DNSMASQ}, /sbin/pfctl, /usr/sbin/sysctl, /bin/cp, /bin/cat, /bin/kill, /sbin/route
EOF
sudo chmod 440 /etc/sudoers.d/ws-edge
sudo visudo -c -f /etc/sudoers.d/ws-edge
```

Validate:

```bash
sudo -n wg show
sudo -n /sbin/pfctl -s info | head -1
```

If `sudo -n` asks for a password, re-check paths (`which wg`, `which dnsmasq`). Intel Macs often use `/usr/local/...` instead of `/opt/homebrew/...`.

## 4. Run

```bash
export EDGE_DATA_DIR="${HOME}/.edge"
export PME_RELAY_ENABLED=true   # 30-day trial or Mesh Pro
edge run
```

Open **http://127.0.0.1:9191**

1. Set **PME Server URL** to `https://pme.pmenetwork.com`
2. Sign in with your PME account
3. Tap **Register with PME Server**
4. Confirm the dashboard shows relay connected (when entitled)
5. Create an invite under **Invitations**

Optional checks:

```bash
edge doctor
```

## 5. Optional — launchd (always-on)

The release archive includes `packaging/launchd/com.ws.edge.plist`. After installing `edge` to `/usr/local/bin/edge`:

```bash
# Add EnvironmentVariables for EDGE_DATA_DIR and PME_RELAY_ENABLED in the plist, then:
sudo cp packaging/launchd/com.ws.edge.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.ws.edge.plist
```

Prefer a user LaunchAgent if you want Edge to run only when you are logged in. Several Homes on one Mac: `task edge:new -- --target launchd --name cabin` (label `com.ws.edge.<name>`).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| “damaged” / cannot open | `xattr -d com.apple.quarantine edge` |
| Permission denied on port 53 / pf | Re-run sudoers block; confirm Homebrew paths |
| UI not loading | Confirm `edge run` is still running; try `http://127.0.0.1:9191` |
| Relay disconnected | Ensure `PME_RELAY_ENABLED=true` and account has trial or Mesh Pro |

More: website `/troubleshooting/#install`.
