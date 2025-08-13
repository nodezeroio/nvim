local M = {}

local utils = require("nodezero.utils")

-- Helper function to deep copy any table/value
local function deep_copy_table(obj)
  if type(obj) ~= "table" then
    return obj
  end

  local copy = {}
  for key, value in pairs(obj) do
    copy[key] = deep_copy_table(value)
  end

  return copy
end

-- Helper function to deep copy a plugin definition
local function deep_copy_plugin(plugin)
  if type(plugin) ~= "table" then
    return plugin
  end

  local copy = {}
  for key, value in pairs(plugin) do
    copy[key] = deep_copy_table(value)
  end

  return copy
end

-- Helper function to merge two plugin definitions
-- higher_priority_plugin takes precedence over lower_priority_plugin
local function merge_plugin_definitions(higher_priority_plugin, lower_priority_plugin)
  local merged = deep_copy_plugin(lower_priority_plugin)

  -- Merge spec if both exist
  if higher_priority_plugin.spec and merged.spec then
    merged.spec = vim.tbl_deep_extend("force", merged.spec, higher_priority_plugin.spec)
  elseif higher_priority_plugin.spec then
    merged.spec = deep_copy_table(higher_priority_plugin.spec)
  end

  -- Merge options if both exist
  if higher_priority_plugin.options and merged.options then
    merged.options = vim.tbl_deep_extend("force", merged.options, higher_priority_plugin.options)
  elseif higher_priority_plugin.options then
    merged.options = deep_copy_table(higher_priority_plugin.options)
  end

  -- Copy any other fields from higher priority plugin
  for key, value in pairs(higher_priority_plugin) do
    if key ~= "spec" and key ~= "options" and key ~= 1 then
      merged[key] = deep_copy_table(value)
    end
  end

  return merged
end

function M.getBaseRepositoryURL()
  -- Get the environment variable
  local env_url = vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY
  -- Check if environment variable is not set or is empty/whitespace
  if not env_url or env_url == "" or env_url:match("^%s*$") then
    return "https://github.com/"
  end

  -- Validate the URL format
  if utils.vcs.isValidBaseRepositoryURL(env_url) then
    if string.sub(env_url, -1) ~= "/" then
      return env_url .. "/"
    end
    return env_url
  else
    -- Log warning and fallback to GitHub
    utils.debug.log(string.format("'%s' is not a valid base repository URL, falling back to github", env_url), "WARN")
    return "https://github.com/"
  end
end

function M.getProfilesPath()
  -- Check if the environment variable is set and not empty
  local env_path = vim.env.NODEZERO_NVIM_PROFILES_PATH

  if env_path and env_path ~= "" then
    -- Return the custom path from environment variable
    return env_path
  else
    -- Return the default path with proper expansion
    return vim.fn.expand("$XDG_DATA_HOME/nodezero.nvim/profiles")
  end
end

function M.sort(profiles)
  -- Create a shallow copy to avoid modifying the original array
  local sorted_profiles = {}
  for i, profile in ipairs(profiles) do
    sorted_profiles[i] = profile
  end

  -- Sort using table.sort with custom comparison function
  table.sort(sorted_profiles, function(a, b)
    -- Extract priority values, defaulting to nil if not set
    local priority_a = a.spec and a.spec.priority
    local priority_b = b.spec and b.spec.priority

    -- If both have priorities, compare them (higher priority comes first)
    if priority_a ~= nil and priority_b ~= nil then
      if priority_a ~= priority_b then
        return priority_a > priority_b
      end
      -- Priorities are equal, fall through to name comparison
    elseif priority_a ~= nil and priority_b == nil then
      -- A has priority, B doesn't - A comes first
      return true
    elseif priority_a == nil and priority_b ~= nil then
      -- B has priority, A doesn't - B comes first
      return false
    end
    -- Both have no priority, fall through to name comparison

    -- Extract spec.name values
    local name_a = a.spec and a.spec.name
    local name_b = b.spec and b.spec.name

    -- If both have spec.name, compare them alphabetically (case-insensitive)
    if name_a and name_b then
      local lower_a = string.lower(name_a)
      local lower_b = string.lower(name_b)
      if lower_a ~= lower_b then
        return lower_a < lower_b
      end
      -- Names are equal (case-insensitive), fall through to profile[1] comparison
    elseif name_a and not name_b then
      -- A has name, B doesn't - A comes first (in case of equal priorities)
      return true
    elseif not name_a and name_b then
      -- B has name, A doesn't - B comes first (in case of equal priorities)
      return false
    end
    -- Both have no spec.name, fall through to profile[1] comparison

    -- Fallback to profile[1] comparison (case-insensitive)
    local path_a = a[1] or ""
    local path_b = b[1] or ""
    local lower_path_a = string.lower(path_a)
    local lower_path_b = string.lower(path_b)

    return lower_path_a < lower_path_b
  end)

  return sorted_profiles
end
function M.normalizeProfileDefinitions(profiles)
  -- Handle empty profiles list
  if not profiles or #profiles == 0 then
    return {}
  end

  -- Create result array to hold normalized profiles
  local result = {}

  -- Process each profile
  for i, profile in ipairs(profiles) do
    -- Skip invalid profiles (must be a table with a valid string path)
    if type(profile) == "table" and profile[1] and type(profile[1]) == "string" then
      -- Deep copy the profile to avoid mutating the original
      local normalized_profile = deep_copy_table(profile)

      -- Ensure spec table exists
      if not normalized_profile.spec then
        normalized_profile.spec = {}
      elseif type(normalized_profile.spec) ~= "table" then
        -- Handle case where spec is not a table (e.g., nil)
        normalized_profile.spec = {}
      end

      -- Check if spec.name needs to be set
      if not normalized_profile.spec.name then
        -- Generate name from profile path by replacing '/' with '-'
        local profile_path = normalized_profile[1]
        normalized_profile.spec.name = string.gsub(profile_path, "/", "-")
      end

      -- Add the normalized profile to result
      table.insert(result, normalized_profile)
    end
    -- Invalid profiles are silently skipped
  end

  return result
