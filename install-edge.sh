#!/usr/bin/env bash
# Download a Portico Edge release archive from GitHub and extract the edge binary.
# Customer / CI helper — no Windsor required.
# Public URL: https://web.porticoworks.dev/install.sh
#
# Usage:
#   ./install-edge.sh                     # latest → ./edge
#   ./install-edge.sh -t v0.1.0 -o /usr/local/bin
#   ./install-edge.sh --os linux --arch arm64 -o /tmp/edge-linux
#   EDGE_RELEASE_TAG=v0.1.0 ./install-edge.sh
#
# Env:
#   EDGE_RELEASE_TAG   Tag or "latest" (default: latest)
#   EDGE_INSTALL_DIR   Output directory (default: .)
#   EDGE_OS            Override GOOS (linux|darwin|windows)
#   EDGE_ARCH          Override GOARCH (amd64|arm64)
#   EDGE_REPO          owner/repo (default: tvangundy/portico-edge-dist)
#   GITHUB_TOKEN       Optional; raises GitHub API rate limits
set -euo pipefail

REPO="${EDGE_REPO:-tvangundy/portico-edge-dist}"
TAG="${EDGE_RELEASE_TAG:-latest}"
OUT_DIR="${EDGE_INSTALL_DIR:-.}"
OS="${EDGE_OS:-}"
ARCH="${EDGE_ARCH:-}"

usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--tag) TAG="${2:?}"; shift 2 ;;
    -o|--out) OUT_DIR="${2:?}"; shift 2 ;;
    --os) OS="${2:?}"; shift 2 ;;
    --arch) ARCH="${2:?}"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) echo "unknown arg: $1" >&2; usage 1 ;;
  esac
done

if [[ -z "${OS}" ]]; then
  uname_s="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "${uname_s}" in
    linux) OS=linux ;;
    darwin) OS=darwin ;;
    mingw*|msys*|cygwin*) OS=windows ;;
    *) echo "unsupported OS: ${uname_s}" >&2; exit 1 ;;
  esac
fi
OS="$(echo "${OS}" | tr '[:upper:]' '[:lower:]')"

if [[ -z "${ARCH}" ]]; then
  uname_m="$(uname -m)"
  case "${uname_m}" in
    x86_64|amd64) ARCH=amd64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) echo "unsupported arch: ${uname_m}" >&2; exit 1 ;;
  esac
fi
ARCH="$(echo "${ARCH}" | tr '[:upper:]' '[:lower:]')"
case "${ARCH}" in
  x86_64) ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
esac

if [[ "${OS}" == "windows" && "${ARCH}" == "arm64" ]]; then
  echo "windows/arm64 builds are not published" >&2
  exit 1
fi

AUTH_HEADER=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

api="https://api.github.com/repos/${REPO}/releases"
if [[ "${TAG}" == "latest" ]]; then
  api_url="${api}/latest"
else
  api_url="${api}/tags/${TAG}"
fi

echo "Resolving release ${TAG} from ${REPO} (${OS}/${ARCH})..."
json="$(curl -fsSL "${AUTH_HEADER[@]}" -H "Accept: application/vnd.github+json" "${api_url}")" || {
  echo "failed to fetch release metadata (no release yet, or GitHub rate limit — set GITHUB_TOKEN)" >&2
  exit 1
}

# With GITHUB_TOKEN, download via the API asset URL (higher rate limits).
USE_API_ASSET=0
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  USE_API_ASSET=1
fi

asset_url="$(
  EDGE_OS="${OS}" EDGE_ARCH="${ARCH}" EDGE_USE_API_ASSET="${USE_API_ASSET}" python3 -c '
import json, os, sys
os_name = os.environ["EDGE_OS"]
arch = os.environ["EDGE_ARCH"]
use_api = os.environ.get("EDGE_USE_API_ASSET") == "1"
data = json.load(sys.stdin)
needle = f"_{os_name}_{arch}.tar.gz"
assets = data.get("assets") or []
def pick(prefix):
    for a in assets:
        name = a.get("name") or ""
        if name.startswith(prefix) and name.endswith(needle):
            return a
    return None
chosen = pick("edge_") or pick("ws-edge_")
if chosen:
    if use_api:
        print(chosen["url"])
    else:
        print(chosen["browser_download_url"])
    sys.exit(0)
print("available assets:", [a.get("name") for a in assets], file=sys.stderr)
sys.exit(1)
' <<<"${json}"
)" || {
  echo "no archive asset for ${OS}/${ARCH} in release ${TAG}" >&2
  exit 1
}

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "${tmpdir}"; }
trap cleanup EXIT

archive="${tmpdir}/edge.tgz"
echo "Downloading ${asset_url}..."
if [[ "${USE_API_ASSET}" -eq 1 ]]; then
  curl -fsSL "${AUTH_HEADER[@]}" -H "Accept: application/octet-stream" -o "${archive}" -L "${asset_url}"
else
  curl -fsSL -o "${archive}" -L "${asset_url}"
fi

mkdir -p "${OUT_DIR}"
tar -xzf "${archive}" -C "${tmpdir}"
bin_path="$(find "${tmpdir}" -type f \( -name edge -o -name edge.exe \) ! -path '*/.*' | head -1)"
if [[ -z "${bin_path}" ]]; then
  echo "archive did not contain edge binary" >&2
  exit 1
fi

dest="${OUT_DIR}/edge"
if [[ "${bin_path}" == *.exe ]]; then
  dest="${OUT_DIR}/edge.exe"
fi
if [[ -d "${dest}" ]]; then
  echo "refusing to install over directory ${dest} (choose a different -o path)" >&2
  exit 1
fi
cp "${bin_path}" "${dest}"
chmod +x "${dest}"
echo "Installed ${dest}"
"${dest}" version 2>/dev/null || true
