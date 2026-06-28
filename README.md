# Affaan's dotfiles

<p align="center">
  <img src="assets/hero.png" alt="Ghostty running the Starship prompt and fastfetch" width="800">
</p>

My macOS terminal setup using Ghostty, Starship, Fastfetch, and some CLI tools.

> [!CAUTION]
> Personal config files.
> Read what each one does and take only the parts you want.
> Don't run configs you haven't read.
> Use at your own risk.

## Files

| File | Installs to | What it is |
| ---- | ----------- | ---------- |
| `zshrc` | `~/.zshrc` (merge, don't overwrite) | Shell config |
| `starship.toml` | `~/.config/starship.toml` | Single-line prompt |
| `config.ghostty` | `~/.config/ghostty/config` | Ghostty terminal config |
| `config.jsonc` | `~/.config/fastfetch/config.jsonc` | Fastfetch system-info layout |
| `statusline-command.sh` | `~/.claude/statusline-command.sh` | Tokyo Night Claude Code status line (macOS/Linux) |
| `statusline-command.ps1` | `%USERPROFILE%\.claude\statusline-command.ps1` | Tokyo Night Claude Code status line (Windows) |

> [!WARNING]
> Overwriting your `~/.zshrc` loses your current PATH, aliases, and shell config.  
> Merge the blocks you want into your existing one. Don't overwrite!

## Tools

Tools this setup uses.
`make tools` (non-Windows) installs them (except Ghostty, Git, and jq) (see [Installation](#installation)).

> [!IMPORTANT]
> If the `fzf` installer offers to edit your shell config, say `no`.
> Your `~/.zshrc` aliases `nvm` to `fnm`, so set the default Node version with `nvm default <version>`, not the old `nvm alias default`.

| Tool | Purpose |
| ---- | ------- |
| [Ghostty](https://ghostty.org) | Terminal |
| [Starship](https://starship.rs) | Prompt |
| [Fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info on launch |
| [bat](https://github.com/sharkdp/bat) | `cat` with highlighting |
| [fd](https://github.com/sharkdp/fd) | `find` replacement |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `grep` replacement |
| [eza](https://github.com/eza-community/eza) | `ls` replacement |
| [jq](https://github.com/jqlang/jq) | JSON processor - usually pre-installed on macOS |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` |
| [fnm](https://github.com/Schniz/fnm) | Node version manager |
| [Git](https://git-scm.com) | Version control - usually pre-installed on macOS |

## Fonts

- `starship.toml` and `statusline-command.sh` contain raw Nerd Font characters (powerline separators, icons).
  Copy the files directly; retyping or pasting from rendered text will break the glyphs.
- You'll need a [Nerd Font](https://www.nerdfonts.com) installed and selected in your terminal (I use `JetBrains Mono`).

## Installation

> [!NOTE]
> The steps below assume a macOS setup.
> On Windows the only applicable file is `statusline-command.ps1` (the Claude Code status line); see [Windows](#windows).
> The shell, terminal configs, and installer are macOS-only.

1. Install a Nerd Font (see [Fonts](#fonts)).

2. Clone the repo:

   ```sh
   git clone https://github.com/affaan-git/dotfiles.git
   cd dotfiles
   ```

3. Install the prerequisites (for `make tools`):

   - **Xcode Command Line Tools** - `xcode-select --install`
   - **Rust cargo-binstall** - [rustup.rs](https://rustup.rs), then `cargo install cargo-binstall cargo-update`
   - **Ghostty** - [ghostty.org](https://ghostty.org)

   `git` and `jq` are included with recent macOS and the Command Line Tools.
   On older macOS install `jq` first.

4. Install the [tools](#tools):

   ```sh
   make tools
   ```

   > Tools are built from source or fetched from each project's latest release and checksum-verified.
   > Run `make update` any time to refresh them all to their latest versions.

5. Link the configs into place (existing files are backed up first):

   ```sh
   make link
   ```

   > `make` on its own lists every target.

6. Merge the `zshrc` blocks you want into your own - it is not linked automatically (`make zsh` prints the steps).

7. Add the [status line](#statusline-command) config key to your settings.

## Config notes

### `starship.toml`

<img src="assets/starship.png" alt="Single-line Starship prompts across a sequence of commands, showing an OS icon, the working directory, git branch with a dirty marker, a Python version module, and a 12-hour clock" width="700">

- Muted gray caret, no red on failure
- Generous command/scan timeouts so slow git/filesystem modules aren't cut off

### `config.ghostty`

- 120x30 window, background blur, One Dark palette
- Opens at `$HOME`, no state restoration between sessions
- Keeps the window open after a process exits

### `zshrc`

The tool overrides (`cat`->bat, `catp`->paged bat, `grep`->rg, `ls`->eza, fzf, zoxide, fastfetch, starship) are behind `if [[ -n "$RICH_TERM" || "$TERM_PROGRAM" == "ghostty" ]]`, so Terminal.app stays mostly stock.

Always-on: `setopt NO_NOMATCH`, bash-style word motions, PATH (`~/.local/bin`), fnm, `python`/`pip`->`python3`/`pip3`, `explorer`/`finder`, and git helpers:

- `gs` status, `gl` log, `glp` log with diffs, `ga` add, `grs` restore --staged
- `gr` restore and `grc` rm --cached prompt for confirmation first (they can lose work)
- `gd` - smart diff: bare `gd` = all changes; `gd <ref>`/`<range>` diffs that; `gd <path>` vs HEAD
- `NO_NOMATCH` keeps unmatched glob characters as literal text (e.g. `pip install requests[socks]`, URLs with `?`) instead of zsh erroring with "no matches found".
  A glob that matches nothing is passed through literally rather than stopping the command, so zsh won't catch a typo'd `rm *.foo` for you
- `select-word-style bash` makes word motions (`Ctrl-W`, `Alt-Backspace`, `Alt-B`/`F`) stop at `/` and punctuation, so they act on one path segment at a time instead of the whole `a/b/c/d`

### `statusline-command`

<img src="assets/statusline.png" alt="Claude Code status line with model, directory, context percentage remaining, git status, and 12-hour clock" width="700">

Add to `~/.claude/settings.json` (merge this key, don't overwrite the file):

#### macOS/Linux

Needs `jq` and `git` on your PATH.

```json
{
  "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
}
```

#### Windows

Parses JSON natively, so no `jq`

> [!NOTE]
> Write the literal path in the `command`. `%USERPROFILE%` doesn't expand there. Forward slashes avoid escaping backslashes in JSON.

```json
{
  "statusLine": { "type": "command", "command": "powershell -NoProfile -File C:/Users/<you>/.claude/statusline-command.ps1" }
}
```

Restart Claude Code after editing `settings.json`.

---

All product names, logos, and trademarks are property of their respective owners.
