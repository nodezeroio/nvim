# NodeZero Nvim

The NodeZero Nvim setup is a [profile](./profiles.md) setup that allows for the configuration of [LazyVim Plugins](https://lazyvim.org) on a per profile basis. This allows for having language specific configuration, for example. 


Currently all plugins are forked from the [nodezero](https://github.com/nodezeroio) organization on github. In the future we will be adding scanning for security vulnerabilities to ensure that all the plugins meet basic standards for security. 


Some of the most commonly used shortcuts and commands are documented in the [cheat-sheet](./shortcuts-cheat-sheet.md).


## Installation

To run this nvim configuration you can clone it into the default `~/.config/nvim` or to your own directory like `~/.config/nodezero.nvim`, if you use a non standard path you will need to set the `NVIM_APPNAME` environment variable to start neovim with this configuration:

```sh
NVIM_APPNAME=nodezero.nvim nvim
```

## Treesitter parsers

Syntax highlighting and folding use Neovim's built-in treesitter (`vim.treesitter`) rather than the `nvim-treesitter` plugin. Neovim ships parsers for only seven languages — `c`, `lua`, `markdown`, `markdown_inline`, `query`, `vim` and `vimdoc` — and has no way to install more (see `:help treesitter-parsers`). Everything else has to be built, which this configuration automates.

Requires Neovim 0.12+, a C compiler (`cc`), plus `curl`, `tar` and `git`. On macOS the Xcode command line tools provide the compiler; on Debian/Ubuntu install `build-essential`.

### Installing

Build the parsers for every profile:

```sh
make treesitter
```

That takes about ten seconds from cold. To do a subset, set `TS_PROFILES`:

```sh
make treesitter TS_PROFILES="core;python"
```

`TS_PROFILES` is deliberately separate from `NODEZERO_NVIM_PROFILES`, which is usually set in your shell to whichever profile you are working in. The make targets default to *all* profiles so a fresh machine gets everything in one go.

From inside Neovim the same work is available for whichever profiles are currently active:

| Command | Effect |
| --- | --- |
| `:NodeZeroTSInstall [lang...]` | Build anything missing. `!` rebuilds everything. |
| `:NodeZeroTSUpdate [lang...]` | Rebuild languages whose pinned revision has moved. |
| `:NodeZeroTSClean` | Remove parsers no longer declared by any profile. |
| `:checkhealth nodezero.treesitter` | Report every declared language as current, out of date or missing. |

`:checkhealth nodezero.treesitter` is the first thing to run when a file is not highlighted.

### Where things land

Nothing is written into this repository. Parsers and queries are installed under `stdpath("data")/site`, which is already on `runtimepath`:

```
~/.local/share/nvim/site/parser/<lang>.so         # compiled grammars
~/.local/share/nvim/site/queries/<lang>/*.scm     # highlight, injection, fold, local queries
~/.local/share/nvim/site/nodezero-treesitter.json # what is installed, at which revision
```

If you run with `NVIM_APPNAME=nodezero.nvim` these live under `~/.local/share/nodezero.nvim/` instead. Downloaded grammar tarballs are cached in `stdpath("cache")/nodezero-treesitter` and can be deleted at any time.

Note that only highlighting and folding are configured. Built-in treesitter has no indent engine, so indentation is left to the language server and Neovim's own ftplugin indent files.

### Declaring a language for a profile

Each profile that needs treesitter has a `config/treesitter.lua` that names its languages, loaded from that profile's `config/init.lua`:

```lua
-- lua/nodezero/profiles/python/config/treesitter.lua
require("nodezero.treesitter").setup({
  languages = { "python" },
})
```

Add a `filetypes` entry whenever the filetype is not spelled the same as the parser. Without it the language is never activated, because the `FileType` autocmd has nothing to match on:

```lua
require("nodezero.treesitter").setup({
  languages = { "c_sharp" },
  filetypes = {
    c_sharp = { "cs" },
  },
})
```

This also applies to compound filetypes: a pattern of `yaml` does **not** match a buffer whose filetype is `yaml.ansible`, so the ansible profile registers `yaml = { "yaml.ansible" }` explicitly.

After changing a language list, regenerate the pinned grammar sources and rebuild:

```sh
make treesitter-sync
make treesitter
```

### Pinned sources

`lua/nodezero/treesitter/sources.lua` records the exact repository and revision each grammar is built from. It is generated — do not edit it by hand. `make treesitter-sync` rewrites it by reading the languages the profiles declare and resolving them against `nvim-treesitter`'s registry, so every version bump is a reviewable diff.

The sync fails loudly rather than quietly dropping a language, in two cases: a declared language with no upstream entry, and a grammar that would need the `tree-sitter` CLI to generate its parser. Neither is silently ignored.

Grammar revisions and queries are both taken from a **single** revision of `nvim-treesitter`. They must stay on the same commit — its queries are written against the grammar revisions its own registry pins, and mixing the two produces queries that reference node types the grammar does not have. To pick up newer grammars, sync the [nodezero fork](https://github.com/nodezeroio/nvim-treesitter) with upstream and re-run `make treesitter-sync`.

Queries are copied from `nvim-treesitter` (Apache-2.0); each grammar carries its own licence.

## TODO 

* Need a way to ensure all plugins are loaded from the correct url, there is an ordering question depending on which plugin is loaded first determines which url for the plugin is required. Currently some plugins are still being loaded from their default repository.
