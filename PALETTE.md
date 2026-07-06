# Palette

These configs are read by different programs (Ghostty, Starship, Fastfetch, fzf, nano, bash, PowerShell).
Variables cannot be cleanly shared, so the same colors are repeated across files in a few different encodings.
This file is a reference that lists every color once and maps where each copy lives, to make re-theming easier.

There are **two independent palettes**.
You can retheme one without touching the other.

- **Palette A - accent** (blue/silver): the Starship prompt, the Fastfetch logo, and the Claude Code status line.
- **Palette B - One Dark** (terminal): the Ghostty 16-color theme, mirrored into the fzf picker (as hex) and referenced by name in `nanorc`.

## Palette A - accent (blue / silver)

| Name | Hex | RGB | Where it lives |
| ---- | --- | --- | -------------- |
| silver | `#a3aed2` | `163 174 210` | `starship.toml` (`silver`) / `config.jsonc` (logo `1`,`6`; `title`) / `statusline-command.sh` (`SILVER`) / `statusline-command.ps1` (seg 0) |
| blue | `#769ff0` | `118 159 240` | `starship.toml` (`blue`) / `config.jsonc` (logo `3`,`4`; `keys`) / `statusline-command.sh` (`BLUE`) / `statusline-command.ps1` (seg 1) |
| navy | `#394260` | `57 66 96` | `starship.toml` (`navy`) / `statusline-command.sh` (`NAVY`) / `statusline-command.ps1` (seg 2) |
| steel | `#212736` | `33 39 54` | `starship.toml` (`steel`) / `statusline-command.sh` (`STEEL`) / `statusline-command.ps1` (seg 3) |
| coal | `#1d2230` | `29 34 48` | `starship.toml` (`coal`) / `statusline-command.sh` (`COAL`) / `statusline-command.ps1` (seg 4) |
| ink | `#090c0c` | `9 12 12` | `starship.toml` (`ink`) / `statusline-command.sh` (`INK`) / `statusline-command.ps1` (seg 0 text) |
| fog | `#e3e5e5` | `227 229 229` | `starship.toml` (`fog`) / `statusline-command.sh` (`FOG`) / `statusline-command.ps1` (seg 1-2 text) |
| slate | `#a0a9cb` | `160 169 203` | `starship.toml` (`slate`) / `statusline-command.sh` (`SLATE`) / `statusline-command.ps1` (seg 3-4 text) |
| gray | `#6b7089` | `107 112 137` | `starship.toml` (`gray`) - prompt caret only |
| (logo mid) | `#8da6e8` | `141 166 232` | `config.jsonc` (logo `2`,`5`) - Fastfetch gradient midpoint only |

## Palette B - One Dark (terminal)

Defined once in `config.ghostty`; the fzf line in `zshrc` re-hardcodes a subset as hex, and `nanorc` references slots by ANSI name.
Fastfetch's `colors` module also displays this palette live (the ANSI swatches at the end of the system info), reading it from the terminal rather than defining any value.
Every fzf color below is a copy of a Ghostty value.

| Role | Hex | Ghostty source | fzf key(s) in `zshrc` |
| ---- | --- | -------------- | --------------------- |
| background | `#282c3c` | `background` | `gutter` |
| selection | `#404859` | `selection-background` | `bg+`, `border` |
| white / fg | `#abb2bf` | `palette 7` | `fg` |
| bright white | `#ffffff` | `selection-foreground` | `fg+` |
| blue | `#61afef` | `palette 4` | `hl`, `hl+`, `prompt`, `pointer` |
| green | `#98c379` | `palette 2` | `marker` |
| magenta | `#c678dd` | `palette 5` | `spinner` |
| cyan | `#56b6c2` | `palette 6` | `header` |
| bright black | `#5c6370` | `palette 8` | `info` |

The remaining One Dark slots (`#d19a66`, `#e0e0e0`, plus `foreground`/`cursor-color` `#cccccc`) live only in `config.ghostty`.

### nanorc (One Dark by ANSI name)

`nanorc` colors nano's interface with ANSI color *names*, not hex.
Per nano's manual those names are the 16 ANSI colors (`grey`/`gray` = `lightblack`), so each renders as whatever `config.ghostty` maps that slot to.
That makes `nanorc` a third copy of Palette B, but one that stays in sync on its own because it never hardcodes hex.
The five colors it uses (plus the `bold` attribute):

| nanorc setting | nano name | Ghostty slot | Hex |
| -------------- | --------- | ------------ | --- |
| `titlecolor`, `statuscolor`, `promptcolor` | white on black | `palette 7` on `palette 0` | `#abb2bf` on `#3f4451` |
| `errorcolor` | white on red | `palette 7` on `palette 1` | `#abb2bf` on `#e06c75` |
| `keycolor` | cyan | `palette 6` | `#56b6c2` |
| `functioncolor`, `numbercolor` | grey (`lightblack`) | `palette 8` | `#5c6370` |

Syntax highlighting comes from the bundled GNU nano files (`include "~/.local/share/nano/*.nanorc"`) and uses their stock colors, not this palette.

### Not themed

Some tools produce color but are left at their defaults, so they are in neither palette:

- `gitconfig`/delta - delta's default syntax theme (no colors set).
- `eza` (`--color=always` in `zshrc`) - eza's built-in colors; no `EZA_COLORS`/`LS_COLORS` override.
- `bat` (aliased to `cat`) - bat's default theme; no `BAT_THEME` set.
- nano syntax highlighting - the bundled `~/.local/share/nano/*.nanorc` files' stock colors.
- `btop` - built-in themes; turn `theme_background` off to keep the terminal background.

## How to re-theme

**Palette A (accent):**

1. `starship.toml` lines 36-44 - the `[palettes.theme]` block. This is the only file with named colors, so editing the 9 definitions here retints the whole prompt.
2. `config.jsonc` lines 5-16 - Fastfetch logo (`1`-`6`) and `keys`/`title`. Hex.
3. `statusline-command.sh` lines 103-110 - the `*_FG`/`*_BG` assignments. **RGB, not hex** (`fg 163 174 210`), so convert.
4. `statusline-command.ps1` - the `(Fg ...)`/`(Bg ...)` calls in the segment block. Same RGB format as the `.sh`; keep the two status lines in sync.

**Palette B (One Dark):**

1. `config.ghostty` lines 15-39 - `background`, `selection-*`, and `palette 0`-`15`.
2. `zshrc` - the `FZF_DEFAULT_OPTS` line. Update only the keys in the table above, matching whatever the Ghostty values became.
3. `nanorc` - uses ANSI color *names*, so it re-themes automatically when `config.ghostty`'s palette changes. Edit it only to point a setting at a different slot (e.g. `keycolor` from `cyan` to `blue`).

The copies are independent by necessity, so a retheme means editing each listed spot.
This file just helps you edit all of them and none by surprise.
