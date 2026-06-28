#!/bin/sh
# Claude Code status line - Tokyo Night theme matching Starship prompt
# Special characters embedded as raw UTF-8

input=$(head -c 65536)

# jq parsing
if ! command -v jq >/dev/null 2>&1; then
  printf '[status line: jq not found]\n'
  exit 0
fi

# Nerd Font characters (raw UTF-8)
GRAD="░▒▓"
CLAUDE="❋"
SEP=""
CLOCK=""
GIT_ICON=""
CHECK="✓"
CROSS="✗"

# ANSI color helpers
fg() { printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
bg() { printf '\033[48;2;%s;%s;%sm' "$1" "$2" "$3"; }
RST=$(printf '\033[0m')
BOLD=$(printf '\033[1m')

# Safety
sanitize() { LC_ALL=C tr -d '[:cntrl:]'; }

# Clamp display field to $2 chars
clip() {
  awk -v max="$2" 'BEGIN { s = ARGV[1]; ARGV[1] = ""
    if (length(s) > max) printf "%s…", substr(s, 1, max - 1)
    else printf "%s", s }' "$1"
}

# Extract JSON fields
{
  read -r MODEL
  read -r CUR_DIR
  read -r USED_PCT
  read -r WORKTREE
} <<EOF
$(printf '%s' "$input" | jq -r '
  def clean: gsub("[[:cntrl:]]"; "");
  [ (.model.display_name            // "--" | clean),
    (.workspace.current_dir          // ""  | clean),
    (.context_window.used_percentage // ""  | tostring),
    (.worktree.name                  // ""  | clean) ] | .[]')
EOF

[ -z "$MODEL" ] && MODEL="--"
MODEL=$(clip "$MODEL" 40)
WORKTREE=$(clip "$WORKTREE" 30)

# Truncate directory to last 3 parts, replace HOME with ~ (pure shell, no subprocs)
truncate_dir() {
  case "$1" in
    "$HOME")   d="~" ;;
    "$HOME"/*) d="~${1#"$HOME"}" ;;
    *)         d="$1" ;;
  esac
  case "$d" in
    */*/*/*/*) printf '…/%s' "${d#"${d%/*/*/*}/"}" ;;
    *)         printf '%s' "$d" ;;
  esac
}

DIR_STR=""
if [ -n "$CUR_DIR" ]; then
  DIR_STR=$(truncate_dir "$CUR_DIR")
fi

# Worktree
[ -n "$WORKTREE" ] && DIR_STR="${DIR_STR} [${WORKTREE}]"
DIR_STR=$(clip "$DIR_STR" 60)

# Context used
if [ -n "$USED_PCT" ]; then
  REM_PCT=$(awk -v p="$USED_PCT" 'BEGIN { r = 100 - p; if (r < 0) r = 0; if (r > 100) r = 100; printf "%.0f", r }')
  CTX_STR="${REM_PCT}% left"
fi

# Git branch + dirty/clean
GIT_STR=""
if [ -n "$CUR_DIR" ] && git -C "$CUR_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(GIT_OPTIONAL_LOCKS=0 git -C "$CUR_DIR" symbolic-ref --short HEAD 2>/dev/null | sanitize)
  BRANCH=$(clip "$BRANCH" 40)
  if [ -n "$BRANCH" ]; then
    DIRTY=$(GIT_OPTIONAL_LOCKS=0 git -C "$CUR_DIR" status --porcelain 2>/dev/null)
    if [ -n "$DIRTY" ]; then
      GIT_STR=" $GIT_ICON $BRANCH $CROSS"
    else
      GIT_STR=" $GIT_ICON $BRANCH $CHECK"
    fi
  fi
fi

# =============== BUILD OUTPUT ===============

# Precompute the palette escapes once (one subshell each, not one per segment)
SILVER_FG=$(fg 163 174 210); SILVER_BG=$(bg 163 174 210)
BLUE_FG=$(fg 118 159 240);   BLUE_BG=$(bg 118 159 240)
NAVY_FG=$(fg 57 66 96);      NAVY_BG=$(bg 57 66 96)
STEEL_FG=$(fg 33 39 54);     STEEL_BG=$(bg 33 39 54)
COAL_FG=$(fg 29 34 48);      COAL_BG=$(bg 29 34 48)
INK_FG=$(fg 9 12 12)
FOG_FG=$(fg 227 229 229)
SLATE_FG=$(fg 160 169 203)

# Segment 3 inner: context + git
INFO_PARTS=""
[ -n "$CTX_STR" ] && INFO_PARTS="${CTX_STR}"
[ -n "$GIT_STR" ] && INFO_PARTS="${INFO_PARTS}${GIT_STR}"

# Time (LC_TIME=C so AM/PM is stable regardless of locale)
TIME_STR=$(LC_TIME=C date +"%-I:%M %p")

# Assemble the whole line in memory, then emit once (avoid a half-rendered line)

# gradient
OUT="${SILVER_FG}${GRAD}${RST}"
# claude logo
OUT="${OUT}${BOLD}${INK_FG}${SILVER_BG} ${CLAUDE} ${RST}"
# sep 0>1
OUT="${OUT}${SILVER_FG}${BLUE_BG}${SEP}${RST}"
# model
OUT="${OUT}${FOG_FG}${BLUE_BG} ${MODEL} ${RST}"
# sep 1>2
OUT="${OUT}${BLUE_FG}${NAVY_BG}${SEP}${RST}"
# directory
OUT="${OUT}${FOG_FG}${NAVY_BG} ${DIR_STR} ${RST}"
# sep 2>3
OUT="${OUT}${NAVY_FG}${STEEL_BG}${SEP}${RST}"
# context + git
OUT="${OUT}${SLATE_FG}${STEEL_BG} ${INFO_PARTS} ${RST}"
# sep 3>4
OUT="${OUT}${STEEL_FG}${COAL_BG}${SEP}${RST}"
# time
OUT="${OUT}${SLATE_FG}${COAL_BG} ${CLOCK} ${TIME_STR} ${RST}"
# end cap
OUT="${OUT}${COAL_FG}${SEP}${RST}"

printf '%s\n' "$OUT"
