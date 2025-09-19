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
        yaml = function(bufnr)
          local path = vim.api.nvim_buf_get_name(bufnr)
          if
            path:match("/playbooks/")
            or path:match("/roles/")
            or path:match("/group_vars/")
            or path:match("/host_vars/")
            or path:match("%.ansible%.ya?ml$")
          then
            return { "ansible-lint", "yamlfmt" }
          end
          return { "yamlfmt" }
        end,
      },
    },
  },
}
