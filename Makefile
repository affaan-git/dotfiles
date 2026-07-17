# Affaan's dotfiles - link the config files into place.
# zshrc is not modified here; it is a manual merge (see 'make zsh').

.DEFAULT_GOAL := help
.PHONY: help link unlink tools update eza nano htop btop fzf-tab zsh uninstall

help: ## show the available targets
	@echo "Affaan's dotfiles:"
	@grep -E '^[a-z][a-z -]*:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{ printf "  make %-9s %s\n", $$1, $$2 }'

# repo file : install path (link and unlink)
CONFIGS = \
	config.ghostty:$(HOME)/.config/ghostty/config \
	statusline-command.sh:$(HOME)/.claude/statusline-command.sh \
	gitconfig:$(HOME)/.config/git/delta.gitconfig \
	scripts/theme.sh:$(HOME)/.config/dotfiles/theme.sh \
	themes:$(HOME)/.config/dotfiles/themes

link: ## symlink configs into place (backs up anything already there, skips zshrc)
	@set -e; \
	for pair in $(CONFIGS); do \
		src="$${pair%%:*}"; dst="$${pair#*:}"; \
		mkdir -p "$$(dirname "$$dst")"; \
		if [ -e "$$dst" ] && [ ! -L "$$dst" ]; then mv "$$dst" "$$dst.backup"; echo "  backed up $$dst -> $$dst.backup"; fi; \
		ln -sfn "$(CURDIR)/$$src" "$$dst"; echo "  linked $$dst"; \
	done; \
	if [ ! -e "$(HOME)/.config/dotfiles/active" ]; then \
		ln -sfn "$(HOME)/.config/dotfiles/themes/one-night" "$(HOME)/.config/dotfiles/active"; \
		echo "  seeded theme pointer -> one-night"; \
	else echo "  theme pointer already set - kept"; fi; \
	if [ -e "$(HOME)/.nanorc" ] && [ ! -L "$(HOME)/.nanorc" ]; then mv "$(HOME)/.nanorc" "$(HOME)/.nanorc.backup"; echo "  backed up ~/.nanorc"; fi; \
	ln -sfn "$(HOME)/.config/dotfiles/active/nanorc" "$(HOME)/.nanorc"; echo "  linked ~/.nanorc -> active theme"; \
	if command -v delta >/dev/null 2>&1; then \
		if git config --global --get-all include.path 2>/dev/null | grep -qxF "~/.config/git/delta.gitconfig"; then echo "  git include already set"; \
		else git config --global --add include.path "~/.config/git/delta.gitconfig"; echo "  added delta include to ~/.gitconfig"; fi; \
	else echo "  delta not found - skipped git include (run 'make tools')"; fi; \
	echo; echo "Done. zshrc is a manual merge - run 'make zsh' for the steps."; \
	echo "Themes: 'theme list' shows them, 'theme <name>' switches (see THEMES.md)."

unlink: ## remove the symlinks 'make link' made (only those pointing into this repo)
	@for pair in $(CONFIGS); do \
		f="$${pair#*:}"; \
		if [ -L "$$f" ]; then case "$$(readlink "$$f")" in "$(CURDIR)"/*) rm "$$f"; echo "  unlinked $$f";; esac; fi; \
	done; \
	rm -f "$(HOME)/.config/dotfiles/active" "$(HOME)/.nanorc"; echo "  removed theme pointer + ~/.nanorc"; \
	if git config --global --get-all include.path 2>/dev/null | grep -qxF "~/.config/git/delta.gitconfig"; then git config --global --unset-all include.path 'delta\.gitconfig'; echo "  removed delta include from ~/.gitconfig"; fi; \
	echo "Any .backup files were left untouched."

zsh: ## print the zshrc merge steps (it is not installed automatically)
	@echo "zshrc is a merge, not a copy, so 'make link' does not modify it."
	@echo "Open zshrc, read it, and copy the blocks you want into your own ~/.zshrc."
	@echo "Overwriting ~/.zshrc entirely loses your existing PATH, aliases, and shell setup."

tools: ## install every CLI tool from source + releases (needs Xcode CLT and Rust)
	@bash scripts/install.sh install

update: ## update every installed tool to its latest release (skips up-to-date ones)
	@bash scripts/install.sh update

nano htop btop eza: ## build tools from source
	@bash scripts/build.sh $@

fzf-tab: ## install the fzf-tab zsh plugin (carapace + zsh-completions come from 'make tools')
	@bash scripts/plugins.sh $@

uninstall: unlink ## remove installed tools and unlink the configs
	@bash scripts/uninstall.sh
