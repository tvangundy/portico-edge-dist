# Install PME Edge on Ubuntu

Customer guide for Ubuntu 24.04 LTS (and similar Debian-based hosts). No Windsor or Task required.

Everything lives under one **home directory** (`EDGE_HOME`):

```text
~/PorticoEdge/
  bin/edge     # the application
  data/        # agent state, WireGuard, logs
```

## 1. Prerequisites

```bash
sudo apt update
sudo apt install -y wireguard wireguard-tools dnsmasq nftables iptables curl
```

Kernel WireGuard is used on Linux. Identify your LAN NIC (often `eth0`, `enp*`, or `wlp*`):

```bash
ip -br link
```

You will pass that name to `edge install --lan-interface`.

## 2. Create your Edge home

Expand `$HOME` **before** any `sudo` (sudo may change home):

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

**Option B — manual**

1. Open [Portico Edge releases](https://github.com/tvangundy/portico-edge-dist/releases/latest)
2. Download `edge_*_linux_amd64.tar.gz` or `edge_*_linux_arm64.tar.gz`
3. Extract into `bin/` (use the directory where the browser saved the file):

```bash
tar -xzf ~/Downloads/edge_*_linux_*.tar.gz -C "${EDGE_HOME}/bin"
chmod +x "${EDGE_HOME}/bin/edge"
```

## 4. Always-on — `edge install`

Installs packages if needed, writes `/etc/default/edge` with `EDGE_DATA_DIR=$EDGE_HOME/data`, places/keeps the binary at `$EDGE_HOME/bin/edge`, and enables a systemd unit with `CAP_NET_ADMIN`:

```bash
sudo "${EDGE_HOME}/bin/edge" install --prefix "${EDGE_HOME}" --lan-interface eth0
"${EDGE_HOME}/bin/edge" doctor
```

Change `eth0` to your NIC. Optional flags: `--dry-run`, `--no-split-dns`, `--pme-server-url URL`, `--listen-addr 0.0.0.0:9191`.

Open `http://<host-ip>:9191` (printed at the end of install).

```bash
sudo "${EDGE_HOME}/bin/edge" uninstall --prefix "${EDGE_HOME}"
# sudo "${EDGE_HOME}/bin/edge" uninstall --purge --prefix "${EDGE_HOME}"
```

## 5. Foreground (optional)

Without systemd (debug / temporary):

```bash
export EDGE_DATA_DIR="${EDGE_HOME}/data"
export PME_RELAY_ENABLED=true
export VPN_LAN_INTERFACE=eth0   # change to your NIC
"${EDGE_HOME}/bin/edge" run
```

## 6. Register

Open **http://127.0.0.1:9191** (or the host IP from install):

1. Set **PME Server URL** to `https://pme.pmenetwork.com`
2. Sign in with your PME account
3. Tap **Register with PME Server**
4. Confirm relay connected when entitled
5. Create an invite under **Invitations**

Several Homes on one host: install `packaging/systemd/edge@.service` and use `/etc/default/edge-<name>` with `systemctl enable --now edge@garage`. Homelab Incus: [INCUS.md](./INCUS.md).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Operation not permitted` creating WG iface | Use `sudo … install --prefix` so the unit has `CAP_NET_ADMIN` |
| Wrong LAN / no NAT | Set `--lan-interface` / `VPN_LAN_INTERFACE` to the NIC that reaches your router |
| `dnsmasq` / port 53 busy | Stop conflicting resolvers; check `ss -ulnp \| grep :53` |
| Relay disconnected | `PME_RELAY_ENABLED=true` in `/etc/default/edge`; trial or Mesh Pro on account |
| `--prefix` rejected | Use an absolute path; `export EDGE_HOME="$HOME/PorticoEdge"` before `sudo` |

More: website `/troubleshooting/#install`.
