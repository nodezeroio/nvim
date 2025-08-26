return {
  {
    "catppuccin/nvim",
    url = "git@github.com:nodezeroio/catppuccin-nvim.git",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "auto",
      background = {
        light = "latte",
        dark = "mocha",
      },
    },
    config = function(plugin, opts)
      local catppuccin = require("catppuccin")
      if opts then
        catppuccin.setup(opts)
      end
      catppuccin.load()
    end,
  },
  {
    "LazyVim/LazyVim",
    url = "git@github.com:nodezeroio/LazyVim.git",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
