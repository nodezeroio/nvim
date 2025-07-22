return {
    spec = {
        name="catppuccin",
        url = "https://github.com/thomasbellio/catppuccin-nvim",
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
