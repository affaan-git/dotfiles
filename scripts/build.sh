#!/usr/bin/env bash
# Build the tools with no prebuilt macOS binary, from the manifests in lib.sh:
#   BUILDS - fetch (verified) or clone source, run a build command, install the binary
#   CARGO  - install a crate from source with cargo
# nano is the one build with no data form (two packages, two mirrors)
#
# No args builds everything; a name builds just that one.
set -uo pipefail
SDIR="$(cd "$(dirname "$0")" && pwd)"
source "$SDIR/lib.sh"

JOBS=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)

# build one BUILDS entry. Run in a subshell: fetch/clone failures call die (exit).
build_release() {  # <name> <repo> <source> <build-cmd> <binary-path>
  set -e
  local name=$1 repo=$2 source=$3 build=$4 relpath=$5 tag ver json=""
  if [ "$source" = clone ]; then tag=$(latest_tag "$repo")
  else json=$(gh_latest "$repo"); tag=$(tag_from "$json"); fi
  [ -n "$tag" ] || die "no release for $repo"
  ver=${tag#v}
  if [ "$(installed_ver "$PREFIX/bin/$name")" = "$ver" ]; then ok "$name $ver already current"; return 0; fi

  local w src; w=$(mktemp -d); trap "rm -rf '$w'" EXIT; src="$w/src"; mkdir -p "$src"
  if [ "$source" = clone ]; then
    say "cloning $name $tag"
    git clone --depth 1 --branch "$tag" "https://github.com/$repo" "$src" >/dev/null 2>&1 \
      || die "clone failed: $repo@$tag"
  else
    local url sha; read -r url sha < <(asset_from "$json" "$source")
    { [ -n "$url" ] && [ -n "$sha" ]; } || die "no verified source for $name $tag"
    say "downloading + verifying $name $tag"
    fetch "$url" "$w/a.arc" "$sha"
    tar xf "$w/a.arc" -C "$src" --strip-components=1
  fi

  say "building $name"
  local log; log=$(mktemp)
  if ! ( cd "$src" && eval "$build" ) >"$log" 2>&1; then
    echo "error: $name build failed:" >&2; tail -25 "$log" >&2; exit 1
  fi
  rm -f "$log"
  install_bin "$src/$relpath" "$name"
  "$PREFIX/bin/$name" --version 2>/dev/null | head -1
  ok "$name $ver installed to $PREFIX/bin/$name"
}

# install one CARGO crate from source. Run in a subshell (need calls die).
build_cargo() {  # <crate>
  need cargo "install Rust: https://rustup.rs"
  say "building $1 from source (cargo install)"
  cargo install "$1"
  ok "$1 in ~/.cargo/bin (re-run to update)"
}

# run one named tool through the right builder; returns its status
build_one() {  # <name>
  local want=$1 n repo source build relpath e
  for e in "${BUILDS[@]}"; do
    IFS='|' read -r n repo source build relpath <<<"$e"
    [ "$n" = "$want" ] && { ( build_release "$n" "$repo" "$source" "$build" "$relpath" ); return $?; }
  done
  for e in "${CARGO[@]}"; do
    [ "$e" = "$want" ] && { ( build_cargo "$e" ); return $?; }
  done
  [ "$want" = nano ] && { bash "$SDIR/build-nano.sh"; return $?; }
  die "unknown build target: $want"
}

preflight cc make git tar curl shasum jq

want="${1:-}"
if [ -n "$want" ]; then build_one "$want"; exit $?; fi

# no arg: build them all, collecting failures
ok_list=(); fail_list=()
for name in $(for e in "${BUILDS[@]}"; do IFS='|' read -r n _ <<<"$e"; echo "$n"; done) "${CARGO[@]}" nano; do
  echo; echo "== $name =="
  if build_one "$name"; then ok_list+=("$name"); else fail_list+=("$name"); fi
done
echo; echo "  ok:     ${ok_list[*]:-none}"
[ ${#fail_list[@]} -eq 0 ] || { echo "  failed: ${fail_list[*]}"; exit 1; }
