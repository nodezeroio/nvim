-- lua/profiles/core/init.lua
local M = {}

local profiles = {
  "core",
}

function M.setup()
  local plugin_manager = require("utils.plugin-manager")
  for _, name in ipairs(profiles) do
    local plugin = require("profiles." .. name .. ".plugins")
    -- Use the enhanced ensure_and_setup function
    plugin_manager.ensure_and_setup(plugin)
  end
end

return M
