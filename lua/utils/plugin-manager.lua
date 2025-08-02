-- lua/utils/plugin-manager.lua
local M = {}

M.plugin_dir = vim.fn.stdpath("data") .. "/plugins"

local function normalize_plugin_spec(plugin_def)
  -- If the first element is a string, it's the plugin identifier (LazyVim style)
  if type(plugin_def[1]) == "string" then
    if not plugin_def.spec then
        plugin_def.spec = {}
    end
    plugin_def.spec.plugin = plugin_def[1]
    if not plugin_def.spec.name then
      plugin_def.spec.name = plugin_def.spec.plugin:match("([^/]+)$") -- Extract repo name from "owner/repo"
    end
  else
    error("Invalid plugin definition: missing plugin identifier")
  end
end
-- Function to resolve plugin URL based on spec and environment variables
local function resolve_plugin_url(spec)
  -- If URL is explicitly provided, use it
  if spec.url then
    return spec.url
  end

  local overrides = {}
  local ok, override_module = pcall(require, "profiles.overrides")
  if ok then
    overrides = override_module
  end
  -- Get the default repository from environment variable
  local default_repo = vim.env.NVIM_DEFAULT_PLUGIN_REPOSITORY

  -- If default repo is set, use it
  if default_repo then
    -- Remove trailing slash if present
    default_repo = default_repo:gsub("/$", "")
    return default_repo .. "/" .. (overrides[spec.plugin] or spec.plugin)
  end

  -- Fallback to GitHub
  return "https://github.com/" ..  (overrides[spec.plugin] or spec.plugin)
end

-- Simple function to ensure plugin is cloned and added to rtp
function M.ensure(spec)
  -- Validate required fields
  if not spec.plugin then
    vim.notify("✗ Plugin spec missing required 'plugin' field", vim.log.levels.ERROR)
    return false
  end

  if not spec.name then
    vim.notify("✗ Plugin spec missing required 'name' field", vim.log.levels.ERROR)
    return false
  end

  local plugin_path = M.plugin_dir .. "/" .. spec.name
  local plugin_url = resolve_plugin_url(spec)

  -- Clone if doesn't exist
  if vim.fn.isdirectory(plugin_path) == 0 then
    vim.notify("Installing " .. spec.plugin .. "...", vim.log.levels.INFO)

    local cmd = string.format("git clone --depth=1 %s %s", plugin_url, plugin_path)
    local result = vim.fn.system(cmd)

    -- Check if clone was successful
    if vim.v.shell_error == 0 then
      vim.notify("✓ " .. spec.plugin .. " installed successfully", vim.log.levels.INFO)
    else
      vim.notify("✗ Failed to install " .. spec.plugin .. " from " .. plugin_url .. ": " .. result, vim.log.levels.ERROR)
      return false
    end
  end

  -- Add to runtimepath
  vim.opt.rtp:prepend(plugin_path)
  return true
end

-- Enhanced setup function that handles configuration merging and hooks
function M.setup(plugin_def)
  local options = plugin_def.options
  -- Execute pre-setup hook if it exists
  if plugin_def.preSetup then
    plugin_def.preSetup(plugin_def)
  end

  -- Call the main plugin setup if specified
  if plugin_def.config and type(plugin_def.config) == "function" then
     plugin_def.config(plugin_def)
  elseif plugin_def.name then
      -- String format: require the module and call setup
      require(plugin_def.name).setup(options)
  end

  -- Execute post-setup hook if it exists
  if plugin_def.postSetup then
    plugin_def.postSetup(plugin_def)
  end
end

-- Convenience function that ensures plugin and sets it up in one call
function M.ensure_and_setup(plugin_def)
  -- Normalize the plugin definition to extract spec
  normalize_plugin_spec(plugin_def)
  if M.ensure(plugin_def.spec) then
    M.setup(plugin_def)
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
