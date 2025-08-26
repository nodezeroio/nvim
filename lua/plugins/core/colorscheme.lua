return {
  {
    "catppuccin/nvim",
    url = "https://github.com/thomasbellio/catppuccin-nvim.git",
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
}
