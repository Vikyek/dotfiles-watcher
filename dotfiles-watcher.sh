#!/usr/bin/env bash
# dotfiles-watcher — watch bare-repo tracked files and auto-sync on change
# Installed to: /usr/local/bin/dotfiles-watcher
# Bare repo:    ~/.cfg/

set -euo pipefail

GIT_CFG="git --git-dir=${HOME}/.cfg/ --work-tree=${HOME}"

log() { echo "[dotfiles-watcher] $*"; }

while true; do
    FILES=$($GIT_CFG ls-files | awk -v h="$HOME" '{print h "/" $0}')

    if [ -z "$FILES" ]; then
        log "No tracked files found in ~/.cfg. Retrying in 30s..."
        sleep 30
        continue
    fi

    log "Watching $(echo "$FILES" | wc -l) files..."
    echo "$FILES" | entr -n -d dotfiles-sync

    log "File set changed or entr exited. Restarting in 5s..."
    sleep 5
done
