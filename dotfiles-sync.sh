#!/usr/bin/env bash
# dotfiles-sync — stage, AI-commit, and push dotfiles bare repo changes
# Installed to: /usr/local/bin/dotfiles-sync
# Bare repo:    ~/.cfg/

set -euo pipefail

GIT_CFG="git --git-dir=${HOME}/.cfg/ --work-tree=${HOME}"

log() { echo "[dotfiles-sync] $*"; }

# 1. Stage new systemd user units
log "Scanning for new systemd units..."
while IFS= read -r unit; do
    $GIT_CFG add "$unit"
done < <(find ~/.config/systemd/user/ -maxdepth 1 \( -name "*.service" -o -name "*.timer" \) 2>/dev/null)

# 2. Stage changes to already-tracked files
$GIT_CFG ls-files | while IFS= read -r f; do
    $GIT_CFG add "${HOME}/${f}" 2>/dev/null || true
done

# 3. Check for staged changes
DIFF_STAT=$($GIT_CFG diff --cached --stat)
if [ -z "$DIFF_STAT" ]; then
    log "Nothing to commit."
    exit 0
fi

# 4. Generate commit message via Gemini, fallback to timestamp
PROMPT="Generate a concise, professional one-line git commit message for these dotfiles changes. Only return the message text, no quotes or prefix. Changes: ${DIFF_STAT}"
COMMIT_MSG=$(gemini -p "$PROMPT" 2>/dev/null || true)

if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="auto-sync dotfiles: $(date +'%Y-%m-%d %H:%M:%S')"
fi

log "Committing: ${COMMIT_MSG}"
$GIT_CFG commit -m "$COMMIT_MSG"
$GIT_CFG push origin main
log "Pushed."
