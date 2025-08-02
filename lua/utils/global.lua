-- lua/utils/global.lua
local M = {}

-- Create the global ThomasVim object
_G.ThomasVim = {}

-- Core utility functions
ThomasVim.utils = {}

-- Configuration and state
ThomasVim.config = {
  plugin_dir = vim.fn.stdpath("data") .. "/plugins",
  profiles = {},
}

-- Debug utilities
ThomasVim.debug = {}

function ThomasVim.debug.inspect(obj, opts)
  print(vim.inspect(obj, opts))
end

function ThomasVim.debug.log(msg, level)
  local log_file = vim.fn.stdpath("log") .. "/thomas-vim.log"
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
-- function ThomasVim.profiles.get_active()
--   return ThomasVim.utils.get_active_profiles()
-- end
--
-- function ThomasVim.profiles.is_active(profile_name)
--   local active = ThomasVim.profiles.get_active()
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
  ThomasVim.debug.log("ThomasVim global object initialized")

  -- Store active profiles in config
  -- ThomasVim.config.profiles = ThomasVim.profiles.get_active()
end

return M
