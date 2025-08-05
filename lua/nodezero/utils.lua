local M = {}

function M.ensurePath(path, create)
  -- Validate input path
  if path == nil then
    error("Path cannot be nil or empty")
  end

  if path == "" then
    error("Path cannot be empty")
  end

  -- Expand the path to handle ~, environment variables, etc.
  local expanded_path = vim.fn.expand(path)

  -- Check if path exists (could be file or directory)
  local path_exists = vim.fn.isdirectory(expanded_path) == 1 or vim.fn.filereadable(expanded_path) == 1

  if path_exists then
    return true
  end

  -- Path doesn't exist
  -- If create is falsy (false, nil, or not provided), throw error
  if not create then
    error("Path does not exist: " .. expanded_path)
  end

  -- Attempt to create the directory
  local success = vim.fn.mkdir(expanded_path, "p")

  if success == 0 then
    -- mkdir failed, throw error
    error("Failed to create directory: " .. expanded_path)
  end

  return true
end

return M
