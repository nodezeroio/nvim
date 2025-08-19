local M = {}

M.fs = require("nodezero.utils.filesystem")
M.vcs = require("nodezero.utils.git")
M.debug = require("nodezero.debug")

function M.updatePackagePath(path)
  -- Add profiles path to Lua's package path
  local lua_path = path .. "/?.lua"
  local init_path = path .. "/?/init.lua"

  if not package.path:find(lua_path, 1, true) then
    package.path = package.path .. ";" .. lua_path
  end

  if not package.path:find(init_path, 1, true) then
    package.path = package.path .. ";" .. init_path
  end
  return M
end

function M.getHooks()

end

return M
