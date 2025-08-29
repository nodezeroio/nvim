return {
  plugins = {
    { "nvim-treesitter/nvim-treesitter", url = "git@github.com:nodezeroio/nvim-treesitter.git" },
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      url = "git@github.com:nodezeroio/nvim-treesitter-textobjects.git",
    },
    { "nvim-lua/plenary.nvim", url = "git@github.com:nodezeroio/plenary.nvim.git" },
    {
      "folke/snacks.nvim",
      url = "git@github.com:nodezeroio/snacks.nvim.git",
      opts = {
        picker = {
          sources = {
            explorer = {
              hidden = true,
              ignored = true,
            },
          },
        },
      },
    },
    {
      "folke/tokyonight.nvim",
      cond = false,
    },
    {
      "folke/trouble.nvim",
      url = "git@github.com:nodezeroio/trouble.nvim.git",
    },
    {
      "folke/ts-comments.nvim",
      url = "git@github.com:nodezeroio/ts-comments.nvim.git",
    },
    {
      "folke/which-key.nvim",
      url = "git@github.com:nodezeroio/which-key.nvim.git",
    },
    {
      "MunifTanjim/nui.nvim",
      url = "git@github.com:nodezeroio/nui.nvim.git",
    },
    {
      "folke/lazydev.nvim",
      url = "git@github.com:nodezeroio/lazydev.nvim.git",
    },
    {
      "stevearc/conform.nvim",
      url = "git@github.com:nodezeroio/conform.nvim.git",
    }, -- TODO: this will be configurable per language in profiles
    {
      "rafamadriz/friendly-snippets",
      url = "git@github.com:nodezeroio/friendly-snippets.git",
    }, -- TODO: this will be configurable through profiles
    {
      "lewis6991/gitsigns.nvim",
      cond = false,
    },
    {
      "MagicDuck/grug-far.nvim",
      url = "git@github.com:nodezeroio/grug-far.nvim.git",
    },
    {
      "mason-org/mason.nvim",
      url = "git@github.com:nodezeroio/mason.nvim.git",
    },
    {
      "folke/noice.nvim",
      cond = false,
    },
    {
      "mfussenegger/nvim-lint",
      url = "git@github.com:nodezeroio/nvim-lint.git",
    }, -- TODO: this may also be configurable per language profile,
    {
      "folke/todo-comments.nvim",
      url = "git@github.com:nodezeroio/todo-comments.nvim.git",
    },
    {
      "neovim/nvim-lspconfig",
      url = "git@github.com:nodezeroio/nvim-lspconfig.git",
    }, -- TODO: this will be configurable on a per profile basis
    {
      "windwp/nvim-ts-autotag",
      url = "git@github.com:nodezeroio/nvim-ts-autotag.git",
    }, -- TODO: this will be configurable on a per profile basis
    {
      "folke/persistence.nvim",
      cond = false,
    },
    {
      "echasnovski/mini.pairs",
      url = "git@github.com:nodezeroio/mini.pairs.git",
    },
    {
      -- auto completion
      "saghen/blink.cmp",
      url = "git@github.com:nodezeroio/blink.cmp",
    },
    {
      -- window tabs
      "akinsho/bufferline.nvim",
      url = "git@github.com:nodezeroio/bufferline.nvim",
    },
    {
      -- fuzzy file search
      "nvim-telescope/telescope.nvim",
      url = "git@github.com:nodezeroio/telescope.nvim",
    },
    {
      -- status line
      "nvim-lualine/lualine.nvim",
      url = "git@github.com:nodezeroio/lualine.nvim.git",
    },
    {
      "folke/flash.nvim",
      cond = false,
    },
    {
      "echasnovski/mini.ai",
      cond = false,
    },
    {
      -- file icons and glyphs
      "echasnovski/mini.icons",
      url = "git@github.com:nodezeroio/mini.icons.git",
    },
    {
      -- helpers for mason
      "mason-org/mason-lspconfig.nvim",
      url = "git@github.com:nodezeroio/mason-lspconfig.nvim.git",
    },
    {
      "yetone/avante.nvim",
      url = "git@github.com:nodezeroio/avante.nvim.git",
      event = "VeryLazy",
      version = false, -- Never set this value to "*"! Never!
      opts = {
        -- add any opts here
        -- for example
        provider = "openai",
        providers = {
          openai = {
            endpoint = "https://api.openai.com/v1",
            model = "gpt-4o", -- your desired model (or use gpt-4o, etc.)
            timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
            extra_request_body = {
              temperature = 0,
              max_completion_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
            },
            --reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
          },
        },
      },
      -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
      build = "make",
      -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
      dependencies = {
        { "nvim-treesitter/nvim-treesitter", url = "git@github.com:nodezeroio/nvim-treesitter.git" },
        { "nvim-lua/plenary.nvim", url = "git@github.com:nodezeroio/plenary.nvim.git" },
        { "folke/snacks.nvim", url = "git@github.com:nodezeroio/snacks.nvim.git" },
        --- The below dependencies are optional,
        { "nvim-telescope/telescope.nvim" }, -- for file_selector provider telescope
        {
          -- file icons and glyphs
          "echasnovski/mini.icons",
          url = "git@github.com:nodezeroio/mini.icons.git",
        },
        -- not sure if this is necessary since I already have blink-cmp
        --      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
        {
          -- support for image pasting
          "HakonHarnes/img-clip.nvim",
          url = "git@github.com:nodezeroio/img-clip.nvim.git",
          event = "VeryLazy",
          opts = {
            -- recommended settings
            default = {
              embed_image_as_base64 = false,
              prompt_for_file_name = false,
              drag_and_drop = {
                insert_mode = true,
              },
              -- required for Windows users
              use_absolute_path = true,
            },
          },
        },
        {
          -- Make sure to set this up properly if you have lazy=true
          "MeanderingProgrammer/render-markdown.nvim",
          url = "git@github.com:nodezeroio/render-markdown.nvim.git",
          opts = {
            file_types = { "markdown", "Avante" },
          },
          ft = { "markdown", "Avante" },
        },
      },
    },
  },
}
