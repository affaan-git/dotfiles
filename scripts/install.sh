#!/usr/bin/env bash
# Run tool installation/updates. Every step self-detects and re-fetches only what
# is missing or outdated, so 'install' and 'update' behave the same.
set -uo pipefail   # deliberately not -e: per-step failures are handled below
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/lib.sh"

# label : script
STEPS=(
  "prebuilt binaries:install-binaries.sh"
  "builds:build.sh"
  "plugins:plugins.sh"
)

ok_list=(); fail_list=()
for step in "${STEPS[@]}"; do
  label="${step%%:*}"; script="${step#*:}"
  echo; echo "== $label =="
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
