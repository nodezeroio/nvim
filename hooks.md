# Hooks System

The hooks system in nodezero.nvim provides a clean, centralized way to customize plugin setup behavior without cluttering plugin definitions with functional logic. Hooks are defined globally and executed at specific points during the plugin loading lifecycle.

## Overview

The hooks system separates plugin configuration (what plugins to load and their options) from plugin setup logic (how plugins should be initialized and customized). This separation provides:

- **Clean plugin definitions** focused purely on configuration
- **Centralized setup logic** in a single location
- **Simplified merging** of plugin configurations across profiles
- **Better maintainability** and debugging capabilities

## Architecture

### Plugin Definitions (No Hooks)

Plugin definitions in profile configurations contain only declarative configuration:

```lua
{
    "catppuccin/nvim",
    spec = {
        name = "catppuccin",
    },
    options = {
        flavour = "mocha",
        background = {
            light = "latte",
            dark = "mocha",
        },
    },
}
```

### Global Hooks File

All setup logic is defined in `lua/nodezero/hooks.lua`:

```lua
-- lua/nodezero/hooks.lua
local M = {}

M.plugin_hooks = {
    ["catppuccin/nvim"] = {
        postSetup = function(pluginDef)
            vim.cmd.colorscheme("catppuccin")
        end
    },
    
    ["nvim-treesitter/nvim-treesitter"] = {
        config = function(pluginDef)
            require("nvim-treesitter.configs").setup(pluginDef.options)
        end
    },
}

function M.get_hooks(plugin_key)
    return M.plugin_hooks[plugin_key] or {}
end

return M
```

## Hook Types

### preSetup Hook

Executed before the main plugin setup logic. Useful for:
- Setting up prerequisites
- Modifying environment or global state
- Logging setup initiation

```lua
M.plugin_hooks = {
    ["example/plugin"] = {
        preSetup = function(pluginDef)
            -- Setup prerequisites
            vim.g.example_plugin_enabled = true
            NodeZeroVim.debug.log("Setting up example plugin")
        end
    }
}
```

### config Hook

Replaces the default plugin setup behavior. When defined, this function is called instead of the standard `require(plugin_name).setup(options)` pattern.

```lua
M.plugin_hooks = {
    ["nvim-treesitter/nvim-treesitter"] = {
        config = function(pluginDef)
            -- Custom setup logic instead of default
            require("nvim-treesitter.configs").setup(pluginDef.options)
        end
    }
}
```

### postSetup Hook

Executed after the main plugin setup is complete. Useful for:
- Additional configuration that depends on the plugin being loaded
- Setting colorschemes or themes
- Configuring keymaps specific to the plugin

```lua
M.plugin_hooks = {
    ["catppuccin/nvim"] = {
        postSetup = function(pluginDef)
            vim.cmd.colorscheme("catppuccin")
        end
    }
}
```

## Hook Execution Order

Hooks are executed in the following order during plugin setup:

1. **preSetup hook** (if defined)
2. **Main setup logic**:
   - Custom `config` hook (if defined), OR
   - Default `require(plugin_name).setup(options)` call
3. **postSetup hook** (if defined)

## Plugin Identification

Plugins are identified by the first string in their definition array. For example:

```lua
{
    "catppuccin/nvim",  -- This string identifies the plugin
    spec = { name = "catppuccin" },
    options = { ... }
}
```

The corresponding hook would be defined using the same identifier:

```lua
M.plugin_hooks = {
    ["catppuccin/nvim"] = {  -- Same identifier
        postSetup = function(pluginDef) ... end
    }
}
```

## Error Handling

If a hook encounters an error during execution:

1. The error is logged using `NodeZeroVim.debug.log`
2. Plugin loading continues with the next step
3. The overall loading process is not interrupted

```lua
-- Example error handling (built into the system)
local ok, err = pcall(plugin_hooks.preSetup, plugin_def)
if not ok then
    NodeZeroVim.debug.log(
        string.format("Error in preSetup hook for %s: %s", plugin_key, err), 
        "ERROR"
    )
    -- Continue with next setup step
end
```

## Examples

### Basic Plugin with Post-Setup Hook

```lua
-- In a profile's plugins.lua
{
    "folke/tokyonight.nvim",
    spec = {
        name = "tokyonight",
    },
    options = {
        style = "night",
        transparent = true,
    },
}

-- In lua/nodezero/hooks.lua
M.plugin_hooks = {
    ["folke/tokyonight.nvim"] = {
        postSetup = function(pluginDef)
            vim.cmd.colorscheme("tokyonight")
        end
    }
}
```

### Plugin with Custom Configuration

```lua
-- In a profile's plugins.lua
{
    "nvim-lualine/lualine.nvim",
    spec = {
        name = "lualine",
    },
    options = {
        theme = "auto",
        sections = {
            lualine_a = {"mode"},
            lualine_b = {"branch", "diff", "diagnostics"},
            lualine_c = {"filename"},
        },
    },
}

-- In lua/nodezero/hooks.lua
M.plugin_hooks = {
    ["nvim-lualine/lualine.nvim"] = {
        config = function(pluginDef)
            require("lualine").setup(pluginDef.options)
        end
    }
}
```

### Plugin with Complete Lifecycle Hooks

```lua
-- In a profile's plugins.lua
{
    "nvim-telescope/telescope.nvim",
    spec = {
        name = "telescope",
    },
    options = {
        defaults = {
            file_ignore_patterns = {"node_modules", ".git"},
            layout_strategy = "horizontal",
        },
    },
}

-- In lua/nodezero/hooks.lua
M.plugin_hooks = {
    ["nvim-telescope/telescope.nvim"] = {
        preSetup = function(pluginDef)
            -- Ensure dependencies are available
            if not pcall(require, "plenary") then
                error("Telescope requires plenary.nvim")
            end
        end,
        
        config = function(pluginDef)
            require("telescope").setup(pluginDef.options)
        end,
        
        postSetup = function(pluginDef)
            -- Set up keymaps after plugin is loaded
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
            vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
        end
    }
}
```

### Plugin with No Default Setup

```lua
-- In a profile's plugins.lua
{
    "nvim-lua/plenary.nvim",
    spec = {
        name = "plenary",
    },
    -- No options - this is a library plugin
}

-- In lua/nodezero/hooks.lua
M.plugin_hooks = {
    ["nvim-lua/plenary.nvim"] = {
        config = function(pluginDef)
            -- This plugin doesn't need setup() to be called
            -- Just ensure it's loaded
            require("plenary")
        end
    }
}
```

## Benefits

### Clean Separation of Concerns

- **Plugin definitions** focus on *what* to load and *how* to configure
- **Hooks system** handles *how* to set up and customize
- Profiles can focus on their domain-specific plugin selections

### Simplified Plugin Merging

Since plugin definitions contain no functions, merging configurations across profiles becomes straightforward:

```lua
-- Simple deep merge without function complexity
merged_plugin = vim.tbl_deep_extend("force", base_plugin, override_plugin)
```

### Centralized Customization

All plugin setup logic is in one place, making it easy to:
- See all customizations at a glance
- Debug setup issues
- Modify behavior without touching profile definitions
- Add logging or debugging around setup process

### Future Extensibility

The hooks system provides a foundation for future enhancements:
- Conditional hooks based on environment
- Profile-aware hooks
- Plugin dependency management
- Setup performance monitoring`
