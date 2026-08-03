require("nodezero.treesitter").setup({
  languages = {
    "bash",
    "c",
    "diff",
    "json",
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
    -- nvim-treesitter dropped the jsonc grammar; the json parser handles the
    -- jsonc filetype, comments included.
    json = { "jsonc" },
  },
})
