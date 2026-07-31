return {
  {
    "mfussenegger/nvim-lint",
    url = "git@github.com:nodezeroio/nvim-lint.git",
    opts = {
      linters_by_ft = {
        ts = { "biome" },
        js = { "biome" },
        jsx = { "biome" },
        tsx = { "biome" },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    url = "git@github.com:nodezeroio/conform.nvim.git",
    opts = {
      formatters_by_ft = {
        js = { "biome" },
        ts = { "biome" },
        tsx = { "biome" },
        jsx = { "biome" },
      },
    },
  },
}
