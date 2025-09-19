local M = {}

local utils = require("nodezero.utils")
local function loadProfilePlugins()
  local plugins = {}
  local env_profiles = vim.env.NODEZERO_NVIM_PROFILES
  if env_profiles then
    for profile in string.gmatch(env_profiles, "([^;]+)") do
      local success, profile_module = pcall(require, "nodezero.profiles." .. profile .. ".plugins")
      if success then
        table.insert(plugins, profile_module)
      end
    end
  end
  return plugins
end

local plugins = loadProfilePlugins()
M = utils.mergeTables(plugins)

return M
