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
  -- sort profiles first by profile.spec.priority, then lexigraphic order based on profile.spec.name if set, else by profile[1]
end

return M
