require("nodezero.treesitter").setup({
  languages = {
    "yaml",
    "jinja",
    "jinja_inline",
  },
  filetypes = {
    -- lsp.lua maps .yaml onto the compound filetype yaml.ansible. A FileType
    -- autocmd pattern of "yaml" does not match "yaml.ansible", so the parser
    -- has to be registered for it explicitly.
    yaml = { "yaml.ansible" },
  },
})
