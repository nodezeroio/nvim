vim.filetype.add({
  extension = {
    jinja = "jinja",
    jinja2 = "jinja",
    j2 = "jinja",
    yaml = "yaml.ansible",
  },
})

vim.lsp.config("jinja_lsp", {
  name = "jinja_lsp",
  cmd = { "jinja-lsp" },
  filetypes = { "jinja" },
  root_markers = { "ansible.cfg" },
})

vim.lsp.config("ansible-language-server", {
  cmd = { "ansible-language-server", "--stdio" },
  settings = {
    ansible = {
      python = {
        interpreterPath = "python",
      },
      ansible = {
        path = "ansible",
      },
      executionEnvironment = {
        enabled = false,
      },
      validation = {
        enabled = true,
        lint = {
          enabled = true,
          path = "ansible-lint",
        },
      },
    },
  },
  filetypes = { "yaml.ansible" },
  root_markers = { "ansible.cfg", ".ansible-lint" },
})

vim.lsp.enable("jinja_lsp")
vim.lsp.enable("ansible-language-server")
