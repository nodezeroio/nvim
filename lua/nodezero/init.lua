local M = {}

M.config = require("nodezero.config")

function M.root_dir()
  local args = vim.fn.argv()
  if #args > 0 then
    local first_arg = args[1]
    local expanded = vim.fn.expand(first_arg)
    local full_path = vim.fn.fnamemodify(expanded, ":p")
    if vim.fn.isdirectory(full_path) == 1 then
      return full_path
    else
      return vim.fn.fnamemodify(full_path, ":h")
    end
  else
    return vim.fn.getcwd()
  end
end
function M.dedup(tbl)
  local seen = {}
  local result = {}
  for _, value in ipairs(tbl) do
    if not seen[value] then
      table.insert(result, value)
      seen[value] = true
    end
  end
  return result
end

_G.NodeZeroVim = M
return M
