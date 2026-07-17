# dotfiles theme selector - source this from your shell rc; do not run it directly.
# Reads the active theme from the ~/.config/dotfiles/active symlink (-> themes/<name>)
# and points the shell tools (starship, fzf, fastfetch, bat) at it. Ghostty, delta,
# and nano read the same pointer through their own includes.

_dotfiles_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
_dotfiles_themes="$_dotfiles_cfg/themes"   # symlink into the repo's themes/
_dotfiles_ptr="$_dotfiles_cfg/active"      # symlink -> themes/<name>

# resolve the pointer to a theme name; default one-night
DOTFILES_THEME=$(readlink "$_dotfiles_ptr" 2>/dev/null)
DOTFILES_THEME=${DOTFILES_THEME%/}
DOTFILES_THEME=${DOTFILES_THEME##*/}
: "${DOTFILES_THEME:=one-night}"
export DOTFILES_THEME

# point the shell tools at the active theme's files (missing file = tool's default)
_dotfiles_apply_theme() {
  _d="$_dotfiles_ptr"
  [ -r "$_d/starship.toml" ]   && export STARSHIP_CONFIG="$_d/starship.toml"
  [ -r "$_d/fastfetch.jsonc" ] && export DOTFILES_FASTFETCH_CONFIG="$_d/fastfetch.jsonc"
  [ -r "$_d/fzf.opts" ]        && export FZF_DEFAULT_OPTS="$(cat "$_d/fzf.opts")"
  # bat follows delta's syntax theme
  if [ -r "$_d/delta.gitconfig" ]; then
    _bt=$(git config -f "$_d/delta.gitconfig" delta.syntax-theme 2>/dev/null)
    [ -n "$_bt" ] && export BAT_THEME="$_bt"
  fi
  unset _d _bt
}
_dotfiles_apply_theme

# theme [name|list] - switch the active theme
theme() {
  case "$1" in
    ""|-l|list|--list)
      printf 'themes:'
      for _t in "$_dotfiles_themes"/*/; do
        [ -d "$_t" ] || continue; _n=${_t%/}; printf ' %s' "${_n##*/}"
      done
      printf '\ncurrent: %s\n' "$DOTFILES_THEME"; unset _t _n; return 0 ;;
    -h|--help)
      printf 'usage: theme [<name>|list]\n'; return 0 ;;
  esac

  [ -d "$_dotfiles_themes/$1" ] || { printf 'theme: "%s" not found (see: theme list)\n' "$1" >&2; return 1; }
  mkdir -p "$_dotfiles_cfg"
  ln -sfn "$_dotfiles_themes/$1" "$_dotfiles_ptr"

  export DOTFILES_THEME="$1"
  _dotfiles_apply_theme
  printf 'theme -> %s\n' "$1"
  printf 'shell: new prompts are live. ghostty: reload with Cmd+Shift+, or open a new window.\n'
}
