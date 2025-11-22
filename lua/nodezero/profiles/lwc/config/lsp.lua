vim.lsp.config("typescript-language-server", {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "typescript", "typescriptreact", "javascript" },
  root_markers = {
    "tsconfig.json",
  },
})
vim.lsp.enable("typescript-language-server")
