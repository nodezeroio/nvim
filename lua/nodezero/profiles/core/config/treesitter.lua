require("nodezero.treesitter").setup({
  languages = {
    "bash",
    "c",
    "diff",
    "json",
    "jsonc",
    "lua",
    "luadoc",
    "luap",
    "markdown",
    "markdown_inline",
    "toml",
    "vimdoc",
    "xml",
    "yaml",
  },
  filetypes = {
    bash = { "sh" },
  },
})
