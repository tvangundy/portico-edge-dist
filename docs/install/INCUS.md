# Install PME Edge in an Incus container

Customer / homelab guide. No Windsor, Task, or `go build`. You need the **Incus CLI** on the host (the machine that already runs Incus).

This is the always-on Linux path the in-guest `edge install` engine was proven on. Typical household hosts still use [UBUNTU.md](./UBUNTU.md) or [MACOS.md](./MACOS.md).

## 1. Prerequisites

- Incus on the host (`incus version`)
- A default profile with a NIC (usually `eth0`)
- Network access from the container to GitHub (release download happens on the host) and to `https://pme.pmenetwork.com`

The helper launches a **privileged** Ubuntu 24.04 container (`security.privileged=true`) so WireGuard and `CAP_NET_ADMIN` work.

## 2. One-shot helper

Copy `install-edge.sh` and `install-edge-incus.sh` into the same directory (this repo’s root, `scripts/` in a [release archive](https://github.com/tvangundy/portico-edge-dist/releases/latest), or `https://web.porticoworks.dev/install.sh` plus the Incus helper from the dist repo).

```bash
chmod +x install-edge.sh install-edge-incus.sh
./install-edge-incus.sh --name portico-edge
```

Flags:

```text
--name NAME          Container name (default: portico-edge)
--image IMAGE        e.g. ubuntu/24.04 or images:ubuntu/24.04
--remote REMOTE      Incus remote (omit for local)
-t / --tag TAG       Release tag (default: latest)
```

The helper:

1. Launches or reuses a privileged Ubuntu 24.04 container
2. Downloads a `linux/{amd64|arm64}` release binary (host arch)
3. Pushes it to `/usr/local/bin/edge`
4. Runs `edge install` inside the guest (packages, `/etc/default/edge`, systemd)

Open the printed **Agent UI** URL (`http://<container-ip>:9191`), set **PME Server URL** to `https://pme.pmenetwork.com`, sign in, and register.

```bash
incus exec portico-edge -- edge doctor
```

## 3. Manual (same engine)

If you already have a privileged Ubuntu container:

```bash
./install-edge.sh --os linux --arch arm64 -o /tmp/edge-linux   # or amd64
incus file push --mode 0755 /tmp/edge-linux/edge CONTAINER:/usr/local/bin/edge
incus exec CONTAINER -- edge install
```

`edge install` is idempotent. It will not overwrite existing keys in `/etc/default/edge` (operator SOPS files stay intact).

## Uninstall

Inside the container:

```bash
incus exec portico-edge -- edge uninstall          # stop/disable unit; keep data
incus exec portico-edge -- edge uninstall --purge  # also remove env, binary, data dir
```

Destroy the container with Incus (`incus delete --force portico-edge`). Operator factory Homes still use `task edge:down` in ws-edge.

## Operator note

Factory `task edge:up` / `task edge:deploy` still build from source and write Windsor env, then call the same in-guest `edge install`. Do not send public download traffic to `task edge:new`.
