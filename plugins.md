# Plugin System Documentation

## Overview

This Neovim configuration uses a custom, lightweight plugin management system designed for simplicity and control. The system is built around the core Neovim functionality without relying on external plugin managers like LazyVim.

## Architecture

### Directory Structure

```
$HOME/.config/thomas.nvim/lua
.
├── profiles
│   ├── core
│   │   ├── config
│   │   │   ├── autocmds.lua
│   │   │   ├── init.lua
│   │   │   ├── keymaps.lua
│   │   │   └── options.lua
│   │   └── plugins.lua
│   ├── init.lua
│   └── overrides.lua
└── utils
    ├── global.lua
    └── plugin-manager.lua
```

### Plugin Storage

All plugins are cloned to: `$HOME/.local/share/thomas.nvim/plugins/`

Each plugin gets its own directory: `$HOME/.local/share/thomas.nvim/plugins/[plugin-name]/`

## How the Plugin Manager Works

### Core Functionality

The plugin manager (`utils/plugin-manager.lua`) provides a single main function:

```lua
plugin_manager.ensure(spec)
```

This function:

1. **Checks if plugin exists**: Looks for the plugin directory in `~/.local/share/thomas.nvim/plugins/`
2. **Clones if needed**: If the plugin doesn't exist, clones it using `git clone --depth=1`
3. **Adds to runtime path**: Prepends the plugin directory to Neovim's `runtimepath`
4. **Provides feedback**: Shows notifications during installation

### Plugin Specification Format

Each plugin is configured as follows:

```lua
M.plugin_def = {
    {
        "catppuccin/nvim", -- the plugin path on the repository, for example catppuccin/nvim would correspond to ${NVIM_PLUGIN_REPOSITORY}/catppucin/nvim
        spec = {
            name="catppuccin", -- optional parameter, if name is specified the plugin will be cloned at, if not specified it will be cloned at a normalized path based on the repository path. For example if spec.name is not specified it will be cloned and the plugin path is 'catppuccin/nvim' it will be cloned at `catppucin-nvim` `
        },
        options = {  -- This is the plugin configuration options specified by the plugin in question
            flavour = "mocha",
            background = {
                light = "latte",
                dark = "mocha",
            },
        },
        -- Hooks are ran before and after the configuration of the plugin. 
        -- Multiple hooks for each may be defined, they will be executed in the order specified by the profile priority or according to the lexigraphical order of the  profile names
        preSetup = function(pluginDef) -- a pre-setup hook
            -- This is ran before any setup steps have been completed for the plugin
        end

        postSetup = function(pluginDef) -- a pre-setup hook
            -- This is ran after all setup steps have been completed for the plugin
        end

        config = function(pluginDef) -- optional override for the default 'setup' method
            -- will be ran instead of the default setup method
        end

    }
}
```

### Runtime Path Management

Once a plugin is ensured, it's added to Neovim's `runtimepath` using:

```lua
vim.opt.rtp:prepend(plugin_path)
```

This allows you to use standard `require()` calls to load the plugin's Lua modules.

## Adding a Profile Plugin

Plugins are defined on a per profile basis. To add a plugin for a profile add a plugins.lua file at `lua/profiles/${profile_name}/plugins.lua`. 

Create a new file in `lua/profiles/core/plugins.lua`:

```lua
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
```
## Benefits of This Approach

1. **Simplicity**: Minimal code, easy to understand
2. **Control**: You know exactly what's happening
3. **Flexibility**: Easy to extend and modify
4. **Performance**: Only loads what you need
5. **Security**: No external dependencies for plugin management
6. **Debugging**: Easy to trace issues

## Troubleshooting

### Plugin Not Loading

1. Check if the plugin was cloned: `ls ~/.local/share/thomas.nvim/plugins/`
2. Verify the plugin spec has a correct plugin path
3. Check for error messages: `:messages`

### Git Clone Issues

- Ensure you have internet connectivity
- Verify the repository URL is correct and accessible
- Check if you need authentication for private repositories

### Runtime Path Issues

The plugin manager automatically handles runtime path management. If a plugin isn't found after installation, the issue is likely in the plugin specification or the plugin itself.
