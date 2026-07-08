#!/usr/bin/env bash
# Install/refresh the git-clone zsh plugins (the CLONES manifest in lib.sh).
# No args does all; a name does just that one (used by the make targets).
set -uo pipefail
source "$(dirname "$0")/lib.sh"

preflight git curl jq

want="${1:-}"; found=0; fail_list=()
for e in "${CLONES[@]}"; do
  IFS='|' read -r name repo dest <<<"$e"
  [ -n "$want" ] && [ "$want" != "$name" ] && continue
  found=1
  echo; echo "== $name =="
  ( clone_latest "$repo" "$dest" ) || fail_list+=("$name")
done
[ -n "$want" ] && [ "$found" = 0 ] && die "unknown plugin: $want"
[ ${#fail_list[@]} -eq 0 ] || die "failed: ${fail_list[*]}"
ok "plugins current"
