#!/usr/bin/env bash

# --- The Package Variables ---
REPO="jcnnll/vlab"
VERSION="v0.0.1"

# Exit on error, pipefail ensures errors in curl | tar are caught
set -eo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  log "Installing VM tools via pacman..."

  # qemu provides the hardware emulation for Lima on Linux
  sudo pacman -S --needed --noconfirm lima qemu-desktop || error "Failed to install pacman packages."

  # Ensure the user is in the libvirt/kvm groups if necessary
  # (Lima usually handles its own unprivileged execution on Linux)
}

install_brew() {
  log "Installing VM tools via Homebrew..."
  # Lima is the core engine
  brew install lima || error "Failed to install lima."

  # socket_vmnet provides the bridge networking for mDNS (.local names)
  brew install socket_vmnet || error "Failed to install socket_vmnet."

  log "Setting up network bridge permissions (requires sudo)..."
  # socket_vmnet needs specific setuid bits to create bridges without sudo later
  sudo brew services start socket_vmnet
}

install_cli() {

  OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH_NAME=$(uname -m)

  # Standardize architecture names for Go/GitHub assets
  [[ "$ARCH_NAME" == "x86_64" ]] && ARCH_NAME="amd64"
  [[ "$ARCH_NAME" == "arm64" || "$ARCH_NAME" == "aarch64" ]] && ARCH_NAME="arm64"

  # The exact filename your GitHub Action must produce
  BINARY_NAME="vlab_${VERSION}_${OS_NAME}_${ARCH_NAME}.tar.gz"

  # THE FINAL CORRECTED URL
  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}"

  log "Downloading VLab CLI from: $DOWNLOAD_URL"

  # -fsSL: Fail on 404, Silent but show errors, follow Redirects
  if ! curl -fsSL "$DOWNLOAD_URL" -o "/tmp/$BINARY_NAME"; then
    error "Failed to download from https://github.com{REPO}/releases"
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
#install_cli

echo -e "\u2713 VLab installation complete! Run 'vlab status' to begin."
