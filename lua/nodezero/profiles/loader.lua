local M = {}
M.loaded = {}

local profile_utils = require("nodezero.profiles.utils")
local profiles_path = nil
function M.setup()
  profiles_path = profile_utils.getProfilesPath()
  -- Add profiles path to Lua's package path
  local lua_path = profiles_path .. "/?.lua"
  local init_path = profiles_path .. "/?/init.lua"

  if not package.path:find(lua_path, 1, true) then
    package.path = package.path .. ";" .. lua_path
  end

  if not package.path:find(init_path, 1, true) then
    package.path = package.path .. ";" .. init_path
  end
  return M
end
function M.load()
  -- Step 1: Retrieve profiles to load from 'nodezero.profiles.profile-config'
  local profiles = {}
  local ok, profile_config = pcall(require, "nodezero.profiles.profile-config")
  if ok and profile_config then
    profiles = profile_config
  end
  -- Return early if no profiles to process
  if not profiles or #profiles == 0 then
    M.loaded = {}
    return M
  end

  -- Step 2: Retrieve the repository base URL
  local base_repository_url = profile_utils.getBaseRepositoryURL()
  -- Step 3: Retrieve the profile path

  -- Step 4: Normalize the profile definitions
  profiles = profile_utils.normalizeProfileDefinitions(profiles)

  -- Step 5: Normalize the plugin dependencies
  profiles = profile_utils.normalizePluginDependencies(profiles)

  -- Step 6: Retrieve the overrides from 'nodezero.overrides', if it exists
  local overrides = {}
  local ok_overrides, override_config = pcall(require, "nodezero.overrides")
  if ok_overrides and override_config then
    overrides = override_config
  end

  -- Get utility modules
  local utils = require("nodezero.utils")

  -- Process each profile
  for _, profile in ipairs(profiles) do
    local profile_name = profile.spec.name
    local profile_path = profiles_path .. "/" .. profile_name
    local profile_repo_path = profile[1]
    local vcs_type = profile.spec.vcs

    -- Validate VCS type
    if vcs_type ~= nil and vcs_type ~= "git" and vcs_type ~= "file" then
      error(
        string.format(
          "Invalid VCS type '%s' for profile %s. Must be nil, 'git', or 'file'",
          vcs_type,
          profile_repo_path
        )
      )
    end

    -- Step 7: Check if the profile already exists
    local path_exists = false
    local path_exists_ok, path_exists_err = pcall(utils.fs.ensurePath, profile_path, false)
    if path_exists_ok then
      path_exists = true
    else
      -- If vcs is 'file', throw error when path doesn't exist
      if vcs_type == "file" then
        error(path_exists_err)
      end
    end

    -- Step 8: Clone profile if needed and VCS is git (or nil, which defaults to git)
    if not path_exists and (vcs_type == nil or vcs_type == "git") then
      -- Determine repository URL (with override if available)
      local repo_path = overrides[profile_repo_path] or profile_repo_path
      local repo_url = base_repository_url .. repo_path

      -- Clone the repository
      local clone_success = utils.vcs.cloneRepo({
        repo = repo_url,
        path = profile_path,
      })

      if not clone_success then
        error(string.format("Failed to clone profile %s", profile_repo_path))
      end
    end

    -- Step 9: Load profile config if it exists
    local config_module_name = profile_name .. ".config"
    local config_ok, config_err = pcall(require, config_module_name) -- luacheck: ignore config_err
    if not config_ok then -- luacheck: ignore 542
      -- Config loading failed or doesn't exist - continue silently
    end
    -- Step 10: Load profile plugins if they exist
    local plugins_module_name = profile_name .. ".plugins"
    local plugins_ok, profile_plugins = pcall(require, plugins_module_name)
    if plugins_ok and profile_plugins then
      profile.plugins = profile_plugins
    end
  end

  -- Step 11: Merge plugins and set to M.loaded
  M.loaded = profile_utils.mergePlugins(profiles)

  -- Step 12: Return M
  return M
end
return M
