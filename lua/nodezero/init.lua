
local M = {}

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



