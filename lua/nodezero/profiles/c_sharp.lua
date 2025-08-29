return {
  plugins = {
    {
      "stevearc/conform.nvim",
      url = "git@github.com:nodezeroio/conform.nvim.git",
      opts = {
        formatters_by_ft = {
          cs = { "csharpier" },
        },
      },
    },
    {
      "nvim-treesitter/nvim-treesitter",
      url = "git@github.com:nodezeroio/nvim-treesitter.git",
      opts = {
        ensure_installed = {
          "c_sharp",
        },
      },
    },
  },
}
