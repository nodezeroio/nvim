require("nodezero.treesitter").setup({
  languages = {
    "starlark",
  },
  filetypes = {
    -- Nvim detects Tiltfiles as filetype "tiltfile"; the grammar is starlark.
    starlark = { "tiltfile" },
  },
})
