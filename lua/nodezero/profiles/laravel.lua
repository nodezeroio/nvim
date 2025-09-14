return {
  plugins = {
    {
      "mfussenegger/nvim-lint",
      url = "git@github.com:nodezeroio/nvim-lint.git",
      opts = {
        linters_by_ft = {
          php = { "pint" },
        },
      },
    },
    {
      "stevearc/conform.nvim",
      url = "git@github.com:nodezeroio/conform.nvim.git",
      opts = {
        formatters_by_ft = {
          php = { "pint" },
        },
      },
    },
    {
      "nvim-treesitter/nvim-treesitter",
      url = "git@github.com:nodezeroio/nvim-treesitter.git",
      opts = {
        ensure_installed = {
          "php",
          "phpdoc",
        },
      },
    },
  },
}
