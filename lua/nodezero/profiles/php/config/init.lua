vim.lsp.config("phpactor", {
  cmd = { "phpactor", "language-server", "-vvv" },
  root_markers = { "composer.json" },
})
vim.lsp.enable("phpactor")
