local M = {}
M.plugins = {}

local utils = require("nodezero.utils")
local profile_utils = require("nodezero.profiles.utils")
local profiles_path = nil
function M.setup()
  profiles_path = profile_utils.getProfilesPath()
  utils.updatePackagePath(profiles_path)
  M.loaded = {
    profiles = {},
    plugins = {},
  }
  return M
end

function M.load(overrides)
  if overrides == nil then
    overrides = {}
  end
  -- Step 1: Retrieve profiles to load from 'nodezero.profiles.profile-config'
  local profiles = {}
  local ok, profile_configs = pcall(require, "nodezero.profiles.profile-configs")
  -- Return early if no profiles to process
  if not ok or #profile_configs == 0 then
    return M
  end
  -- Step 2: Retrieve the repository base URL
  local base_repository_url = profile_utils.getBaseRepositoryURL()
  -- Step 3: Retrieve the profile path

  -- Step 4: Normalize the profile definitions
  profile_configs = profile_utils.normalizeProfileDefinitions(profile_configs)
  -- Step 5: Normalize the plugin dependencies

  -- Process each profile
  for _, profile_config in ipairs(profile_configs) do
    local profile_name = profile_config.spec.name
    local profile_path = profiles_path .. "/" .. profile_name
    local profile_repo_path = profile_config[1]
    local vcs_type = profile_config.spec.vcs

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
    utils.updatePackagePath(profiles_path .. "/" .. profile_name)
    local profile_to_add = require(profile_name)
    table.insert(profiles, profile_to_add)
  end
  -- Step 11: Merge plugins and set to M.plugins
  M.loaded.profiles = profile_utils.normalizePluginDependencies(profiles)
  M.loaded.plugins = profile_utils.mergePlugins(profiles)
  return M
end
return M
