#!/usr/bin/env bash
# Shared helpers for the install/update scripts. Source this file; do not run it
# directly. Every install is "latest + verify at fetch" - there are no pinned
# versions here; each fetch is authenticated against a checksum the upstream
# publishes for that release.
#
# Requires: curl, shasum, git, jq (jq is included with recent macOS at /usr/bin/jq).

PREFIX="${PREFIX:-$HOME/.local}"   # binaries land in $PREFIX/bin

say() { echo ">> $*"; }
ok()  { echo "OK: $*"; }
die() { echo "error: $*" >&2; exit 1; }

# need <cmd> [hint] - require a command on PATH
need() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' not found${2:+ - $2}"
}

# preflight <cmd...> - require each command; a miss points at the two sources that
# provide them all: the Xcode Command Line Tools, and the jq that's included with macOS.
preflight() {
  local c
  for c in "$@"; do
    need "$c" "install the Xcode Command Line Tools (xcode-select --install); jq is included with recent macOS"
  done
}

# installed_ver <cmd...> - first x.y[.z] version from the tool's --version output,
# or empty if the tool is not installed. Used to skip work when already current.
installed_ver() { "$@" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1; }

# skip_if_current <name> <version> - exit 0 (skip the build) if $PREFIX/bin/<name>
# already reports <version>.
skip_if_current() {
  if [ "$(installed_ver "$PREFIX/bin/$1")" = "$2" ]; then ok "$1 $2 already current"; exit 0; fi
}

# fetch <url> <outfile> [sha256] - download and verify when a sha is given
fetch() {
  curl -fsSL --proto '=https' --tlsv1.2 -o "$2" "$1" || die "download failed: $1"
  if [ -n "${3:-}" ]; then
    echo "$3  $2" | shasum -a 256 -c - >/dev/null 2>&1 || die "checksum mismatch for $2"
  fi
}

# _api <url> - GET
_api() { curl -fsSL --proto '=https' --tlsv1.2 "$1"; sleep 1; }

# gh_latest <owner/repo> - the latest-release JSON (one API call). Callers pull the
# tag and any asset out of this single response with tag_from / asset_from.
gh_latest() { _api "https://api.github.com/repos/$1/releases/latest"; }

# tag_from <json> - the release tag
tag_from() { jq -r '.tag_name // empty' <<<"$1"; }

# asset_from <json> <name-regex> - "<url>\t<sha256>" for the first matching asset
# (sha from the API "digest" field; empty if the release publishes none)
asset_from() {
  jq -r --arg re "$2" '
    [.assets[] | select(.name | test($re))][0]
    | [.browser_download_url, ((.digest // "") | sub("^sha256:"; ""))] | @tsv' <<<"$1"
}

# latest_tag <owner/repo> - newest release tag; falls back to newest git tag for
# repos with no GitHub "release" (e.g. zsh-completions)
latest_tag() {
  local t
  t=$(gh_latest "$1" 2>/dev/null | jq -r '.tag_name // empty')
  if [ -z "$t" ]; then
    t=$(git ls-remote --tags --refs "https://github.com/$1" 2>/dev/null \
        | sed 's#.*refs/tags/##' | sort -V | tail -1)
  fi
  printf '%s' "$t"
}

# install_bin <srcfile> <name> - place an executable into $PREFIX/bin
install_bin() {
  mkdir -p "$PREFIX/bin"
  chmod +x "$1"
  mv -f "$1" "$PREFIX/bin/$2"
  ok "installed $2 -> $PREFIX/bin/$2"
}

# clone_latest <owner/repo> <dest> - clone the newest release/tag over HTTPS into
# <dest> (replacing any existing copy). Falls back to the default branch.
clone_latest() {
  local tag tmp
  tag=$(latest_tag "$1")
  if [ -n "$tag" ] && [ "$(cat "$2/.tag" 2>/dev/null)" = "$tag" ]; then
    ok "$1 $tag already current"; return 0
  fi
  tmp=$(mktemp -d)
  if [ -n "$tag" ]; then
    git clone --depth 1 --branch "$tag" "https://github.com/$1" "$tmp/repo" >/dev/null 2>&1 \
      || die "clone failed: $1@$tag"
  else
    git clone --depth 1 "https://github.com/$1" "$tmp/repo" >/dev/null 2>&1 \
      || die "clone failed: $1"
    tag="(default branch)"
  fi
  rm -rf "$2"
  mkdir -p "$(dirname "$2")"
  mv "$tmp/repo" "$2"
  rm -rf "$tmp"
  printf '%s' "$tag" > "$2/.tag"   # marker so a later run can skip if unchanged
  ok "$1 $tag -> $2"
}

# === tool manifests for engines and uninstall ===

# prebuilt binaries -> install-binaries.sh
# name | owner/repo | asset regex (tarball, zip, or bare binary)
BINARIES=(
  "bat|sharkdp/bat|aarch64-apple-darwin\\.tar\\.gz$"
  "fd|sharkdp/fd|aarch64-apple-darwin\\.tar\\.gz$"
  "rg|BurntSushi/ripgrep|aarch64-apple-darwin\\.tar\\.gz$"
  "zoxide|ajeetdsouza/zoxide|aarch64-apple-darwin\\.tar\\.gz$"
  "delta|dandavison/delta|aarch64-apple-darwin\\.tar\\.gz$"
  "starship|starship/starship|aarch64-apple-darwin\\.tar\\.gz$"
  "btm|ClementTsang/bottom|aarch64-apple-darwin\\.tar\\.gz$"
  "tldr|tealdeer-rs/tealdeer|tealdeer-macos-aarch64$"
  "fzf|junegunn/fzf|darwin_arm64\\.tar\\.gz$"
  "carapace|carapace-sh/carapace-bin|darwin_arm64\\.tar\\.gz$"
  "fastfetch|fastfetch-cli/fastfetch|macos-aarch64\\.tar\\.gz$"
  "fnm|Schniz/fnm|fnm-macos\\.zip$"
)

# source builds -> build.sh
# name | owner/repo | source (asset regex to fetch+verify, or "clone") | build cmd | binary path
BUILDS=(
  'htop|htop-dev/htop|htop-.*\.tar\.xz$|./configure --prefix="$PREFIX" && make -j"$JOBS"|htop'
  'btop|aristocratos/btop|clone|make -j"$JOBS"|bin/btop'
)

# crates built with cargo -> build.sh
CARGO=(eza)

# git-clone zsh plugins -> plugins.sh
# name | owner/repo | dest
CLONES=(
  "zsh-completions|zsh-users/zsh-completions|$HOME/.local/share/zsh/zsh-completions"
  "fzf-tab|Aloxaf/fzf-tab|$HOME/.local/share/zsh/fzf-tab"
)
