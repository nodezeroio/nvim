# Brief: automating treesitter parser installation

**Status:** proposal
**Date:** 2026-07-31
**Follows:** the migration from `nvim-treesitter` to built-in `vim.treesitter` (per-profile `config/treesitter.lua` + `lua/nodezero/treesitter/`)

## Problem

The profiles now declare treesitter languages through `require("nodezero.treesitter").setup({ languages = {...} })`, and the helper starts highlighting via `vim.treesitter.start()`. But Neovim ships parsers for only 7 languages — `c`, `lua`, `markdown`, `markdown_inline`, `query`, `vim`, `vimdoc` — and has **no parser installer** (`:help treesitter-parsers`: *"You can install more parsers manually, or with a plugin like nvim-treesitter"*).

Across the 15 profiles, 28 languages are declared. 23 of them have no parser, so `:checkhealth nodezero.treesitter` currently reports them missing and those buffers get no highlighting. Provisioning was deliberately left out of the migration; this brief closes it.

Two things must be provisioned per language, not one:

1. **A parser** — a compiled shared object at `parser/<lang>.so` on `runtimepath`.
2. **Queries** — `queries/<lang>/highlights.scm` etc. Without these a parser produces a syntax tree that nothing consumes, and highlighting stays dark.

## Research findings

Everything below was verified on this machine (Neovim 0.12.4, macOS, `/usr/bin/cc`), not inferred.

### 1. nvim-treesitter's queries work with built-in Neovim, with no plugin runtime

This is the finding the whole proposal rests on. Two things make it true:

- **`main` has no `query_predicates.lua`.** That file existed only on `master`, and was the reason master's queries needed the plugin loaded. `main`'s `lua/nvim-treesitter/` contains only `async, config, health, indent, init, install, log, parsers, util`. Its queries use only predicates Neovim implements natively (`#eq?`, `#match?`, `#lua-match?`, `#any-of?`, `#has-ancestor?`, `#has-parent?`, plus the `not-`/`any-` prefixes).
- **Neovim natively supports the `; inherits:` and `; extends` query modelines** (`treesitter.txt:279-308`). nvim-treesitter's query set is modular — `typescript/highlights.scm` opens with `; inherits: ecma` — and Neovim resolves that itself.

Verified: with only `typescript.so` and the `typescript/` + `ecma/` query dirs on `runtimepath`, `vim.treesitter.query.get("typescript", "highlights")` returns a merged query of **46 captures** including ecma-inherited ones, and the highlighter attaches.

So we can consume nvim-treesitter's curated queries as *data* without adopting it as a plugin. There is no other maintained source of Neovim-shaped queries; upstream grammar repos ship queries written for the tree-sitter highlight crate, with different capture conventions.

### 2. No `tree-sitter` CLI, no Node, no Rust is needed

nvim-treesitter's own installer shells out to `tree-sitter build`. We don't have to: every grammar we need ships a **pre-generated `src/parser.c`**, so a plain compiler call suffices. `tree-sitter generate` is only required when a grammar ships `grammar.js` but no `parser.c` — that's **8 of 320** registry grammars (2%), and **none** of ours.

The full build is:

```sh
cc  -o <out>/<lang>.so -shared -Os -fPIC -I<src> <src>/parser.c [<src>/scanner.c]
c++ -o <out>/<lang>.so -shared -Os -fPIC -I<src> <src>/parser.c  <src>/scanner.cc   # if scanner.cc
```

### 3. Full build validated — 24/24, 18 seconds

All 24 required grammars were fetched at their pinned revisions and compiled with `/usr/bin/cc`:

```
apex bash c_sharp css cue diff dtd hcl html javascript jinja jinja_inline
json json5 luadoc luap php php_only phpdoc python toml typescript xml yaml
```

| Metric | Result |
| --- | --- |
| Parsers compiled | 24 / 24, zero failures |
| Wall clock (cold cache, parallel-free) | 18s build, ~23s including downloads |
| Parsers that load in Neovim | 24 / 24 |
| `highlights.scm` that parse | 24 / 24 |
| Disk — parsers | 14 MB (`c_sharp` 5.1 MB and `apex` 1.5 MB dominate) |
| Disk — queries | 532 KB, 122 files, 33 languages |
| Grammars needing a C++ scanner | 0 (all used plain `cc`) |
| Grammars needing `tree-sitter generate` | 0 |

Neovim 0.12.4 accepts parser ABI 13–15; the pinned revisions produce ABI-15 parsers, matching the bundled ones.

### 4. Four gotchas the implementation must handle

