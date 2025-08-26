return {
  require("plugins.core.colorscheme"),
  -- {
  --   -- auto completion
  --   "saghen/blink.cmp",
  --   url = "git@github.com:nodezeroio/blink.cmp",
  -- },
  -- {
  --   -- window tabs
  --   "akinsho/bufferline.nvim",
  --   url = "git@github.com:nodezeroio/bufferline.nvim",
  -- },
  {
    -- fuzzy file search
    "nvim-telescope/telescope.nvim",
    url = "git@github.com:nodezeroio/telescope.nvim",
    lazy = false,
  },
  -- {
  --   -- status line
  --   "nvim-lualine/lualine.nvim",
  --   url = "git@github.com:nodezeroio/lualine.nvim.git",
  -- },
  -- {
  --   "folke/flash.nvim",
  --   enabled = false,
  -- },
  -- {
  --   "echasnovski/mini.ai",
  --   enabled = false,
  -- },
  -- {
  --   -- file icons and glyphs
  --   "echasnovski/mini.icons",
  --   url = "git@github.com:nodezeroio/mini.icons.git",
  -- },
  -- {
  --   -- helpers for mason
  --   "maon-org/mason-lspconfig.nvim",
  --   url = "git@github.com:nodezeroio/mason-lspconfig.nvim.git",
  -- },
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
      "nvim-treesitter/nvim-treesitter",
      --     "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
      --- The below dependencies are optional,
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
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
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
