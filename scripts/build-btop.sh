#!/usr/bin/env bash
# Build btop from its latest release into $PREFIX/bin. Skips when current.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

REPO=aristocratos/btop
preflight git make c++ jq

tag=$(latest_tag "$REPO"); [ -n "$tag" ] || die "no btop release found"
ver=${tag#v}
skip_if_current btop "$ver"

build=$(mktemp -d); trap 'rm -rf "$build"' EXIT
say "cloning btop $tag"
git clone --depth 1 --branch "$tag" "https://github.com/$REPO" "$build/btop" >/dev/null 2>&1 \
  || die "clone failed: $REPO@$tag"

say "building btop (C++20)"
log=$(mktemp)
if ! make -C "$build/btop" -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)" >"$log" 2>&1; then
  echo "error: btop build failed:" >&2; tail -25 "$log" >&2; rm -f "$log"; exit 1
fi
rm -f "$log"

install_bin "$build/btop/bin/btop" btop
"$PREFIX/bin/btop" --version
ok "btop $ver installed to $PREFIX/bin/btop"
