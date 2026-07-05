#!/usr/bin/env bash
# Build GNU nano (UTF-8 + syntax highlighting) from its latest release into
# $PREFIX/bin, linked against a private static wide ncurses (the ncurses build is
# temporary). GNU publishes only GPG signatures and gpg is not on stock macOS, so
# rather than pin a hash we download each tarball from TWO official mirrors and
# require their SHA-256 to match before building. Skips when nano is already current.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

preflight cc make tar curl shasum

# latest_ver <gnu-listing-url> <name> -> highest version of <name>-VER.tar.gz
latest_ver() {
  curl -fsSL --proto '=https' --tlsv1.2 "$1" \
    | grep -oE "$2-[0-9]+(\\.[0-9]+)+\\.tar\\.gz" \
    | sed -E "s/^$2-//; s/\\.tar\\.gz\$//" | sort -V | uniq | tail -1
}

# fetch2 <label> <urlA> <urlB> <out> - fetch from both mirrors, require sha match
fetch2() {
  fetch "$2" "$4.a"
  fetch "$3" "$4.b"
  local a b
  a=$(shasum -a 256 "$4.a" | awk '{print $1}')
  b=$(shasum -a 256 "$4.b" | awk '{print $1}')
  [ "$a" = "$b" ] || die "$1: mirrors disagree ($a vs $b) - refusing"
  mv "$4.a" "$4"; rm -f "$4.b"
  say "$1 verified - two mirrors agree (${a:0:12}...)"
}

NANO_VER=$(latest_ver "https://ftp.gnu.org/gnu/nano/" nano)
NCURSES_VER=$(latest_ver "https://ftp.gnu.org/gnu/ncurses/" ncurses)
[ -n "$NANO_VER" ] && [ -n "$NCURSES_VER" ] || die "could not resolve latest nano/ncurses versions"
skip_if_current nano "$NANO_VER"

jobs=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
build=$(mktemp -d); trap 'rm -rf "$build"' EXIT; cd "$build"

say "latest: nano $NANO_VER, ncurses $NCURSES_VER"
fetch2 "ncurses $NCURSES_VER" \
  "https://ftp.gnu.org/gnu/ncurses/ncurses-$NCURSES_VER.tar.gz" \
  "https://invisible-island.net/archives/ncurses/ncurses-$NCURSES_VER.tar.gz" \
  ncurses.tgz
fetch2 "nano $NANO_VER" \
  "https://ftp.gnu.org/gnu/nano/nano-$NANO_VER.tar.gz" \
  "https://www.nano-editor.org/dist/v${NANO_VER%%.*}/nano-$NANO_VER.tar.gz" \
  nano.tgz

log=$(mktemp)
say "building wide ncurses (static, minimal, reusing system terminfo)"
tar xzf ncurses.tgz
if ! ( cd "ncurses-$NCURSES_VER"
  ./configure --prefix="$build/nc" --enable-widec \
    --without-shared --with-normal --without-debug \
    --without-progs --without-tests --without-manpages --without-ada \
    --with-default-terminfo-dir=/usr/share/terminfo --disable-db-install
  make -j"$jobs"
  make install ) >"$log" 2>&1; then
  echo "error: ncurses build failed:" >&2; tail -25 "$log" >&2; exit 1
fi

say "building nano linked against the static ncursesw"
tar xzf nano.tgz
if ! ( cd "nano-$NANO_VER"
  ./configure --prefix="$PREFIX" --disable-nls \
    CPPFLAGS="-I$build/nc/include -I$build/nc/include/ncursesw" \
    LDFLAGS="-L$build/nc/lib"
  make -j"$jobs"
  make install ) >>"$log" 2>&1; then
  echo "error: nano build failed:" >&2; tail -25 "$log" >&2; exit 1
fi
rm -f "$log"

say "verifying"
if "$PREFIX/bin/nano" --version | grep -q -- '--enable-utf8'; then
  "$PREFIX/bin/nano" --version | head -1
  ok "GNU nano $NANO_VER (UTF-8) installed to $PREFIX/bin/nano - temporary ncurses build removed"
else
  die "UTF-8 not enabled in the resulting binary"
fi
