#!/usr/bin/env bash
# Install/refresh the prebuilt CLI tools (the BINARIES manifest in lib.sh), each
# from its latest GitHub release and verified against the release's published
# sha256. Detection is sequential; downloads run in parallel.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

preflight curl shasum tar unzip jq

# equential + detection
NEEDS=()
for row in "${BINARIES[@]}"; do
  IFS='|' read -r name repo re <<<"$row"
  json=$(gh_latest "$repo")
  tag=$(tag_from "$json"); [ -n "$tag" ] || die "no release for $repo"
  ver=${tag#v}
  if [ "$(installed_ver "$PREFIX/bin/$name")" = "$ver" ]; then
    ok "$name $ver already current"; continue
  fi
  read -r url sha < <(asset_from "$json" "$re")
  [ -n "$url" ] || die "no macOS arm64 asset for $name ($repo $tag)"
  [ -n "$sha" ] || die "no published checksum for $name asset - refusing unverified install"
  NEEDS+=("$name|$ver|$url|$sha")
done
[ ${#NEEDS[@]} -eq 0 ] && { ok "all prebuilt binaries current"; exit 0; }

# parallel download + verify + extract into a staging dir
stage=$(mktemp -d); trap 'rm -rf "$stage"' EXIT
stage_one() {  # produces $stage/<name>.bin on success
  local name=$1 url=$2 sha=$3
  local d="$stage/$name.d"
  mkdir -p "$d"
  fetch "$url" "$d/a.arc" "$sha"
  local bin
  case "$url" in
    *.zip)          unzip -qo "$d/a.arc" -d "$d"; bin=$(find "$d" -type f -name "$name" -perm +111 | head -1) ;;
    *.tar.gz|*.tgz) tar xzf "$d/a.arc" -C "$d";   bin=$(find "$d" -type f -name "$name" -perm +111 | head -1) ;;
    *)              bin="$d/a.arc" ;;   # bare binary (e.g. tealdeer)
  esac
  [ -n "$bin" ] && [ -f "$bin" ] || { echo "error: '$name' binary not found" >&2; return 1; }
  cp "$bin" "$stage/$name.bin"
}
say "downloading ${#NEEDS[@]} binary(s) in parallel"
for job in "${NEEDS[@]}"; do
  IFS='|' read -r name ver url sha <<<"$job"
  stage_one "$name" "$url" "$sha" &
done
wait

# sequential install + report
fails=()
for job in "${NEEDS[@]}"; do
  IFS='|' read -r name ver url sha <<<"$job"
  if [ -f "$stage/$name.bin" ]; then install_bin "$stage/$name.bin" "$name"
  else fails+=("$name"); fi
done
[ ${#fails[@]} -eq 0 ] || die "failed: ${fails[*]}"
ok "prebuilt binaries current"
