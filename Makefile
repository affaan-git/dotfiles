# Affaan's dotfiles - link the config files into place.
# zshrc is not modified here; it is a manual merge (see 'make zsh').

.DEFAULT_GOAL := help
.PHONY: help link unlink tools update nano zsh

help: ## show the available targets
	@echo "Affaan's dotfiles:"
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{ printf "  make %-7s %s\n", $$1, $$2 }'

# repo file : install path (link and unlink)
CONFIGS = \
	starship.toml:$(HOME)/.config/starship.toml \
	config.ghostty:$(HOME)/.config/ghostty/config \
	config.jsonc:$(HOME)/.config/fastfetch/config.jsonc \
	statusline-command.sh:$(HOME)/.claude/statusline-command.sh \
	gitconfig:$(HOME)/.config/git/delta.gitconfig \
	nanorc:$(HOME)/.nanorc

link: ## symlink configs into place (backs up anything already there, skips zshrc)
	@set -e; \
	for pair in $(CONFIGS); do \
		src="$${pair%%:*}"; dst="$${pair#*:}"; \
		mkdir -p "$$(dirname "$$dst")"; \
		if [ -e "$$dst" ] && [ ! -L "$$dst" ]; then mv "$$dst" "$$dst.backup"; echo "  backed up $$dst -> $$dst.backup"; fi; \
		ln -sfn "$(CURDIR)/$$src" "$$dst"; echo "  linked $$dst"; \
	done; \
	mkdir -p "$(HOME)/.cache/nano/backups"; \
	if command -v delta >/dev/null 2>&1; then \
		if git config --global --get-all include.path 2>/dev/null | grep -qxF "~/.config/git/delta.gitconfig"; then echo "  git include already set"; \
		else git config --global --add include.path "~/.config/git/delta.gitconfig"; echo "  added delta include to ~/.gitconfig"; fi; \
	else echo "  delta not found - skipped git include (run 'make tools')"; fi; \
	echo; echo "Done. zshrc is a manual merge - run 'make zsh' for the steps."

unlink: ## remove the symlinks 'make link' made (only those pointing into this repo)
	@for pair in $(CONFIGS); do \
		f="$${pair#*:}"; \
		if [ -L "$$f" ]; then case "$$(readlink "$$f")" in "$(CURDIR)"/*) rm "$$f"; echo "  unlinked $$f";; esac; fi; \
	done; \
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

nano: ## build GNU nano with UTF-8 + highlighting from source
	@bash scripts/build-nano.sh
