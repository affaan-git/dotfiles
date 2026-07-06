#!/usr/bin/env bash
# Install zsh-completions (extra completion definitions) from its latest release
# into ~/.local/share/zsh/zsh-completions. zshrc adds its src/ dir to fpath.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

preflight git curl jq

DEST="${DEST:-$HOME/.local/share/zsh/zsh-completions}"
clone_latest zsh-users/zsh-completions "$DEST"
