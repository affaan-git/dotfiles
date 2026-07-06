#!/usr/bin/env bash
# Install the fzf-tab zsh plugin from its latest release into
# ~/.local/share/zsh/fzf-tab (zshrc sources fzf-tab.plugin.zsh from there).
set -euo pipefail
source "$(dirname "$0")/lib.sh"

preflight git curl jq

DEST="${DEST:-$HOME/.local/share/zsh/fzf-tab}"
clone_latest Aloxaf/fzf-tab "$DEST"
