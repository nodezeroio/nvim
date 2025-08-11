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

-- Will resolve dependencies and other items on plugins for profiles
function M.normalizePluginDependencies(profiles) end

-- Implementation for the mergePlugins function
-- Add this to lua/nodezero/profiles/utils.lua replacing the existing stub
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
