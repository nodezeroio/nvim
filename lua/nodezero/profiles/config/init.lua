local M = {}

local utils = require("nodezero.utils")
local function loadProfileConfigs()
  local plugins = {}
  local env_profiles = vim.env.NODEZERO_NVIM_PROFILES
  if env_profiles then
    for profile in string.gmatch(env_profiles, "([^;]+)") do
      pcall(require, "nodezero.profiles." .. profile .. ".config")
    end
  end
  return plugins
end

local plugins = loadProfileConfigs()
M = utils.mergeTables(plugins)

return M
