return {
  {
    -- helpers for mason
    "mason-org/mason-lspconfig.nvim",
    url = "git@github.com:nodezeroio/mason-lspconfig.nvim.git",
    opts = {
      ensure_installed = { "lua_ls" },
    },
  },
  {
    "folke/lazydev.nvim", -- configures the lua language server luals (https://luals.github.io/)
    url = "git@github.com:nodezeroio/lazydev.nvim.git",
  },
  {
    "stevearc/conform.nvim",
    url = "git@github.com:nodezeroio/conform.nvim.git",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },
  {
    -- auto completion
    "saghen/blink.cmp",
    url = "git@github.com:nodezeroio/blink.cmp",
    opts = {
      sources = {
        -- add lazydev to your completion providers
        default = { "lazydev" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
    },
  },
}
