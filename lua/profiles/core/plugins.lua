return {
    {
        "catppuccin/nvim",
        spec = {
            name="catppuccin",
        },
        options = {
            flavour = "mocha",
            background = {
                light = "latte",
                dark = "mocha",
            },
        },
        postSetup = function(pluginDef)
            vim.cmd.colorscheme("catppuccin")
        end
    },
    {
     "nvim-treesitter/nvim-treesitter",
     spec = {
       name = "nvim-treesitter.configs",
     },
     config = function(plugin_def)
        require("nvim-treesitter.configs").setup(plugin_def.options)
     end,
     options = {
       ensure_installed = {
            "lua",
            "luadoc",
            "luap",
            "markdown",
            "markdown_inline",
            "vim",
            "vimdoc",
            "bash",
            "jsdoc",
            "json",
            "jsonc",
            "regex",
            "toml",
            "xml",
            "yaml",
       },
       highlight = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },

     },
   },
}
