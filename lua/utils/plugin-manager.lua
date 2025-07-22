-- lua/utils/plugin-manager.lua
local M = {}

M.plugin_dir = vim.fn.stdpath("data") .. "/plugins"

-- Simple function to ensure plugin is cloned and added to rtp
function M.ensure(spec)
  local plugin_path = M.plugin_dir .. "/" .. spec.name

  -- Clone if doesn't exist
  if vim.fn.isdirectory(plugin_path) == 0 then
    vim.notify("Installing " .. spec.name .. "...", vim.log.levels.INFO)

    local cmd = string.format("git clone --depth=1 %s %s", spec.url, plugin_path)
    local result = vim.fn.system(cmd)

    -- Check if clone was successful
    if vim.v.shell_error == 0 then
      vim.notify("✓ " .. spec.name .. " installed successfully", vim.log.levels.INFO)
    else
      vim.notify("✗ Failed to install " .. spec.name .. ": " .. result, vim.log.levels.ERROR)
      return false
    end
  end

  -- Add to runtimepath
  vim.opt.rtp:prepend(plugin_path)
  return true
end

-- Enhanced setup function that handles configuration merging and hooks
function M.setup(plugin_def, user_config)
  local config = {}

  -- Merge default config with user config if both exist
  if plugin_def.config then
    config = vim.tbl_deep_extend("force", plugin_def.config, user_config or {})
  elseif user_config then
    config = user_config
  end

  -- Execute pre-setup hook if it exists
  if plugin_def.preSetup then
    plugin_def.preSetup(config)
  end

  -- Call the main plugin setup if specified
  if plugin_def.name then
      require(plugin_def.name).setup(config)
  end

  -- Execute post-setup hook if it exists
  if plugin_def.postSetup then
    plugin_def.postSetup(config)
  end
end

-- Convenience function that ensures plugin and sets it up in one call
function M.ensure_and_setup(plugin_def, user_config)
  if M.ensure(plugin_def.spec) then
    M.setup(plugin_def, user_config)
    return true
  end
  return false
end

-- Helper function to create an extend function that works with the table-return pattern
function M.create_extend_function(plugin_def)
  return function(extension)
    plugin_def.config = vim.tbl_deep_extend("force", plugin_def.config, extension)
  end
end

return M
