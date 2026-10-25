vim.lsp.config("tilt_ls", {
  cmd = { "tilt", "lsp", "start" },
  filetypes = { "tiltfile" },
  root_markers = {
    "Tiltfile",
    ".git",
  },
})
vim.lsp.enable("tilt_ls")
