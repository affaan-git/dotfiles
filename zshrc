# Shell Options
setopt NO_NOMATCH
setopt HIST_IGNORE_SPACE

# Bash-style word motions
autoload -Uz select-word-style && select-word-style bash

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Node (fnm) - all interactive shells, outside needing rich-term
eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
alias nvm=fnm   # muscle-memory redirect (set default node version with 'nvm default X', not 'nvm alias default X')

# Aliases
alias cls=clear
alias edit=nano
alias awake="caffeinate -dimsu" # screen on
alias nosleep="caffeinate -ims" # screen may sleep

## Python - use python3/pip3 in PATH (version-agnostic)
alias python=python3
alias pip=pip3

## File manager
function explorer {
  if [[ -n "$1" ]]; then
    open "$1"
  else
    open .
  fi
}
alias finder=explorer

## git
alias gs="git status"

### gd - git diff; bare 'gd' shows all changes (staged + unstaged)
gd() {
  if (( $# == 0 )); then
    git diff HEAD
  elif [[ "$1" == -* || "$1" == *..* ]] || git rev-parse --verify --quiet "$1^{commit}" >/dev/null 2>&1; then
    git diff "$@"
  else
    git diff HEAD -- "$@"
  fi
}
### grc - git rm --cached; untracks file(s) but keeps them on disk, confirm first
grc() {
  (( $# == 0 )) && { git rm --cached; return; }
  print -n "untrack (keep on disk): $* ? [y/N] "
  read -q 2>/dev/null || { print " - aborted"; return 1; }
  print
  git rm --cached "$@"
}
alias ga="git add"
### gr - git restore; discards uncommitted changes, confirm first
gr() {
  (( $# == 0 )) && { git restore; return; }
  print -n "discard changes to: $* ? [y/N] "
  read -q 2>/dev/null || { print " - aborted"; return 1; }
  print
  git restore "$@"
}
alias grs="git restore --staged"
alias gl="git log"
alias glp="git log -p"

# CLI replacements and tools (ghostty/RICH_TERM=1 only)
if [[ -n "$RICH_TERM" || "$TERM_PROGRAM" == "ghostty" ]]; then

  ## theme selector - sets the tool configs (starship/fzf/fastfetch/bat) and adds 'theme'
  [ -r "$HOME/.config/dotfiles/theme.sh" ] && source "$HOME/.config/dotfiles/theme.sh"

  ## bat - better cat
  alias cat="bat --paging=never"
  alias catp="bat"

  ## ripgrep - better grep
  alias grep="rg"

  ## file list (eza - modern ls)
  if command -v eza >/dev/null 2>&1; then
    alias ls="eza --group-directories-first --icons=auto"
    alias ll="eza -l  --group-directories-first --icons=auto --git"
    alias la="eza -a  --group-directories-first --icons=auto"
    alias lx="eza -la --group-directories-first --icons=auto --git --extended"
    alias lt="eza --tree --level=2 --icons=auto"
    alias lg="eza -la --git --git-ignore --icons=auto --group-directories-first"
  else
    ## fall back to BSD ls if eza isn't installed
    alias ls="ls -G"
    alias ll="ls -lG"
    alias la="ls -GA"
    alias lx="ls -lGA@"
  fi

  ## completions (order matters: fpath -> compinit -> fzf -> carapace -> fzf-tab)
  # extra completion definitions must join fpath before compinit
  [ -d "$HOME/.local/share/zsh/zsh-completions/src" ] && fpath=("$HOME/.local/share/zsh/zsh-completions/src" $fpath)
  autoload -Uz compinit && compinit
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive matching

  ## fzf - fuzzy finder + shell completions
  command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"

  ## carapace - completion engine (after compinit)
  command -v carapace >/dev/null 2>&1 && source <(carapace _carapace zsh)

  ## fzf-tab - fzf-powered completion menu (must be last)
  if [ -f "$HOME/.local/share/zsh/fzf-tab/fzf-tab.plugin.zsh" ]; then
    source "$HOME/.local/share/zsh/fzf-tab/fzf-tab.plugin.zsh"
    zstyle ':completion:*' menu no   # give the menu to fzf-tab instead of zsh
    zstyle ':fzf-tab:*' use-fzf-default-opts yes   # inherit the themed FZF_DEFAULT_OPTS
    zstyle ':fzf-tab:*' switch-group '<' '>'
    zstyle ':fzf-tab:*' continuous-trigger 'right'
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=auto --color=always $realpath'
  fi

  ## zoxide - smart cd
  export _ZO_DOCTOR=0
  eval "$(zoxide init zsh --cmd cd)"

  ## fastfetch (themed config from the selector)
  if [[ $- == *i* ]]; then
    if (( COLUMNS >= 110 && LINES >= 24 )); then
      if [[ -n "$DOTFILES_FASTFETCH_CONFIG" ]]; then
        fastfetch --config "$DOTFILES_FASTFETCH_CONFIG"
      else
        fastfetch
      fi
    fi
  fi

  ## starship (must be last)
  eval "$(starship init zsh)"

fi
