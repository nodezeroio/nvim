-- lua/utils/global.lua
local M = {}

-- Create the global NodeZeroVim object
_G.NodeZeroVim = {}

-- Core utility functions
NodeZeroVim.utils = {}

-- Configuration and state
NodeZeroVim.config = {
  plugin_dir = vim.fn.stdpath("data") .. "/plugins",
  profiles = {},
}

-- Debug utilities
NodeZeroVim.debug = {}

function NodeZeroVim.debug.inspect(obj, opts)
  print(vim.inspect(obj, opts))
end

function NodeZeroVim.debug.log(msg, level)
  local log_file = vim.fn.stdpath("log") .. "/nodezero-vim.log"
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local log_level = level or "INFO"
  local log_msg = string.format("[%s] [%s] %s\n", timestamp, log_level, msg)

  local file = io.open(log_file, "a")
  if file then
    file:write(log_msg)
    file:close()
  end
end

-- -- Profile management
-- function NodeZeroVim.profiles.get_active()
--   return NodeZeroVim.utils.get_active_profiles()
-- end
--
-- function NodeZeroVim.profiles.is_active(profile_name)
--   local active = NodeZeroVim.profiles.get_active()
--   for _, profile in ipairs(active) do
--     if profile == profile_name then
--       return true
--     end
--   end
--   return false
-- end

-- Initialize the global object
function M.setup()
  -- Any additional initialization can go here
  NodeZeroVim.debug.log("NodeZeroVim global object initialized")

  -- Store active profiles in config
  -- NodeZeroVim.config.profiles = NodeZeroVim.profiles.get_active()
end

return M
