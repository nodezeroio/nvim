-- lua/utils/global.lua
local M = {}

local profileUtils = require("profiles.utils")
-- Create the global NodeZeroVim object
_G.NodeZeroVim = {}

-- Core utility functions
NodeZeroVim.utils = {}

function NodeZeroVim.utils.ensurePath(path, create)
  -- Validate input path
  if path == nil then
    error("Path cannot be nil or empty")
  end

  if path == "" then
    error("Path cannot be empty")
  end

  -- Expand the path to handle ~, environment variables, etc.
  local expanded_path = vim.fn.expand(path)

  -- Check if path exists (could be file or directory)
  local path_exists = vim.fn.isdirectory(expanded_path) == 1 or vim.fn.filereadable(expanded_path) == 1

  if path_exists then
    return true
  end

  -- Path doesn't exist
  -- If create is falsy (false, nil, or not provided), throw error
  if not create then
    error("Path does not exist: " .. expanded_path)
  end

  -- Attempt to create the directory
  local success = vim.fn.mkdir(expanded_path, "p")

  if success == 0 then
    -- mkdir failed, throw error
    error("Failed to create directory: " .. expanded_path)
  end

  return true
end
NodeZeroVim.utils.profiles = profileUtils
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

-- Initialize the global object
function M.setup()
  -- Any additional initialization can go here
  NodeZeroVim.debug.log("NodeZeroVim global object initialized")
end

return M
