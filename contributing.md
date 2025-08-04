# About

This is the documentation for how to make changes to this code repository. For details on usage please see [usage.md](./usage.md).


## Dependencies

* [luarocks](https://github.com/luarocks/luarocks)
* [stylua](https://github.com/JohnnyMorganz/StyLua)
* [lua 5.1](https://sourceforge.net/projects/luabinaries/files/5.1.5/)
* [make](https://www.gnu.org/software/make/)

## Setup

Once you have installed the dependencies above you should be able to run `make install-dev` to install all required dependencies. 


## Testing

This repository relies on [busted](https://lunarmodules.github.io/busted/) for testing. 

The tests are run using a shim configured in the [busted configuration](./.busted) that executes a shim found [here](./tests/nvim-shim), this ensures that the tests are ran in the context of nvim using the lua interpreter for neovim. 

Once you have done the setup instructions from above you can run the tests by just executing `busted` from the root of this repository.

