#!/usr/bin/env bash

set -euo pipefail

# --- Configuration ---
REPO="jcnnll/vlab"
VMNET_REPO="lima-vm/socket_vmnet"
INSTALL_DIR="/opt/homebrew/bin"
VMNET_ROOT="/opt/socket_vmnet"
TMP_DIR=$(mktemp -d "/tmp/vlab_install")

# Ensure cleanup on exit
trap 'rm -rf "$TMP_DIR"' EXIT
umask 022

# --- Logging ---
log() { echo -e "\033[1;34m[vlab]\033[0m $1"; }
error() {
  echo -e "\033[1;31m[error]\033[0m $1" >&2
  exit 1
}

# --- Platform Check ---
detect_platform() {
  [[ "$(uname -s)" != "Darwin" ]] && error "Only macOS is supported."
  [[ "$(uname -m)" != "arm64" ]] && error "Apple Silicon required."
  OS_NAME="darwin"
  ARCH_NAME="arm64"
}

# --- Version Fetcher (Your Pattern) ---
get_latest_tag() {
  local target_repo=$1
  # Points to the official REST API endpoint
  local tag=$(curl -fsSL "https://api.github.com/repos/${target_repo}/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/')

  [[ -z "$tag" ]] && error "Failed to fetch latest version for ${target_repo}."
  echo "$tag"
}

# --- Logic ---
install_dependencies() {
  log "Checking host environment..."

  # 1. Xcode Command Line Tools
  if ! xcode-select -p >/dev/null 2>&1; then
    log "Installing Xcode Command Line Tools..."
    # This opens the macOS GUI installer
    xcode-select --install
    log "Please complete the GUI installation and then re-run this script."
    exit 0
  fi

  # 2. Rosetta 2
  if ! pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
    log "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license || log "Warning: Rosetta install skipped."
  fi

  # 3. Lima via Brew
  if ! command -v brew >/dev/null 2>&1; then
    log "ERROR: Homebrew is not installed. Please install Homebrew first."
    exit 1
  fi
  if ! command -v limactl >/dev/null 2>&1; then
    log "Installing Lima via Homebrew..."
    brew install lima
  fi

  # 4. Secure socket_vmnet
  local TAG=$(get_latest_tag "$VMNET_REPO")
  local VER="${TAG#v}"
  local BIN="$VMNET_ROOT/bin/socket_vmnet"

  if [[ -f "$BIN" ]] && [[ "$("$BIN" --version | awk '{print $NF}')" == "$VER" ]]; then
    log "socket_vmnet $VER already current."
  else
    log "Installing socket_vmnet $VER to $VMNET_ROOT..."
    local FILE="socket_vmnet-${VER}-${ARCH_NAME}.tar.gz"
    local URL="https://github.com/${VMNET_REPO}/releases/download/${TAG}/${FILE}"

    curl -fsSL -o "$TMP_DIR/$FILE" "$URL"
    brew uninstall socket_vmnet --force 2>/dev/null || true

    sudo rm -rf "$VMNET_ROOT"
    sudo tar -C / -xzf "$TMP_DIR/$FILE" opt/socket_vmnet
    sudo chown -R root:wheel "$VMNET_ROOT"

  fi
  # ALWAYS run this to ensure the Root Access bridge exists
  log "Force-syncing sudoers for /opt/socket_vmnet..."
  LIMA_SUDOERS_NET="$BIN" limactl sudoers >"$TMP_DIR/lima-sudoers"
  sudo install -o root -g wheel -m 440 "$TMP_DIR/lima-sudoers" /etc/sudoers.d/lima
}

install_vlab() {
  local VERSION=$(get_latest_tag "$REPO")
  log "Installing VLab $VERSION..."

  local BINARY_NAME="vlab_${VERSION}_${OS_NAME}_${ARCH_NAME}.tar.gz"
  local CHECKSUM_NAME="vlab_${VERSION#v}_checksums.txt"

  curl -fsSL -o "$TMP_DIR/$BINARY_NAME" "https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}"
  curl -fsSL -o "$TMP_DIR/$CHECKSUM_NAME" "https://github.com/${REPO}/releases/download/${VERSION}/${CHECKSUM_NAME}"

  (cd "$TMP_DIR" && grep "$BINARY_NAME" "$CHECKSUM_NAME" | shasum -a 256 -c -) || error "Checksum failed."

  log "Deploying vlab to $INSTALL_DIR..."
  sudo tar -xzf "$TMP_DIR/$BINARY_NAME" -C "$INSTALL_DIR" vlab
  sudo chmod +x "$INSTALL_DIR/vlab"
}

# --- Main ---
detect_platform
install_dependencies
install_vlab

echo -e "✔ Installation complete! Run 'vlab status' to begin."
