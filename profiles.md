# Profiles

Profiles are the core component of `nodezero.nvim`, which is to say that it enables configuring different configuration and plugin setups depending on the profile that is being used. For example the [c_sharp](./lua/nodezero/profiles/c_sharp.lua) profile ensures the linter, formatters, and proper treesitter parsers are installed and configured for csharp. 

Profiles can be configured using an environment variable: `NODEZERO_NVIM_PROFILES` environment variable. For instance if you start the neovim instance like this: 

```sh
NODEZERO_NVIM_PROFILES="core;c_sharp" NVIM_APPNAME=nodezero.nvim nvim
```

This will ensure all the plugins and configuration are loaded from the [./lua/nodezero/profiles/core.lua](./lua/nodezero/profiles/core.lua) and [./lua/nodezero/profiles/c_sharp.lua](./lua/nodezero/profiles/c_sharp.lua respectively.

A profile can be a lua file or a directory of the profile name with an init.lua. A profile should define at least a 'plugins' property like this:

```lua
return {
    plugins = {
        -- plugin onfiguration here

    }
}
```

All plugins are defined  according to the [LazyVim profile spec](https://lazy.folke.io/spec). [LazyVim](https://www.lazyvim.org/) is currently the plugin manager that is used to load all plugins and configuration. 

