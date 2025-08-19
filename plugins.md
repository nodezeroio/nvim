# Plugin System Documentation

## Overview

This Neovim configuration uses a custom, lightweight plugin management system designed for simplicity and control.

## Architecture

### Directory Structure

```
$HOME/.config/nodezero.nvim/lua
.
└── nodezero
    ├── debug.lua
    ├── init.lua
    ├── overrides.lua
    ├── overrides.lua.example
    ├── plugins
    │   └── loader.lua
    ├── profile-config.lua
    ├── profile-config.lua.example
    ├── profiles
    │   ├── config.lua
    │   ├── init.lua
    │   ├── loader.lua
    │   ├── overrides.lua.example
    │   ├── profile-config.lua
    │   ├── profile-config.lua.example
    │   └── utils.lua
    └── utils
        ├── filesystem.lua
        ├── git.lua
        └── init.lua
```

### Plugin Storage

All plugins are cloned to: `$XDG_DATA_HOME/nodezero.nvim/plugins/`

Each plugin gets its own directory: `$XDG_DATA_HOME/nodezero.nvim/plugins/[plugin-name]/`

The plugins directory can be overridden using `NODEZERO_NVIM_PLUGINS_DIRECTORY`

## How the Plugin Manager Works

### Core Functionality

The plugin loader (`nodezero.plugins.loader`) provides a single main function:

```lua
plugin_loader.setup(plugins, hooks)
```

This function:

1. **Checks that the plugin directory exists**: Looks for the directory `$XDG_DATA_HOME/nodezero.nvim/plugins/`, using `nodezero.utils.ensurePath` with the 'create' parameter set to true
2. **Checks if plugin exists**: Looks for the plugin directory in `$XDG_DATA_HOME/nodezero.nvim/plugins/[plugin-name]`
3. **Clones if needed**: If the plugin doesn't exist, clones it using `nodezero.utils.vcs.cloneRepo`
4. **Adds to runtime path**: Prepends the plugin directory to Neovim's `runtimepath` using `nodezero.utils.updatePackagePath`
5. **Load the Plugin**: For each plugin it will:
    1. Check if there is a 'preSetup' function for the `plugin[1]` key, if there is it will call the `preSetup` hook using the plugin_def as an argument
    2. If there is a hook named `config` it will call that method to setup the plugin using the `plugin_def` as an argument. If there is no `config` hook then it will `require(plugin_def.spec.name).setup(plugin_def.options)`.
    3. If there is a hook named `postSetup` it will call that method after the setup process is completed
5. **Provides feedback**: Shows notifications during installation


The above steps will be repeated for each plugin, except for step 1.
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
    }
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
