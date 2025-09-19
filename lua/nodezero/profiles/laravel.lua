return {
  plugins = {
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
    {
      -- helpers for mason
      "mason-org/mason-lspconfig.nvim",
      url = "git@github.com:nodezeroio/mason-lspconfig.nvim.git",
      dependencies = {
        {
          "mason-org/mason.nvim",
          url = "git@github.com:nodezeroio/mason.nvim.git",
        },
        {
          "neovim/nvim-lspconfig",
          url = "git@github.com:nodezeroio/nvim-lspconfig.git",
        },
      },
      opts = {
        ensure_installed = { "phpactor" },
      },
    },
  },
}
