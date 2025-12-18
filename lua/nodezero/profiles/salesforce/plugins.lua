return {
  {
    "nvim-treesitter/nvim-treesitter",
    url = "git@github.com:nodezeroio/nvim-treesitter.git",
    opts = {
      ensure_installed = {
        "apex",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    url = "git@github.com:nodezeroio/conform.nvim.git",
    opts = {
      log_level = vim.log.levels.DEBUG,
      formatters_by_ft = {
        apex = { "prettier" },
      },
    },
  },
}
