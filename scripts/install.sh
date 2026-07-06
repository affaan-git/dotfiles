#!/usr/bin/env bash
# Run tool installation/updates.
# Usage: install.sh [install|update]   (default: install)
set -uo pipefail   # deliberately not -e: per-step failures are handled below
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/lib.sh"

mode="${1:-install}"

# label : script
STEPS=(
  "rust tools:install-cargo-tools.sh"
  "prebuilt binaries:install-binaries.sh"
  "nano:build-nano.sh"
  "zsh-completions:install-zsh-completions.sh"
  "fzf-tab:install-fzf-tab.sh"
)

ok_list=(); fail_list=()
for step in "${STEPS[@]}"; do
  label="${step%%:*}"; script="${step#*:}"
  echo; echo "== $label =="

  # in update mode the rust tools refresh via cargo-update
  if [ "$mode" = update ] && [ "$script" = install-cargo-tools.sh ]; then
    if command -v cargo-install-update >/dev/null 2>&1; then
      if cargo install-update -a; then ok_list+=("$label"); else fail_list+=("$label"); fi
    else
      echo "note: run 'cargo install cargo-update' to auto-update the rust tools"
      ok_list+=("$label (skipped)")
    fi
    continue
  fi

  if bash "$here/$script"; then ok_list+=("$label"); else fail_list+=("$label"); fi
done

echo; echo "Ghostty is a GUI app - install it from https://ghostty.org (see README)."
echo; echo "== summary =="
echo "  ok:     ${ok_list[*]:-none}"
if [ ${#fail_list[@]} -eq 0 ]; then
  echo "  failed: none"
else
  echo "  failed: ${fail_list[*]}  (re-run to retry; up-to-date tools are skipped)"
  exit 1
fi
