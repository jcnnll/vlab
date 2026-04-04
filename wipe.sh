#!/usr/bin/env bash

set -euo pipefail

# --- Logging ---
log() { echo -e "\033[1;34m[vlab]\033[0m $1"; }
error() {
  echo -e "\033[1;31m[error]\033[0m $1" >&2
  exit 1
}

# --- Logic ---
uninstall() {
  # 1. Stop and delete all Lima instances
  log "Stopping and deleting all Lima instances..."
  if command -v limactl &>/dev/null; then
    # Only attempt to stop/delete if there are actually instances listed
    INSTANCES=$(limactl ls -q)
    if [ -n "$INSTANCES" ]; then
      limactl stop -f $INSTANCES 2>/dev/null || true
      limactl delete $INSTANCES 2>/dev/null || true
    fi
    # Clean up hidden Lima data directories
    rm -rf ~/.lima ~/Library/Caches/lima
  fi

  # 2. Stop and remove socket_vmnet service (installed in /opt/socket_vmnet)
  echo "Removing socket_vmnet service and binaries..."
  SERVICE_ID=io.github.lima-vm.socket_vmnet
  if [ -f "/Library/LaunchDaemons/$SERVICE_ID.plist" ]; then
    sudo launchctl bootout system "/Library/LaunchDaemons/$SERVICE_ID.plist" 2>/dev/null || true
    sudo rm -f "/Library/LaunchDaemons/$SERVICE_ID.plist"
  fi
  # Remove the installation directory and sudoers config
  sudo rm -rf /opt/socket_vmnet
  sudo rm -f /etc/sudoers.d/lima
  sudo rm -rf /usr/local/bin/vlab

  # 3. Uninstall Lima via Homebrew
  echo "Uninstalling Lima via Homebrew..."
  if brew list lima &>/dev/null; then
    brew uninstall -f lima
    brew autoremove
  fi
}

# --- Main ---
uninstall

echo -e "✔ Wipe complete!"
