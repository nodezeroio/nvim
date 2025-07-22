return {
    "catppuccin/nvim",
    spec = {
        name="catppuccin",
    },
    config = {
        flavour = "mocha",
        background = {
            light = "latte",
            dark = "mocha",
        },
    },
    integrations = {
        treesitter = true,
        telescope = true,
    },
    postSetup = function(config)
        vim.cmd.colorscheme("catppuccin")
    end
}
