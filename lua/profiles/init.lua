-- lua/profiles/init.lua
local M = {}

local profiles = {
  "core",
}

function M.setup()
  local plugin_manager = require("utils.plugin-manager")

  for _, profile_name in ipairs(profiles) do
    local plugins_list = require("profiles." .. profile_name .. ".plugins")

    -- Check if plugins_list is actually a list or a single plugin
    if plugins_list[1] and type(plugins_list[1]) == "string" then
      -- This is a single plugin definition (backwards compatibility)
      plugin_manager.ensure_and_setup(plugins_list)
    else
      -- This is a list of plugins
      for _, plugin_def in ipairs(plugins_list) do
        plugin_manager.ensure_and_setup(plugin_def)
      end
    end
  end
end

return M
