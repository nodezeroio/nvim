local M = {
  plugins = {},
}

local function loadPlugins()
  local plugins = {}
  local env_profiles = vim.env.NODEZERO_NVIM_PROFILES
  if env_profiles then
    for profile in string.gmatch(env_profiles, "([^;]+)") do
      local profile_module = require("nodezero.profiles." .. profile)
      table.insert(plugins, profile_module.plugins)
    end
  end
  return plugins
end

local function mergePlugins(plugins)
  local utils = require("nodezero.utils")
  return utils.mergeTables(plugins)
end

local plugins = loadPlugins()
M.plugins = mergePlugins(plugins)

return M
