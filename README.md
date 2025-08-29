# NodeZero Nvim

The NodeZero Nvim setup is a [profile](./profiles.md) setup that allows for the configuration of [LazyVim Plugins](https://lazyvim.org) on a per profile basis. This allows for having language specific configuration, for example. 


Currently all plugins are forked from the [nodezero](https://github.com/nodezeroio) organization on github. In the future we will be adding scanning for security vulnerabilities to ensure that all the plugins meet basic standards for security. 


Some of the most commonly used shortcuts and commands are documented in the [cheat-sheet](./shortcuts-cheat-sheet.md).


## Installation

To run this nvim configuration you can clone it into the default `~/.config/nvim` or to your own directory like `~/.config/nodezero.nvim`, if you use a non standard path you will need to set the `NVIM_APPNAME` environment variable to start neovim with this configuration:

```sh
NVIM_APPNAME=nodezero.nvim nvim
```


