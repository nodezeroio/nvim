return {
  {
    "nvim-treesitter/nvim-treesitter",
    url = "git@github.com:nodezeroio/nvim-treesitter.git",
    opts = {
      ensure_installed = {
        "yaml",
        "jinja",
        "jinja_inline",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    url = "git@github.com:nodezeroio/conform.nvim.git",
    opts = {
      formatters_by_ft = {
        yaml.ansible = { "ansible-lint" }       
      },
    },
  },
}
