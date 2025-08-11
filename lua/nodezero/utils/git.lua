local M = {}
function M.cloneRepo(repoDetails)
  -- Input validation
  if repoDetails == nil then
    error("repoDetails cannot be nil")
  end

  if type(repoDetails) ~= "table" then
    error("repoDetails must be a table")
  end

  -- Validate repo field
  if repoDetails.repo == nil then
    error("repo is required")
  end

  if type(repoDetails.repo) ~= "string" then
    error("repo must be a string")
  end

  if repoDetails.repo == "" then
    error("repo cannot be empty")
  end

  -- Validate path field
  if repoDetails.path == nil then
    error("path is required")
  end

  if type(repoDetails.path) ~= "string" then
    error("path must be a string")
  end

  if repoDetails.path == "" then
    error("path cannot be empty")
  end

  -- Validate optional branch field
  if repoDetails.branch ~= nil then
    if type(repoDetails.branch) ~= "string" then
      error("branch must be a string if provided")
    end
  end

  -- Validate optional pathToRepo field
  if repoDetails.pathToRepo ~= nil then
    if type(repoDetails.pathToRepo) ~= "string" then
      error("pathToRepo must be a string if provided")
    end
  end

  -- Determine the actual clone destination
  local clone_path = repoDetails.path .. (repoDetails.pathToRepo or "")

  -- Build git clone command
  local cmd = "git clone"

  -- Add branch option if specified and not empty
  if repoDetails.branch and repoDetails.branch ~= "" then
    cmd = cmd .. " -b " .. repoDetails.branch
  end

  -- Add repository URL
  cmd = cmd .. " " .. repoDetails.repo

  -- Add clone path (quote it if it contains spaces or special characters)
  if string.match(clone_path, "[%s@]") then
    cmd = cmd .. " '" .. clone_path .. "'"
  else
    cmd = cmd .. " " .. clone_path
  end

  -- Execute the git clone command
  vim.fn.system(cmd)

  -- Check if the command was successful
  if vim.v.shell_error == 0 then
    return true
  else
    return false
  end
end

-- Helper function to validate base repository URLs
function M.isValidBaseRepositoryURL(url)
  local patterns = {
    "^https?://[%w%.%-]+:?%d*/?$", -- HTTP/HTTPS with hostname
    "^git@[%w%.%-]+:?%d*/?$", -- SSH (git@hostname)
    "^ssh://[%w@%.%-]+:?%d*/?$", -- SSH protocol with hostname
    "^git://[%w%.%-]+:?%d*/?$", -- Git protocol with hostname
  }

  for _, pattern in ipairs(patterns) do
    if string.match(url, pattern) then
      return true
    end
  end

  return false
end

return M
