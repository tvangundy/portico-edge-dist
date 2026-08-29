#!/usr/bin/env bash
# Launch or reuse a privileged Ubuntu 24.04 Incus container and run `edge install`
# inside it. Customer / homelab helper — no Windsor or go build required.
#
# Usage:
#   ./scripts/install-edge-incus.sh
#   ./scripts/install-edge-incus.sh --name portico-edge --image images:ubuntu/24.04
#   ./scripts/install-edge-incus.sh --remote rpi-0 --name garage-edge
#
# Env:
#   EDGE_INCUS_NAME    Container name (default: portico-edge)
#   EDGE_INCUS_IMAGE   Image (default: ubuntu/24.04, then images:ubuntu/24.04)
#   EDGE_INCUS_REMOTE  Incus remote (default: local / unnamed)
#   EDGE_RELEASE_TAG   Passed to install-edge.sh
set -euo pipefail

NAME="${EDGE_INCUS_NAME:-portico-edge}"
IMAGE="${EDGE_INCUS_IMAGE:-}"
REMOTE="${EDGE_INCUS_REMOTE:-}"
TAG="${EDGE_RELEASE_TAG:-latest}"
CPU="${EDGE_INCUS_CPU:-2}"
MEMORY="${EDGE_INCUS_MEMORY:-2GiB}"

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="${2:?}"; shift 2 ;;
    --image) IMAGE="${2:?}"; shift 2 ;;
    --remote) REMOTE="${2:?}"; shift 2 ;;
    -t|--tag) TAG="${2:?}"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) echo "unknown arg: $1" >&2; usage 1 ;;
  esac
done

if ! command -v incus >/dev/null 2>&1; then
  echo "Error: incus CLI not found on PATH" >&2
  exit 1
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
DOWNLOADER="${HERE}/install-edge.sh"
if [[ ! -x "${DOWNLOADER}" && ! -f "${DOWNLOADER}" ]]; then
  tmp_dl="$(mktemp)"
  curl -fsSL -o "${tmp_dl}" \
    https://web.porticoworks.dev/install.sh ||
    curl -fsSL -o "${tmp_dl}" \
      https://raw.githubusercontent.com/tvangundy/portico-edge-dist/main/install-edge.sh
  chmod +x "${tmp_dl}"
  DOWNLOADER="${tmp_dl}"
fi

uname_m="$(uname -m)"
case "${uname_m}" in
  x86_64|amd64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) echo "unsupported host arch: ${uname_m}" >&2; exit 1 ;;
esac

target="${NAME}"
if [[ -n "${REMOTE}" ]]; then
  target="${REMOTE}:${NAME}"
fi

image_exists() {
  incus image info "$1" >/dev/null 2>&1
}

if [[ -z "${IMAGE}" ]]; then
  if image_exists "ubuntu/24.04"; then
    IMAGE="ubuntu/24.04"
  elif image_exists "images:ubuntu/24.04"; then
    IMAGE="images:ubuntu/24.04"
  else
    IMAGE="images:ubuntu/24.04"
  fi
fi

instance_exists() {
  incus info "${target}" >/dev/null 2>&1
}

if instance_exists; then
  echo "Reusing Incus instance ${target}"
  status="$(incus info "${target}" 2>/dev/null | awk -F': ' '/^Status:/ {print $2; exit}' || true)"
  if [[ "${status}" != "RUNNING" && "${status}" != "Running" ]]; then
    incus start "${target}"
  fi
else
  echo "Launching privileged Ubuntu container ${target} (${IMAGE})…"
  launch_args=(
    launch "${IMAGE}" "${target}"
    -c security.privileged=true
    -c security.nesting=false
    -c limits.cpu="${CPU}"
    -c limits.memory="${MEMORY}"
  )
  incus "${launch_args[@]}"
fi

echo "Waiting for container network…"
container_ip=""
for _ in $(seq 1 40); do
  container_ip="$(incus list "${target}" -c 4 --format csv 2>/dev/null \
    | tr ',' '\n' | sed -n 's/^\([0-9.]*\) (eth0)$/\1/p' | head -1 || true)"
  if [[ -z "${container_ip}" ]]; then
    container_ip="$(incus list "${target}" -c 4 --format csv 2>/dev/null \
      | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '^127\.' | head -1 || true)"
  fi
  if [[ -n "${container_ip}" ]]; then
    break
  fi
  sleep 1
done
if [[ -z "${container_ip}" ]]; then
  echo "WARN: could not resolve container IPv4 yet" >&2
fi

outdir="$(mktemp -d)"
cleanup() { rm -rf "${outdir}"; }
trap cleanup EXIT

echo "Downloading linux/${ARCH} release (${TAG})…"
bash "${DOWNLOADER}" -t "${TAG}" --os linux --arch "${ARCH}" -o "${outdir}"

echo "Pushing binary → ${target}:/usr/local/bin/edge"
incus exec "${target}" -- systemctl stop edge >/dev/null 2>&1 || true
incus file push --mode 0755 "${outdir}/edge" "${target}/usr/local/bin/edge"

echo "Running in-guest edge install…"
incus exec "${target}" -- edge install

echo ""
echo "edge installed in ${target}"
echo "  status:  incus exec ${target} -- systemctl status edge --no-pager"
echo "  logs:    incus exec ${target} -- journalctl -u edge -f"
if [[ -n "${container_ip}" ]]; then
  echo "  agent:   http://${container_ip}:9191"
else
  echo "  agent:   http://<container-ip>:9191  (try: incus list ${REMOTE:-local}:)"
fi
echo "  doctor:  incus exec ${target} -- edge doctor"
