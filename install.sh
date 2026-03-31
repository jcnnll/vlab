#!/usr/bin/env bash

# --- The Package Variables ---
REPO="jcnnll/vlab"
VERSION="v0.0.1"

# Exit on error, pipefail ensures errors in curl | tar are caught
set -eo pipefail

# Helper for consistent logging
log() { echo -e "\033[1;34m[vlab]\033[0m $1"; }
error() {
  echo -e "\033[1;31m[error]\033[0m $1" >&2
  exit 1
}

detect_os() {
  case "$(uname -s)" in
  Darwin) echo "macos" ;;
  Linux)
    if [ -f /etc/arch-release ]; then echo "arch"; else echo "unsupported"; fi
    ;;
  *) echo "unsupported" ;;
  esac
}

check_dependencies() {
  log "Checking host environment..."
  if [[ "$1" == "macos" ]]; then
    command -v brew >/dev/null 2>&1 || error "Homebrew is required for macOS installation."
  fi
}

install_pacman() {
  log "Ensuring VM tools via pacman..."
  sudo pacman -S --needed --noconfirm lima qemu-desktop
}

install_brew() {
  log "Ensuring VM tools via Homebrew..."
  # 'brew install' is natively idempotent; it skips if already installed
  brew install lima
  brew install socket_vmnet

  # Idempotent service check
  if ! brew services list | grep -q "socket_vmnet.*started"; then
    log "Starting network bridge permissions (requires sudo)..."
    sudo brew services start socket_vmnet
  else
    log "Network bridge service is already running."
  fi
}

install_cli() {
  OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH_NAME=$(uname -m)

  [[ "$ARCH_NAME" == "x86_64" ]] && ARCH_NAME="amd64"
  [[ "$ARCH_NAME" == "arm64" || "$ARCH_NAME" == "aarch64" ]] && ARCH_NAME="arm64"

  BINARY_NAME="vlab_${VERSION}_${OS_NAME}_${ARCH_NAME}.tar.gz"
  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}"

  # Idempotency check: Don't download/reinstall if version matches
  if command -v vlab >/dev/null 2>&1; then
    # We'll implement 'vlab version' in the CLI later, for now we can skip or force
    log "vlab binary already exists. Re-installing to ensure $VERSION..."
  fi

  log "Downloading VLab CLI from: $DOWNLOAD_URL"

  if ! curl -fsSL "$DOWNLOAD_URL" -o "/tmp/$BINARY_NAME"; then
    error "Failed to download $BINARY_NAME from GitHub."
  fi

  log "Installing vlab binary to /usr/local/bin..."
  sudo tar -xzf "/tmp/$BINARY_NAME" -C /usr/local/bin vlab
  sudo chmod +x /usr/local/bin/vlab

  rm "/tmp/$BINARY_NAME"
}

# --- Main Execution ---

log "Starting VLab installation..."
OS=$(detect_os)

if [[ "$OS" == "unsupported" ]]; then
  error "This OS is not supported. VLab currently supports macOS and Arch Linux."
fi

check_dependencies "$OS"

case "$OS" in
macos) install_brew ;;
arch) install_pacman ;;
esac

log "Installing VLab CLI..."
install_cli

echo -e "\u2713 VLab installation complete! Run 'vlab status' to begin."
