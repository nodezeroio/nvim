local M = {}

M.fs = require("nodezero.utils.filesystem")
M.vcs = require("nodezero.utils.git")
M.debug = require("nodezero.debug")

function M.deepCopyTable(obj)
  if type(obj) ~= "table" then
    return obj
  end

  local copy = {}
  for key, value in pairs(obj) do
    copy[key] = M.deepCopyTable(value)
  end
  return copy
end

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
-- Replace the skeleton implementation in lua/nodezero/utils/init.lua

function M.getHooks()
  -- Check if custom hooks path is set and not empty/whitespace
  local custom_hooks_path = vim.env.NODEZERO_NVIM_HOOKS_PATH
  local use_custom_path = custom_hooks_path and custom_hooks_path ~= "" and not custom_hooks_path:match("^%s*$")

  local hooks_module_name

  if use_custom_path then
    -- Update package path for custom hooks location
    local ok, _ = pcall(M.updatePackagePath, custom_hooks_path)
    if not ok then
      -- If updatePackagePath fails, return empty table
      return {}
    end
    hooks_module_name = "hooks"
  else
    -- Use default hooks location
    hooks_module_name = "nodezero.hooks"
  end

  -- Attempt to load the hooks module
  local ok, hooks = pcall(require, hooks_module_name)

  if not ok then
    -- Module not found or error loading - return empty table
    return {}
  end

  -- Validate that hooks is a table, return empty table if not
  if type(hooks) ~= "table" then
    return {}
  end

  -- Return the hooks table (could be empty)
  return hooks
end

return M
