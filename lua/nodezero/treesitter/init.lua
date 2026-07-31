local M = {}

-- Languages declared by every profile loaded this session.
-- Shape: lang -> { filetypes = { "cs", ... } }
M.declared = {}

local augroup = vim.api.nvim_create_augroup("nodezero_treesitter", { clear = false })

--- Enable treesitter highlighting (and optionally folds) for a buffer.
--- Silently does nothing when no parser is installed for the language: Nvim
--- ships parsers for c, lua, markdown, markdown_inline, query, vim and vimdoc
--- only, and has no parser installer. See :checkhealth nodezero.treesitter.
---@param buf integer
---@param folds boolean
local function start(buf, folds)
  if vim.b[buf].nodezero_ts_started then
    return
  end

  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if not lang then
    return
  end

  -- Returns nil plus an error message rather than throwing when the parser is
  -- absent, so this doubles as the availability probe.
  if not vim.treesitter.language.add(lang) then
    return
  end

  if not pcall(vim.treesitter.start, buf, lang) then
    return
  end
  vim.b[buf].nodezero_ts_started = true

  if folds then
    vim.wo[0][0].foldmethod = "expr"
    vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
  end
end

--- Declare the treesitter languages a profile needs.
---
--- Called from a profile's config/treesitter.lua, e.g.
--- <pre>lua
---   require("nodezero.treesitter").setup({
---     languages = { "c_sharp" },
---     filetypes = { c_sharp = { "cs" } },
---   })
--- </pre>
---
---@param spec table
---  - languages (string[]) treesitter parser names
---  - filetypes (table<string, string[]>?) extra filetypes per language, for
---    when the filetype name differs from the parser name
---  - folds (boolean?) set a treesitter 'foldexpr' (default true)
function M.setup(spec)
  local languages = spec.languages or {}
  local filetypes = spec.filetypes or {}
  local folds = spec.folds ~= false

  for lang, fts in pairs(filetypes) do
    vim.treesitter.language.register(lang, fts)
  end

  local patterns = {}
  for _, lang in ipairs(languages) do
    -- Includes lang itself plus anything registered above, and anything another
    -- profile already registered for the same parser.
    local fts = vim.treesitter.language.get_filetypes(lang)
    M.declared[lang] = { filetypes = fts }
    vim.list_extend(patterns, fts)
  end

  if #patterns == 0 then
    return
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = NodeZeroVim.dedup(patterns),
    callback = function(ev)
      start(ev.buf, folds)
    end,
  })
end

return M
