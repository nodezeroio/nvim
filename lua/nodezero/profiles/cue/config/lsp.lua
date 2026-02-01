vim.lsp.config("cuelsp", {
  cmd = { "cue", "lsp" },
  filetypes = { "cue" },
  root_markers = {
    "cue.mod",
    ".git",
  },
})
vim.lsp.enable("cuelsp")
