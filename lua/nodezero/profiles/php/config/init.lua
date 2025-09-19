vim.lsp.config("phpactor", {
  cmd = { "phpactor", "language-server", "-vvv" },
  filetypes = { "php" },
  root_markers = { "composer.json" },
})
vim.lsp.enable("phpactor")
