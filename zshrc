# Shell Options
setopt NO_NOMATCH

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

  ## fzf - fuzzy finder
  command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"

  ## zoxide - smart cd
  export _ZO_DOCTOR=0
  eval "$(zoxide init zsh --cmd cd)"

  ## fastfetch
  if [[ $- == *i* ]]; then
    if (( COLUMNS >= 110 && LINES >= 24 )); then
      fastfetch
    fi
  fi

  ## starship (must be last)
  eval "$(starship init zsh)"

fi