end
-- Implementation for normalizePluginDependencies function
-- Add this to lua/nodezero/profiles/utils.lua replacing the existing stub

function M.normalizePluginDependencies(profiles)
  -- Handle empty profiles list
  if not profiles or #profiles == 0 then
    return {}
  end

  -- Deep copy profiles to avoid modifying original
  local result = {}
  for i, profile in ipairs(profiles) do
    result[i] = deep_copy_table(profile)
  end

  -- Process each profile independently
  for _, profile in ipairs(result) do
    -- Initialize plugins array if it doesn't exist or is nil
    if not profile.plugins then
      profile.plugins = {}
    end

    -- Skip profiles with no plugins
    if #profile.plugins == 0 then
      goto continue_profile
    end

    -- Track processed dependencies to avoid infinite loops in circular dependencies
    local processed_deps = {}

    -- Keep track of plugins to add (dependencies)
    local deps_to_add = {}

    -- Recursive function to resolve dependencies
    local function resolve_dependencies(plugin_list)
      for _, plugin_def in ipairs(plugin_list) do
        -- Validate plugin definition
        if not plugin_def or type(plugin_def) ~= "table" or not plugin_def[1] or type(plugin_def[1]) ~= "string" then
          goto continue_plugin
        end

        -- Process dependencies if they exist
        if plugin_def.dependencies and type(plugin_def.dependencies) == "table" then
          for _, dep_identifier in ipairs(plugin_def.dependencies) do
            -- Only process string dependencies
            if type(dep_identifier) == "string" and dep_identifier ~= "" then
              -- Skip if we've already processed this dependency (prevents infinite loops)
              if processed_deps[dep_identifier] then
                goto continue_dependency
              end

              -- Mark as processed
              processed_deps[dep_identifier] = true

              -- Check if dependency already exists in current profile
              local dependency_exists = false
              for _, existing_plugin in ipairs(profile.plugins) do
                if existing_plugin and existing_plugin[1] == dep_identifier then
                  dependency_exists = true
                  break
                end
              end

              -- If dependency doesn't exist, add it to the list of dependencies to add
              if not dependency_exists then
                -- Check if we've already queued this dependency
                local already_queued = false
                for _, queued_dep in ipairs(deps_to_add) do
                  if queued_dep[1] == dep_identifier then
                    already_queued = true
                    break
                  end
                end

                if not already_queued then
                  -- Create minimal plugin definition for dependency
                  local dep_plugin = { dep_identifier }
                  table.insert(deps_to_add, dep_plugin)
                end
              end

              ::continue_dependency::
            end
          end
        end

        ::continue_plugin::
      end
    end

    -- Initial pass: resolve dependencies from existing plugins
    resolve_dependencies(profile.plugins)

    -- Continue resolving until no new dependencies are found (handles nested dependencies)
    local previous_deps_count = 0
    while #deps_to_add > previous_deps_count do
      previous_deps_count = #deps_to_add

      -- Resolve dependencies of the newly added dependencies
      local current_deps_to_check = {}
      for i = previous_deps_count + 1, #deps_to_add do
        table.insert(current_deps_to_check, deps_to_add[i])
      end

      resolve_dependencies(current_deps_to_check)
    end

    -- Add all resolved dependencies to the end of the plugins list
    for _, dep_plugin in ipairs(deps_to_add) do
      table.insert(profile.plugins, dep_plugin)
    end

    ::continue_profile::
  end

  return result
end

-- Implementation for the mergePlugins function
function M.mergePlugins(profiles)
  -- Handle empty profiles list
  if not profiles or #profiles == 0 then
    return {}
  end

  -- Sort profiles using existing sort function
  local sorted_profiles = M.sort(profiles)

  -- Track plugins by their identifier (first string element)
  local plugin_map = {}
  local plugin_order = {} -- Track the order plugins were first encountered

  -- Process profiles in sorted order (highest priority first due to sort function)
  for _, profile in ipairs(sorted_profiles) do
    local plugins = profile.plugins

    -- Skip profiles with no plugins or nil plugins field
    if plugins and type(plugins) == "table" then
      for _, plugin_def in ipairs(plugins) do
        -- Validate plugin definition
        if plugin_def and plugin_def[1] and type(plugin_def[1]) == "string" then
          local plugin_id = plugin_def[1]

          if plugin_map[plugin_id] then
            -- Plugin already exists, merge with existing definition
            -- Since profiles are sorted by priority (highest first),
            -- we need to merge in reverse order: existing (higher priority) over new (lower priority)
            plugin_map[plugin_id] = merge_plugin_definitions(plugin_map[plugin_id], plugin_def)
          else
            -- New plugin, add to map and track order
            plugin_map[plugin_id] = deep_copy_plugin(plugin_def)
            table.insert(plugin_order, plugin_id)
          end
        end
      end
    end
  end

  -- Convert map back to array, preserving original encounter order
  local result = {}
  for _, plugin_id in ipairs(plugin_order) do
    table.insert(result, plugin_map[plugin_id])
  end

  return result
end
return M
