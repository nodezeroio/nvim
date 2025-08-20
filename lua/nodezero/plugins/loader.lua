local M = {}

local utils = require("nodezero.utils")
local plugin_utils = require("nodezero.plugins.utils")
function M.setup(plugins, hooks)
  if not plugins then
    plugins = {}
  end
  if not hooks then
    hooks = {}
  end

  -- Input validation
  -- Step 1: Ensure plugin directory exists
  local plugins_directory = plugin_utils.getPluginsDirectory()
  utils.fs.ensurePath(plugins_directory, true)
  -- Step 2-5: Process each plugin
  for _, plugin_def in ipairs(plugins) do
    -- Skip invalid plugin definitions
    if not plugin_utils.isValidPluginDefinition(plugin_def) then
      goto continue_plugin
    end
    local plugin_key = plugin_def[1]
    local plugin_name = plugin_utils.getPluginName(plugin_def)
    local plugin_path = plugins_directory .. "/" .. plugin_name
    -- Step 2: Check if plugin exists
    local plugin_exists = vim.fn.isdirectory(plugin_path) == 1
    -- Step 3: Clone if needed
    if not plugin_exists then
      local repo_url = plugin_utils.getRepositoryURL(plugin_def)

      -- Show notification during installation
      vim.notify("Installing plugin: " .. plugin_key)

      local clone_success = utils.vcs.cloneRepo({
        repo = repo_url,
        path = plugin_path,
      })

      if not clone_success then
        error(string.format("Failed to clone plugin %s", plugin_key))
      end
    end

    -- Step 4: Add to runtime path
    utils.updatePackagePath(plugin_path)
    print("PLUGIN KEY: " .. plugin_key)
    -- Step 5: Load the plugin with hooks
    M.loadPluginWithHooks(plugin_def, hooks[plugin_key])

    ::continue_plugin::
  end

  return M
end

function M.loadPluginWithHooks(plugin_def, plugin_hooks)
  print("PLUGIN HOOKS: " .. vim.inspect(plugin_hooks))
  if not plugin_hooks then
    plugin_hooks = {}
  end

  local plugin_key = plugin_def[1]
  local plugin_name = plugin_utils.getPluginName(plugin_def)

  -- Step 5.1: Call preSetup hook
  if plugin_hooks.preSetup then
    local ok, err = pcall(plugin_hooks.preSetup, plugin_def)
    if not ok then
      utils.debug.log(string.format("Error in preSetup hook for %s: %s", plugin_key, err), "ERROR")
    end
  end
  -- Step 5.2: Call config hook or default setup
  if plugin_hooks.config then
    local ok, err = pcall(plugin_hooks.config, plugin_def)
    if not ok then
      utils.debug.log(string.format("Error in config hook for %s: %s", plugin_key, err), "ERROR")
    end
  else
    -- Default setup: require(plugin_name).setup(options)
    print("PLUGIN NAME: " .. vim.inspect(plugin_name))
    local ok, plugin_module = pcall(require, plugin_name)
    print("OK: " ..  vim.inspect(ok))
--    print("MODULE: " .. vim.inspect(plugin_module))
    if ok and plugin_module and type(plugin_module.setup) == "function" then
      print("OPTIONS: " .. vim.inspect(plugin_def.options))
      plugin_module.setup(plugin_def.options)
      -- if not setup_ok then
      --   utils.debug.log(string.format("Error in default setup for %s: %s", plugin_key, setup_err), "ERROR")
      -- end
    else
      -- Plugin module not found or doesn't have setup function
      -- This is not necessarily an error, some plugins don't require setup
      if not ok then
        utils.debug.log(string.format("Plugin module %s not found, skipping setup", plugin_name), "WARN")
      end
    end
  end

  -- Step 5.3: Call postSetup hook
  if plugin_hooks.postSetup then
    local ok, err = pcall(plugin_hooks.postSetup, plugin_def)
    if not ok then
      utils.debug.log(string.format("Error in postSetup hook for %s: %s", plugin_key, err), "ERROR")
    end
  end
end

return M
