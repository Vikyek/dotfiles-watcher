#!/usr/bin/env bash
# install.sh — install dotfiles-watcher and dotfiles-sync
# Usage: ./install.sh [--uninstall]
#
# Installs binaries to /usr/local/bin and the systemd user unit,
# then enables and starts the watcher service.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="/usr/local/bin"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
SERVICE_NAME="dotfiles-watcher.service"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()  { echo -e "${GREEN}[install]${NC} $*"; }
warn()  { echo -e "${YELLOW}[install]${NC} $*"; }
error() { echo -e "${RED}[install]${NC} $*" >&2; exit 1; }

check_deps() {
    local missing=()
    for cmd in entr gemini git; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing dependencies: ${missing[*]}"
    fi
}

uninstall() {
    info "Stopping and disabling service..."
    systemctl --user disable --now "$SERVICE_NAME" 2>/dev/null || true

    info "Removing binaries..."
    sudo rm -f "${BIN_DIR}/dotfiles-watcher" "${BIN_DIR}/dotfiles-sync"

    info "Removing service file..."
    rm -f "${SYSTEMD_USER_DIR}/${SERVICE_NAME}"
    systemctl --user daemon-reload

    info "Uninstall complete."
    exit 0
}

install() {
    check_deps

    info "Installing binaries to ${BIN_DIR}..."
    sudo install -m 755 "${SCRIPT_DIR}/dotfiles-watcher.sh" "${BIN_DIR}/dotfiles-watcher"
    sudo install -m 755 "${SCRIPT_DIR}/dotfiles-sync.sh"    "${BIN_DIR}/dotfiles-sync"

    info "Installing systemd user service..."
    mkdir -p "$SYSTEMD_USER_DIR"
    install -m 644 "${SCRIPT_DIR}/dotfiles-watcher.service" "${SYSTEMD_USER_DIR}/${SERVICE_NAME}"

    systemctl --user daemon-reload

    info "Enabling and starting service..."
    systemctl --user enable --now "$SERVICE_NAME"

    info ""
    info "✓ dotfiles-watcher installed and running."
    info "  Status:  systemctl --user status dotfiles-watcher"
    info "  Logs:    journalctl --user -u dotfiles-watcher -f"
    info "  Sync:    dotfiles-sync"
}

case "${1:-}" in
    --uninstall|-u) uninstall ;;
    *)              install   ;;
esac
