local M = {}

M.spec = {
  url = "https://github.com/thomasbellio/catppuccin-nvim",
  name = "catppuccin"
}

M.config = {
  flavour = "mocha",
  background = {
    light = "latte",
    dark = "mocha",
  },
  integrations = {
    treesitter = true,
    telescope = true,
  }
}

function M.setup(user_config)
  local config = vim.tbl_deep_extend("force", M.config, user_config or {})
  
  -- Now we can just require normally!
  require("catppuccin").setup(config)
  vim.cmd.colorscheme("catppuccin")
end

return M
