local M = {}

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
return M
