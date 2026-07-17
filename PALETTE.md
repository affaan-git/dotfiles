# Palette

A theme's colors are split across a few files because the programs can't share
variables. This maps each slot to the files and keys that carry it, so a retheme
hits every copy. Actual values live per theme in `themes/<name>/`.

There are **two independent palettes** - retheme one without touching the other.

## Palette A - accent

The prompt/logo/status-line accent. Named once in `starship.toml`, repeated
elsewhere as hex or RGB.

| Slot | starship.toml | fastfetch.jsonc | statusline.env |
| ---- | ------------- | --------------- | -------------- |
| silver | `silver` | logo `1`,`6`; `title` | `SILVER` |
| blue | `blue` | logo `3`,`4`; `keys` | `BLUE` |
| navy | `navy` | - | `NAVY` |
| steel | `steel` | - | `STEEL` |
| coal | `coal` | - | `COAL` |
| ink | `ink` | - | `INK` |
| fog | `fog` | - | `FOG` |
| slate | `slate` | - | `SLATE` |
| gray | `gray` (caret) | - | - |
| logo mid | - | logo `2`,`5` | - |

`statusline.env` is RGB (`163 174 210`), the rest hex. `statusline-command.ps1`
(Windows) mirrors the same accent by hand and is not part of the theme system.

## Palette B - terminal

The 16-color terminal theme, set in `ghostty.theme` and mirrored into `fzf.opts`.
`nanorc` follows the same slots by ANSI name, so it never hardcodes hex.

| Role | ghostty.theme | fzf.opts key |
| ---- | ------------- | ------------ |
| background | `background` | `gutter` |
| selection | `selection-background` | `bg+`, `border` |
| white / fg | `palette 7` | `fg` |
| bright white | `selection-foreground` | `fg+` |
| blue | `palette 4` | `hl`, `hl+`, `prompt`, `pointer` |
| green | `palette 2` | `marker` |
| magenta | `palette 5` | `spinner` |
| cyan | `palette 6` | `header` |
| bright black | `palette 8` | `info` |

nano's config lives per theme in `nanorc` (interface colors use ANSI *names* like
`keycolor`; `set` commands must be in the main rc, so `~/.nanorc` links to the active
theme's copy). Syntax highlighting comes from the bundled
`~/.local/share/nano/*.nanorc` files, not this palette.

Delta (git diff) has its own per-theme `delta.gitconfig` (each sets a syntax theme
and its own muted +/- backgrounds); bat reuses that same syntax theme.

## Not themed

Left at each tool's default: eza, nano syntax highlighting, and btop (turn
`theme_background` off to keep the terminal background).

## Retheme

Edit a theme's files under `themes/<name>/`: `starship.toml` (the `[palettes.theme]`
block), `fastfetch.jsonc`, `statusline.env` (RGB), `ghostty.theme`, `fzf.opts`
(match the Ghostty values), `nanorc`, and `delta.gitconfig`.