- **The `requires` closure.** Query inheritance pulls in languages the profiles never declare. Our 28 declared languages expand to **33**, adding `dtd`, `ecma`, `html_tags`, `jsx`, `php_only`. Of these, `ecma`, `jsx` and `html_tags` are *query-only* — they have no grammar and must not be built, only their query dirs fetched. `dtd` and `php_only` are real parsers pulled in by `xml` and `php`.
- **Subdirectory grammars need the whole repo.** `php`'s scanner does `#include "../../common/scanner.h"`, reaching outside its `location`. Extracting only the subdirectory breaks the build; extract the full tarball and compile from within it.
- **Tarball sharing.** Three repos each supply two languages — `xml`+`dtd`, `php`+`php_only`, `jinja`+`jinja_inline`. Cache downloads keyed on `(url, revision)` or you fetch each twice.
- **`jsonc` does not exist upstream.** It has no entry in nvim-treesitter `main` and no query directory — `main` dropped it. The `core` profile currently declares it, which is why it shows as permanently missing in checkhealth. Correct handling is `vim.treesitter.language.register("json", "jsonc")`; verified working, the `json` parser highlights a `.jsonc` buffer with comments.

## Proposed solution

Four pieces. The design principle is that **the profile declarations are already the manifest** — `nodezero.treesitter.declared` is populated at config load, so the installer derives its work list from the active profiles with no second list to maintain.

### A. `lua/nodezero/treesitter/sources.lua` — vendored, pinned registry

A committed table, `lang -> { url, revision, location, requires }`, trimmed to the languages our profiles declare plus their `requires` closure, alongside a single `queries_revision` pinning the nvim-treesitter commit that queries are taken from.

```lua
return {
  queries_revision = "85ec015f3be42a3c2c04648ff99d617d9609e5f0",
  parsers = {
    python = {
      url = "https://github.com/tree-sitter/tree-sitter-python",
      revision = "v0.25.0",
    },
    typescript = {
      url = "https://github.com/tree-sitter/tree-sitter-typescript",
      revision = "75b3874edb2dc714fb1fd77a32013d0f8699989f",
      location = "typescript",
      requires = { "ecma" },
    },
    ecma = { queries_only = true },
    -- ...
  },
}
```

Committing the pins rather than resolving them at runtime keeps installs reproducible and makes every version bump a reviewable diff — consistent with the org's practice of forking and pinning its plugins. It also means `git log` answers "when did the yaml parser change".

### B. `scripts/sync-treesitter-sources.lua` — regenerate the pins

Fetches nvim-treesitter `main`'s `lua/nvim-treesitter/parsers.lua`, computes the `requires` closure over the currently declared languages, and rewrites `sources.lua`. Run manually when you want newer grammars; the diff is the changelog. This is how the 24-entry table above was produced.

