vim.notify("I am configuring the jinja-lsp")

vim.filetype.add({
  extension = {
    jinja = "jinja",
    jinja2 = "jinja",
    j2 = "jinja",
  },
})

vim.lsp.config("jinja_lsp", {
  name = "jinja_lsp",
  cmd = { "jinja-lsp" },
  filetypes = { "jinja" },
  root_markers = { "ansible.cfg" },
})
vim.lsp.enable("jinja_lsp")

vim.notify("got clients: " .. vim.inspect(vim.lsp.get_clients()))
