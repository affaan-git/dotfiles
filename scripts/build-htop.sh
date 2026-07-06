#!/usr/bin/env bash
# Build htop from its latest release, verified, into $PREFIX/bin (single binary).
# Skips if already the latest version.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

REPO=htop-dev/htop
preflight cc make tar curl shasum jq

json=$(gh_latest "$REPO")
tag=$(tag_from "$json"); [ -n "$tag" ] || die "no htop release found"
ver=${tag#v}
skip_if_current htop "$ver"

read -r url sha < <(asset_from "$json" 'htop-.*\.tar\.xz$')
[ -n "$url" ] || die "no source tarball for htop $tag"
[ -n "$sha" ] || die "no published checksum for htop $tag"

build=$(mktemp -d); trap 'rm -rf "$build"' EXIT; cd "$build"
say "downloading + verifying htop $tag"
fetch "$url" htop.tar.xz "$sha"
tar xf htop.tar.xz
cd "htop-$ver"

say "building htop"
log=$(mktemp)
if ! { ./configure --prefix="$PREFIX" && make -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"; } >"$log" 2>&1; then
  echo "error: htop build failed:" >&2; tail -25 "$log" >&2; rm -f "$log"; exit 1
fi
rm -f "$log"

install_bin ./htop htop
"$PREFIX/bin/htop" --version | head -1
ok "htop $ver installed to $PREFIX/bin/htop"
