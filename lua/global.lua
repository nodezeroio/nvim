-- lua/utils/global.lua
local M = {}
-- Create the global NodeZeroVim object
_G.NodeZeroVim = {}

-- Core utility functions
NodeZeroVim.utils = require("nodezero.utils")
NodeZeroVim.profiles = {}

NodeZeroVim.profiles = require("nodezero.profiles")

-- Configuration and state
NodeZeroVim.config = {
  plugin_dir = vim.fn.stdpath("data") .. "/plugins",
  profiles = {},
}

-- Debug utilities
NodeZeroVim.debug = require("nodezero.debug")

-- Initialize the global object
function M.setup()
  -- Any additional initialization can go here
  NodeZeroVim.debug.log("NodeZeroVim global object initialized")
end

return M
