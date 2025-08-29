local M = {}

M.fs = require("nodezero.utils.filesystem")
M.vcs = require("nodezero.utils.git")
M.debug = require("nodezero.debug")

function M.mergeTables(...)
  local merged = {}
  local tables = { ... } -- Pack all arguments into a table

  for i = 1, #tables do
    local current_table = tables[i]
    for j = 1, #current_table do
      merged[#merged + 1] = current_table[j]
    end
  end

  return merged
end

return M
