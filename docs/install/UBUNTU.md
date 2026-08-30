# Install PME Edge on Ubuntu

Customer guide for Ubuntu 24.04 LTS (and similar Debian-based hosts). No Windsor or Task required.

## 1. Prerequisites

```bash
sudo apt update
sudo apt install -y wireguard wireguard-tools dnsmasq nftables iptables curl
```

Kernel WireGuard is used on Linux (no userspace `wg-quick` tunnel required for the home interface). Identify your LAN NIC (often `eth0`, `enp*`, or `wlp*`):

```bash
ip -br link
```

You will set `VPN_LAN_INTERFACE` to that name when running Edge.

## 2. Download

**Option A — helper script**

```bash
curl -fsSL -o install-edge.sh \
  https://web.porticoworks.dev/install.sh
chmod +x install-edge.sh
sudo ./install-edge.sh -o /usr/local/bin
```

**Option B — manual**

1. Open [Portico Edge releases](https://github.com/tvangundy/portico-edge-dist/releases/latest)
2. Download `edge_*_linux_amd64.tar.gz` or `edge_*_linux_arm64.tar.gz`
3. Install the binary:

```bash
tar -xzf edge_*_linux_*.tar.gz
chmod +x edge
sudo mv edge /usr/local/bin/edge
```

## 3. Run (foreground)

```bash
export EDGE_DATA_DIR="${HOME}/.edge"
export PME_RELAY_ENABLED=true
export VPN_LAN_INTERFACE=eth0   # change to your NIC
edge run
```

If you see permission errors creating WireGuard interfaces or binding DNS, run under systemd with capabilities (next section) or temporarily with `sudo` while keeping `EDGE_DATA_DIR` under your home:

```bash
sudo EDGE_DATA_DIR="${HOME}/.edge" PME_RELAY_ENABLED=true VPN_LAN_INTERFACE=eth0 edge run
```

Open **http://127.0.0.1:9191** on the host (or SSH tunnel if headless).

1. Set **PME Server URL** to `https://pme.pmenetwork.com`
2. Sign in with your PME account
3. Tap **Register with PME Server**
4. Confirm relay connected when entitled
5. Create an invite under **Invitations**

```bash
edge doctor
```

## 4. Always-on — `edge install`

After the binary is on the machine (section 2), let Edge install itself: packages, `/etc/default/edge`, and a systemd unit with `CAP_NET_ADMIN`:

```bash
sudo edge install --lan-interface eth0   # change to your NIC
edge doctor
```

Optional flags: `--dry-run`, `--no-split-dns`, `--pme-server-url URL`, `--data-dir DIR`. Existing `/etc/default/edge` keys are kept (only missing customer defaults are filled).

Open `http://<host-ip>:9191` (printed at the end of install). The unit file is embedded in the binary; you do not need the release archive's `packaging/` directory.

```bash
sudo edge uninstall          # stop/disable unit; keep data and env
sudo edge uninstall --purge  # also remove env, binary, and data dir
```

Several Homes on one host: install `packaging/systemd/edge@.service` and use `/etc/default/edge-<name>` with `systemctl enable --now edge@garage`. Homelab Incus: [INCUS.md](./INCUS.md).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Operation not permitted` creating WG iface | Run `sudo edge install` so the systemd unit has `CAP_NET_ADMIN`, or run with sufficient privileges |
| Wrong LAN / no NAT | Set `VPN_LAN_INTERFACE` to the interface that reaches your router |
| `dnsmasq` / port 53 busy | Stop conflicting resolvers or let Edge manage dnsmasq; check `ss -ulnp \| grep :53` |
| Relay disconnected | `PME_RELAY_ENABLED=true` in env or `/etc/default/edge`; trial or Mesh Pro on account |

More: website `/troubleshooting/#install`.
