local M = {}

local plugins = {
  "colorscheme",
}

function M.setup()
  local plugin_manager = require("utils.plugin-manager")
  
  for _, name in ipairs(plugins) do
    local plugin = require("plugins.core." .. name)
    
    -- Ensure plugin is available
    plugin_manager.ensure(plugin.spec)
    
    -- Setup plugin
    plugin.setup()
  end
end

return M

