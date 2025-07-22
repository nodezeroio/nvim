-- lua/loader.lua
local M = {}

-- Set stdpath('data') to ~/.local/share/thomas.nvim
vim.env.XDG_DATA_HOME = vim.env.HOME .. "/.local/share"
local plugin_dir = vim.fn.stdpath("data") .. "/thomas.nvim/plugins"

-- Function to require all modules in a directory
local function require_all_in(dir)
  local path = "plugins." .. dir
  local ok, files = pcall(vim.fn.readdir, vim.fn.stdpath("config") .. "/lua/plugins/" .. dir)
  if not ok then return end
  for _, file in ipairs(files) do
    if file:match("%.lua$") then
      local mod = path .. "." .. file:gsub("%.lua$", "")
      pcall(require, mod)
    end
  end
end

-- Load core plugins
function M.load_core()
  require_all_in("core")
end

-- Load profile-specific plugins
function M.load_profiles()
  local profiles_str = vim.env.NVIM_PROFILES or ""
  for profile in string.gmatch(profiles_str, "([^;]+)") do
    local mod = "plugins.profiles." .. profile
    pcall(require, mod)
  end
end

-- Public function to load all plugins
function M.load_plugins()
  M.load_core()
  M.load_profiles()
end

return M

