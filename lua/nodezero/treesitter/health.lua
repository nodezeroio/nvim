local M = {}

local treesitter = require("nodezero.treesitter")

--- Report the treesitter parsers declared by the active profiles against what
--- is actually installed under stdpath("data")/site.
---
--- Nvim bundles parsers for c, lua, markdown, markdown_inline, query, vim and
--- vimdoc only, and has no parser installer (see :help treesitter-parsers).
--- Everything else is built by :NodeZeroTSInstall from the pins in
--- lua/nodezero/treesitter/sources.lua.
function M.check()
  vim.health.start("nodezero.treesitter")

  local declared = vim.tbl_keys(treesitter.declared)
  if #declared == 0 then
    vim.health.info("No treesitter languages declared. Is NODEZERO_NVIM_PROFILES set?")
    return
  end
  table.sort(declared)
  vim.health.info(("%d languages declared by the active profiles"):format(#declared))

  if vim.fn.executable("cc") == 1 then
    vim.health.ok("C compiler found (`cc`)")
  else
    vim.health.error("No C compiler on PATH. `cc` is required to build parsers.")
  end

  local install = require("nodezero.treesitter.install")
  local _, unknown = install.targets()
  if #unknown > 0 then
    vim.health.error(
      "Declared but absent from sources.lua: " .. table.concat(unknown, ", "),
      { "Run `make treesitter-sync`, or drop them from the profile." }
    )
  end

  local status = install.status()
  local languages = vim.tbl_keys(status)
  table.sort(languages)

  local counts = { current = 0, stale = 0, missing = 0 }
  for _, lang in ipairs(languages) do
    local info = status[lang]
    counts[info.state] = counts[info.state] + 1

    local filetypes = treesitter.declared[lang] and table.concat(treesitter.declared[lang].filetypes, ", ")
    local label = filetypes and ("%s (filetypes: %s)"):format(lang, filetypes) or lang
    if info.queries_only then
      label = label .. " [queries only]"
    end

    if info.state == "current" then
      vim.health.ok(label)
    elseif info.state == "stale" then
      vim.health.warn(label .. ": pinned revision moved to " .. tostring(info.revision):sub(1, 12))
    else
      vim.health.warn(label .. ": not installed")
    end
  end

  if counts.missing > 0 then
    vim.health.info(("%d missing. Run :NodeZeroTSInstall"):format(counts.missing))
  end
  if counts.stale > 0 then
    vim.health.info(("%d out of date. Run :NodeZeroTSUpdate"):format(counts.stale))
  end
  if counts.missing == 0 and counts.stale == 0 then
    vim.health.ok(("All %d parsers installed and current"):format(counts.current))
  end
end

return M
