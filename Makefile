# Makefile for nodezero.nvim development

# Ensure we're using Lua 5.1
LUA_VERSION = 5.1
LUAROCKS_CONFIG = --lua-version=$(LUA_VERSION)

.PHONY: install-deps install-dev test lint format check-lua-version clean help treesitter treesitter-sync treesitter-clean

# Profiles used when installing parsers headlessly. Deliberately NOT
# NODEZERO_NVIM_PROFILES: that is usually set in your shell to the profile you
# are working in, and these targets should default to every profile. Narrow it
# with e.g. `make treesitter TS_PROFILES="core;python"`.
TS_PROFILES ?= core;ansible;c_sharp;cue;lua;lwc;packer;php;pipewire;python;react;salesforce;typescript

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

check-lua-version: ## Verify Lua 5.1 is available
	@echo "Checking Lua version..."
	@which lua5.1 || (echo "Error: Lua 5.1 required but not found" && exit 1)
	@echo "✓ Lua 5.1 detected"

install-deps: check-lua-version ## Install runtime and development dependencies
	@echo "Installing dependencies with Lua 5.1..."
	luarocks $(LUAROCKS_CONFIG) install --local --only-deps nodezero-nvim-dev-1.rockspec

install-dev: check-lua-version ## Install in development mode
	@echo "Installing nodezero.nvim in development mode..."
	luarocks $(LUAROCKS_CONFIG) --local make nodezero-nvim-dev-1.rockspec

lint: ## Run luacheck for linting
	@echo "Running luacheck..."
	luacheck lua/

format: ## Format code with stylua
	@echo "Formatting code with stylua..."
	stylua lua/ --config-path=stylua.toml

format-check: ## Check if code is properly formatted
	@echo "Checking code formatting..."
	stylua --check lua/ --config-path=stylua.toml

treesitter: ## Build treesitter parsers for the declared languages
	@echo "Installing treesitter parsers..."
	@NODEZERO_NVIM_PROFILES="$(TS_PROFILES)" nvim --headless \
		-c 'lua require("nodezero.treesitter.install").install({ update = true, wait = true })' \
		-c 'qa!'

treesitter-sync: ## Refresh the pinned grammar revisions in sources.lua
	@nvim -l scripts/sync-treesitter-sources.lua

treesitter-clean: ## Remove parsers no longer declared by any profile
	@NODEZERO_NVIM_PROFILES="$(TS_PROFILES)" nvim --headless \
		-c 'lua require("nodezero.treesitter.install").clean()' -c 'qa!'

clean: ## Clean up installed rocks and temporary files
	@echo "Cleaning up..."
	luarocks $(LUAROCKS_CONFIG) remove nodezero.nvim || true
	rm -rf .luarocks/