It should fail loudly on two conditions: a declared language absent from the upstream registry (the `jsonc` case), and a grammar whose entry sets `generate`/`generate_from_json` (would need the tree-sitter CLI, which we otherwise don't require).

### C. `lua/nodezero/treesitter/install.lua` — the installer

Install target is `vim.fn.stdpath("data") .. "/site"` — i.e. `~/.local/share/nvim/site/{parser,queries}/`. That directory is already on `runtimepath`, respects `NVIM_APPNAME`, and lives outside the git repo so build artifacts never land in version control.

Per language:

1. Skip if the manifest records it already installed at the pinned revision.
2. Download `<url>/archive/<revision>.tar.gz` with `curl`, cached by `(url, revision)`.
3. Extract the **whole** tarball; compile `<location>/src/parser.c` plus `scanner.c`/`scanner.cc` if present, selecting `cc` or `c++` accordingly, into `site/parser/<lang>.so`.
4. Fetch `runtime/queries/<lang>/*.scm` at `queries_revision` into `site/queries/<lang>/`.
5. Write `site/nodezero-treesitter.json` recording `lang -> { revision, queries_revision, built_at }`.

Use `vim.system()` so downloads and compiles run concurrently and off the UI thread, with a bounded worker pool. The 18s serial figure should drop substantially.

Commands:

| Command | Behaviour |
| --- | --- |
| `:NodeZeroTSInstall [lang...]` | Install missing parsers for the active profiles (or just the named ones) |
| `:NodeZeroTSUpdate [lang...]` | Rebuild where the manifest revision differs from the pin |
| `:NodeZeroTSClean` | Remove parsers/queries no longer declared by any profile |
| `make treesitter` | Headless `nvim -c NodeZeroTSInstall -c qa`, for fresh-machine setup and CI |

### D. Health and helper integration

Extend `lua/nodezero/treesitter/health.lua` to compare the manifest against `sources.lua` and report three states — installed and current, installed but stale, missing — each with the command that fixes it. Today it reports only present/absent.

Leave the `FileType` autocmd's silent degradation as-is by default. Auto-installing on file open means a surprise network fetch and compile mid-edit; make it an opt-in `auto_install = true` flag on `setup()` if wanted later.

## Tradeoffs and risks

- **A C compiler becomes a hard prerequisite.** Fine on this machine (Xcode CLT provides `/usr/bin/cc` and `c++`) and on any Linux box with `build-essential`. `install.lua` should check for `cc` up front and fail with a clear message rather than 24 confusing compile errors.
- **Network access at install time.** Bounded to explicit `:NodeZeroTSInstall` / `make treesitter` runs, never at startup.
- **Pins go stale silently.** Mitigated by the sync script and the stale-revision health report, but nothing forces an update. That's the deliberate trade for reproducibility.
- **Licensing.** Queries are copied from nvim-treesitter (**Apache-2.0**); grammars carry their own licences (mostly MIT). `sources.lua` should carry a provenance header, and the vendored queries an attribution note, to keep the org's supply-chain posture honest.
- **We take on maintenance nvim-treesitter would otherwise do.** ~250 lines of installer plus a generated table, against a plugin dependency the org has decided against. The build logic is simple and fully validated; the ongoing cost is re-running the sync script.
- **Not portable to Windows as written** (`cc`, `curl`, `tar`). Not a concern for this setup; worth stating.

## Recommended follow-ups, independent of this work

1. **Fix `jsonc` in the core profile** — drop it from `languages` and register `json` for the `jsonc` filetype instead. It can never resolve as declared.
2. **`typescriptreact` has no coverage** — `react`, `typescript` and `lwc` declare `typescript` but not `tsx`, so `.tsx` buffers get nothing. Carried over from the old config; adding `tsx` is a one-line change once installation works.
3. **`salesforce/config/lsp.lua:27` throws when `JAVA_HOME` is unset**, and the profile loader's `pcall` swallows it — the Apex LSP is silently not loading today.

## Appendix: pinned sources as validated

| Language | Repo | Revision | Location |
| --- | --- | --- | --- |
| apex | aheber/tree-sitter-sfapex | 27a3091a1a44 | apex |
| bash | tree-sitter/tree-sitter-bash | a06c2e4415e9 | |
| c_sharp | tree-sitter/tree-sitter-c-sharp | v0.23.5 | |
| css | tree-sitter/tree-sitter-css | dda5cfc5722c | |
| cue | eonpatapon/tree-sitter-cue | dd7b90e0770f | |
| diff | tree-sitter-grammars/tree-sitter-diff | 1a24d30d9b2b | |
| dtd | tree-sitter-grammars/tree-sitter-xml | 5000ae8f22d1 | dtd |
| hcl | tree-sitter-grammars/tree-sitter-hcl | 64ad62785d44 | |
| html | tree-sitter/tree-sitter-html | 73a3947324f6 | |
| javascript | tree-sitter/tree-sitter-javascript | 58404d8cf191 | |
| jinja | cathaysia/tree-sitter-jinja | c213d3745ccd | tree-sitter-jinja |
| jinja_inline | cathaysia/tree-sitter-jinja | c213d3745ccd | tree-sitter-jinja_inline |
| json | tree-sitter/tree-sitter-json | 001c28d7a298 | |
| json5 | Joakker/tree-sitter-json5 | 248b85645670 | |
| luadoc | tree-sitter-grammars/tree-sitter-luadoc | 873612aadd3f | |
| luap | tree-sitter-grammars/tree-sitter-luap | c134aaec6acf | |
| php | tree-sitter/tree-sitter-php | 3fda2fb95771 | php |
| php_only | tree-sitter/tree-sitter-php | 3fda2fb95771 | php_only |
| phpdoc | claytonrcarter/tree-sitter-phpdoc | 12d50307e6c0 | |
| python | tree-sitter/tree-sitter-python | v0.25.0 | |
| toml | tree-sitter-grammars/tree-sitter-toml | 64b56832c2cf | |
| typescript | tree-sitter/tree-sitter-typescript | 75b3874edb2d | typescript |
| xml | tree-sitter-grammars/tree-sitter-xml | 5000ae8f22d1 | xml |
| yaml | tree-sitter-grammars/tree-sitter-yaml | a1c4812a73ec | |

Queries-only (fetched, never built): `ecma`, `jsx`, `html_tags`.
Bundled with Neovim (never fetched): `c`, `lua`, `markdown`, `markdown_inline`, `vimdoc`.
