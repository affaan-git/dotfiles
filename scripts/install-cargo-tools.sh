#!/usr/bin/env bash
# Install/update the Rust CLI tools via cargo-binstall (prebuilt binaries pulled
# from each crate's own GitHub releases and verified by binstall). They land in
# ~/.cargo/bin. Rust is a prerequisite - this script never installs or
# manages the toolchain itself.
#
# Update all of these later with: cargo install-update -a  #needs cargo-update
set -euo pipefail
source "$(dirname "$0")/lib.sh"

need cargo "install Rust: https://rustup.rs  (then: cargo install cargo-binstall cargo-update)"
command -v cargo-binstall >/dev/null 2>&1 \
  || die "cargo-binstall not found - run: cargo install cargo-binstall"

CRATES=(bat fd-find ripgrep eza zoxide git-delta starship bottom tealdeer fnm)

say "installing/updating rust tools via cargo binstall"
cargo binstall --no-confirm "${CRATES[@]}"
ok "rust tools in ~/.cargo/bin  (update them with: cargo install-update -a)"
