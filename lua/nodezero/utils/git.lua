local M = {}

function M.cloneRepo(repo, basePath, repoPath, branch) end


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
