-- lua/plugins/core/init.lua
local M = {}

local plugins = {
  "colorscheme",
}

function M.setup()
  local plugin_manager = require("utils.plugin-manager")
  for _, name in ipairs(plugins) do
    local plugin = require("plugins.core." .. name)

    -- Use the enhanced ensure_and_setup function
    plugin_manager.ensure_and_setup(plugin)
  end
end

return M
