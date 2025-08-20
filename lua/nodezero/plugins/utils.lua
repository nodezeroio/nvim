local M = {}

function M.getPluginsDirectory()
  -- Check for custom plugin directory
  local custom_dir = vim.env.NODEZERO_NVIM_PLUGINS_DIRECTORY
  if custom_dir and custom_dir ~= "" then
    return vim.fn.expand(custom_dir)
  end

  -- Default plugin directory
  return vim.fn.expand("$XDG_DATA_HOME/nodezero.nvim/plugins")
end

function M.isValidPluginDefinition(plugin_def)
  return type(plugin_def) == "table" and plugin_def[1] and type(plugin_def[1]) == "string" and plugin_def[1] ~= ""
end

function M.getPluginName(plugin_def)
  -- Use spec.name if provided
  if plugin_def.spec and plugin_def.spec.name then
    return plugin_def.spec.name
  end

  -- Normalize plugin path by replacing '/' with '-'
  local plugin_path = plugin_def[1]
  local plugin_name = string.gsub(plugin_path, "/", "-")
  if not plugin_def.spec then
    plugin_def.spec = {}
  end
  plugin_def.spec.name = plugin_name
  return plugin_name
end

function M.getRepositoryURL(plugin_def)
  -- Use custom URL if provided in spec
  if plugin_def.spec and plugin_def.spec.url then
    return plugin_def.spec.url
  end

  -- Default to GitHub
  return "https://github.com/" .. plugin_def[1]
end

return M
