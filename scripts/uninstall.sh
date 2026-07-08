#!/usr/bin/env bash
# Remove everything 'make tools' installed - binaries in $PREFIX/bin, the cargo
# crates, and the git-clone plugins. Reads the same manifests as the installers
# (lib.sh). Config symlinks are handled by 'make unlink'
# (run 'make uninstall' to do both). The Rust toolchain is left intact.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

say "removing installed tools"

# binaries in $PREFIX/bin: the BINARIES + BUILDS names, plus nano
names=()
for e in "${BINARIES[@]}"; do IFS='|' read -r n _ <<<"$e"; names+=("$n"); done
for e in "${BUILDS[@]}";   do IFS='|' read -r n _ <<<"$e"; names+=("$n"); done
names+=(nano)
for n in "${names[@]}"; do
  [ -e "$PREFIX/bin/$n" ] && { rm -f "$PREFIX/bin/$n"; echo "  removed $PREFIX/bin/$n"; }
done

# cargo-built crates
if command -v cargo >/dev/null 2>&1; then
  for c in "${CARGO[@]}"; do
    cargo uninstall "$c" >/dev/null 2>&1 && echo "  cargo-uninstalled $c" || true
  done
fi

# git-clone plugins
for e in "${CLONES[@]}"; do
  IFS='|' read -r n repo dest <<<"$e"
  [ -e "$dest" ] && { rm -rf "$dest"; echo "  removed $dest"; }
done

# nano's installed data (its ~/.cache/nano backups are your edits - left alone)
[ -e "$PREFIX/share/nano" ] && { rm -rf "$PREFIX/share/nano"; echo "  removed $PREFIX/share/nano"; }

ok "tools removed (Rust toolchain left intact)"
