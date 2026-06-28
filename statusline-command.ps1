# Claude Code status line - Tokyo Night theme (Windows/PowerShell port)
# Input:  JSON on stdin from Claude Code
# Output: one ANSI-styled Powerline-lite line to stdout
#
# No Nerd Font required: all glyphs are standard Unicode that renders in any
# modern monospace font (Cascadia Mono, Consolas, etc.). Glyphs are expressed
# as numeric codepoints so this source file stays ASCII-clean on disk.

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Read + parse stdin. Decode as UTF-8 explicitly; the console input code page
# is not always UTF-8, which would mangle non-ASCII paths/worktree names.
$MAX_PAYLOAD = 65536
$raw = ''
try {
    $reader = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $buf = New-Object char[] $MAX_PAYLOAD
    $n = $reader.ReadBlock($buf, 0, $MAX_PAYLOAD)
    if ($n -gt 0) { $raw = [string]::new($buf, 0, $n) }
} catch { $raw = '' }
$data = $null
if ($raw -and $raw.Length -le $MAX_PAYLOAD) {
    try { $data = $raw | ConvertFrom-Json } catch { $data = $null }
}

# Glyphs (all standard Unicode, no Nerd Font needed)
$GRAD     = [string]([char]0x2591) + [char]0x2592 + [char]0x2593   # light/medium/dark shade blocks
$CLAUDE   = [char]0x274B                                           # heavy 8-pointed asterisk
$SEP      = [char]0x258C                                           # left half block - Powerline-lite separator
$CLOCK    = [char]0x25F7                                           # circle w/ upper-right quadrant - clock-face stand-in
$GIT_ICON = [char]0x2387                                           # "alternative key" glyph, conventional non-Nerd branch mark
$CHECK    = [char]0x2713
$CROSS    = [char]0x2717
$ELLIPSIS = [char]0x2026

# ANSI helpers
$ESC  = [char]27
$RST  = "$ESC[0m"
$BOLD = "$ESC[1m"
function Fg([int]$r,[int]$g,[int]$b) { "$ESC[38;2;$r;$g;${b}m" }
function Bg([int]$r,[int]$g,[int]$b) { "$ESC[48;2;$r;$g;${b}m" }

# Safety
function Sanitize-Display {
    param([string]$s, [int]$maxLen = 80)
    if (-not $s) { return '' }
    $clean = [regex]::Replace($s, '[\x00-\x1F\x7F-\x9F]', '')
    if ($clean.Length -gt $maxLen) {
        $clean = $clean.Substring(0, $maxLen - 1) + $ELLIPSIS
    }
    return $clean
}

try {

# Extract JSON fields
$MODEL    = '--'
$CUR_DIR  = ''         # raw path, kept un-sanitized for git/Test-Path correctness
$USED_PCT = $null
$WORKTREE = ''
if ($data) {
    if ($data.model          -and $data.model.display_name)                         { $MODEL    = [string]$data.model.display_name }
    if ($data.workspace      -and $data.workspace.current_dir)                      { $CUR_DIR  = [string]$data.workspace.current_dir }
    if ($data.context_window -and ($null -ne $data.context_window.used_percentage)) { $USED_PCT = [double]$data.context_window.used_percentage }
    if ($data.worktree       -and $data.worktree.name)                              { $WORKTREE = [string]$data.worktree.name }
}
$MODEL    = Sanitize-Display $MODEL    40
$WORKTREE = Sanitize-Display $WORKTREE 30

# Collapse directory to last 3 parts if deep (HOME -> ~ available below)
function Format-Dir([string]$p) {
    if (-not $p) { return '' }
    # HOME -> ~ substitution (matches the .sh; fall back to $HOME off Windows)
    $home1 = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    if ($home1 -and $p.StartsWith($home1, [System.StringComparison]::OrdinalIgnoreCase)) {
        $p = '~' + $p.Substring($home1.Length)
    }
    $parts = $p -split '[\\/]' | Where-Object { $_ -ne '' }
    if ($parts.Count -gt 4) {
        $tail = $parts[($parts.Count - 3)..($parts.Count - 1)] -join '\'
        return "$ELLIPSIS\$tail"
    }
    return $p
}

$DIR_STR = Format-Dir $CUR_DIR
if ($WORKTREE) { $DIR_STR = "$DIR_STR [$WORKTREE]" }
$DIR_STR = Sanitize-Display $DIR_STR 60

# Context remaining
$CTX_STR = ''
if ($null -ne $USED_PCT) {
    $rem = [int][math]::Round(100 - $USED_PCT)
    if ($rem -lt 0)   { $rem = 0 }
    if ($rem -gt 100) { $rem = 100 }
    $CTX_STR = "$rem% left"
}

# Git branch + dirty/clean
$GIT_STR = ''
if ($CUR_DIR -and (Test-Path -LiteralPath $CUR_DIR) -and (Get-Command git -ErrorAction SilentlyContinue)) {
    try {
        $env:GIT_OPTIONAL_LOCKS = '0'
        $null = & git -C $CUR_DIR rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -eq 0) {
            $branch = (& git -C $CUR_DIR symbolic-ref --short HEAD 2>$null)
            if ($LASTEXITCODE -eq 0 -and $branch) {
                $branch = Sanitize-Display $branch 40
                $dirty  = (& git -C $CUR_DIR status --porcelain 2>$null)
                if ($dirty) { $mark = $CROSS } else { $mark = $CHECK }
                $GIT_STR = " $GIT_ICON $branch $mark"
            }
        }
    } catch { $GIT_STR = '' }
}

# Time (InvariantCulture for stable AM/PM marker regardless of locale)
$TIME_STR = (Get-Date).ToString('h:mm tt', [System.Globalization.CultureInfo]::InvariantCulture)

# =============== Build output ===============
$out = ''

# Segment 0: gradient + Claude mark   (#a3aed2 bg)
$out += (Fg 163 174 210) + $GRAD + $RST
$out += $BOLD + (Fg 9 12 12) + (Bg 163 174 210) + " $CLAUDE " + $RST

# Sep 0 -> 1
$out += (Fg 163 174 210) + (Bg 118 159 240) + $SEP + $RST

# Segment 1: model                    (#769ff0 bg)
$out += (Fg 227 229 229) + (Bg 118 159 240) + " $MODEL " + $RST

# Sep 1 -> 2
$out += (Fg 118 159 240) + (Bg 57 66 96) + $SEP + $RST

# Segment 2: directory                (#394260 bg)
$out += (Fg 227 229 229) + (Bg 57 66 96) + " $DIR_STR " + $RST

# Sep 2 -> 3
$out += (Fg 57 66 96) + (Bg 33 39 54) + $SEP + $RST

# Segment 3: context + git            (#212736 bg)
$info = ''
if ($CTX_STR) { $info  = $CTX_STR }
if ($GIT_STR) { $info += $GIT_STR }
$out += (Fg 160 169 203) + (Bg 33 39 54) + " $info " + $RST

# Sep 3 -> 4
$out += (Fg 33 39 54) + (Bg 29 34 48) + $SEP + $RST

# Segment 4: clock + time              (#1d2230 bg)
$out += (Fg 160 169 203) + (Bg 29 34 48) + " $CLOCK $TIME_STR " + $RST

# End cap
$out += (Fg 29 34 48) + $SEP + $RST

[Console]::Out.WriteLine($out)

} catch {
    # Fallback: single plain line
    try { [Console]::Out.WriteLine('[status line error]') } catch { }
    exit 0
}
