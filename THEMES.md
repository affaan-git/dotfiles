# Themes

- **`one-night`** (default) - One Dark terminal with a Clear Dark blue/silver accent.
- **`pro-black`** - near-black terminal with a graphite/silver accent.

## Switching

```sh
theme pro-black     # switch to pro-black
theme one-night     # switch back to one-night
theme list          # show options and the current theme
```

Prompts update on the next line. Reload Ghostty to repaint it: Cmd+Shift+, or from its
command palette.

## A theme's files

Each theme is a self-contained folder, `themes/<name>/`:

| File | Themes |
| ---- | ------ |
| `starship.toml` | the prompt |
| `ghostty.theme` | terminal colors + opacity |
| `fastfetch.jsonc` | the fastfetch logo |
| `fzf.opts` | the fzf picker |
| `statusline.env` | the Claude Code status line |
| `nanorc` | nano config + interface colors |
| `delta.gitconfig` | git diff (delta) colors |

[`PALETTE.md`](PALETTE.md) maps the slots.

## Adding a theme

1. `cp -r themes/one-night themes/<name>` and edit the colors.
2. `theme <name>`. No edits to `Makefile` or `theme.sh` - `themes/` is one symlink and
   `theme` accepts any folder under it.
