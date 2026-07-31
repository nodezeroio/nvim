local M = {}

local treesitter = require("nodezero.treesitter")

--- Report which of the declared treesitter parsers are actually installed.
---
--- Nvim bundles parsers for c, lua, markdown, markdown_inline, query, vim and
--- vimdoc only, and has no parser installer (see :help treesitter-parsers).
--- Anything else has to be placed on 'runtimepath' as parser/<lang>.so, with
--- matching queries, before highlighting can turn on.
function M.check()
  vim.health.start("nodezero.treesitter")

  local languages = vim.tbl_keys(treesitter.declared)
  if #languages == 0 then
    vim.health.info("No treesitter languages declared. Is NODEZERO_NVIM_PROFILES set?")
    return
  end
  table.sort(languages)

  local missing = 0
  for _, lang in ipairs(languages) do
    local filetypes = table.concat(treesitter.declared[lang].filetypes, ", ")
    local ok, err = vim.treesitter.language.add(lang)
    if ok then
      vim.health.ok(string.format("%s (filetypes: %s)", lang, filetypes))
    else
      missing = missing + 1
      vim.health.warn(string.format("%s (filetypes: %s): %s", lang, filetypes, err or "parser not found"))
    end
  end

  if missing > 0 then
    vim.health.info(
      string.format(
        "%d of %d parsers are missing. Install them as parser/<lang>.so on 'runtimepath' "
          .. "(with queries/<lang>/highlights.scm) to enable highlighting.",
        missing,
        #languages
      )
    )
  end
end

return M
