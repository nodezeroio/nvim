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
      local catppuccin = require(plugin.name)
      if opts then
        catppuccin.setup(opts)
      end
      catppuccin.load()
    end,
  },
}
