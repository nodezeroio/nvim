local M = {}

M.plugin_dir = vim.fn.stdpath("data") .. "/plugins"

-- Simple function to ensure plugin is cloned and added to rtp
function M.ensure(spec)
  local plugin_path = M.plugin_dir .. "/" .. spec.name
  
  -- Clone if doesn't exist
  if vim.fn.isdirectory(plugin_path) == 0 then
    vim.notify("Installing " .. spec.name .. "...", vim.log.levels.INFO)
    
    local cmd = string.format("git clone --depth=1 %s %s", spec.url, plugin_path)
    local result = vim.fn.system(cmd)
    
    -- Check if clone was successful
    if vim.v.shell_error == 0 then
      vim.notify("✓ " .. spec.name .. " installed successfully", vim.log.levels.INFO)
    else
      vim.notify("✗ Failed to install " .. spec.name .. ": " .. result, vim.log.levels.ERROR)
      return false
    end
  end
  
  -- Add to runtimepath
  vim.opt.rtp:prepend(plugin_path)
  return true
end

return M

