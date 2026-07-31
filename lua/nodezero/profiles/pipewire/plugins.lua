return {
  {
    "stevearc/conform.nvim",
    url = "git@github.com:nodezeroio/conform.nvim.git",
    opts = {
      log_level = vim.log.levels.DEBUG,
      formatters_by_ft = {
        ["yaml.ansible"] = { "ansible-lint", "yamlfmt" },
      },
    },
  },
}
