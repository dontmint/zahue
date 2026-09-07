#!/bin/bash
# Download a portable Node.js binary for embedding in ZaloThemeSwitcher.app.
# Regular users should not need a system Node install.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CACHE_ROOT="${NODE_RUNTIME_CACHE:-$ROOT/macos/runtime}"
NODE_VERSION="${NODE_VERSION:-20.19.5}"

arch_for_uname() {
  case "$(uname -m)" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64) echo "x64" ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

download_arch() {
  local arch="$1"
  local dist="node-v${NODE_VERSION}-darwin-${arch}"
  local dest="$CACHE_ROOT/$dist"
  local tarball="$CACHE_ROOT/${dist}.tar.gz"
  local url="https://nodejs.org/dist/v${NODE_VERSION}/${dist}.tar.gz"
  local node_bin="$dest/bin/node"

  if [[ -x "$node_bin" ]]; then
    echo "Using cached Node $NODE_VERSION ($arch) at $node_bin" >&2
    echo "$node_bin"
    return 0
  fi

  mkdir -p "$CACHE_ROOT"
  echo "Downloading Node $NODE_VERSION for darwin-$arch..." >&2
  curl -fsSL "$url" -o "$tarball"
  rm -rf "$dest"
  tar -xzf "$tarball" -C "$CACHE_ROOT"
  rm -f "$tarball"

  if [[ ! -x "$node_bin" ]]; then
    echo "Failed to extract Node binary: $node_bin" >&2
    exit 1
  fi

  # Drop docs/npm to keep the app smaller; we only need the node executable.
  rm -rf "$dest/share" "$dest/lib" "$dest/include" \
    "$dest/bin/npm" "$dest/bin/npx" "$dest/bin/corepack" \
    "$dest/CHANGELOG.md" "$dest/README.md" "$dest/LICENSE" || true

  echo "$node_bin"
}

ARCH="${1:-$(arch_for_uname)}"
download_arch "$ARCH"
