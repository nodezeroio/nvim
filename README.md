# About


This is the configuration setup for my neovim setup. 

The purpose of this setup is to enable rapid iteration on software projects that may be from different domains and contexts. 

This neovim configuration is [profile](./profiles.md) driven, meaning that you can define different profiles for different contexts and domains that will enable functionality depending on the context.

To add a plugin you can follow instructions laid out in [plugins.md](./plugins.md)


For details on contributing to this repository please see the [contributing.md](./contributing.md)


## Goals

As with all of my other system setup related projects, the goal is to enable rapid context switching, while only having the minimum necessary setup for the specific context.

For example when coding I need things like auto complete, but when I am writing notes the auto complete feature gets in the way. 




## Design Heuristics

* Only what you need to achieve the goals in the context
* The experience should be consistent regardless of the context, meaning navigation and keybindings should remain the same so I can easily switch without much cognitive load
* Fast setup and configuration


## Example Contexts

### Coding context

For each coding context I need to be able to have the following things setup:

* Language specific [Treesitter](https://github.com/tree-sitter/tree-sitter) parsers
* [Language Server Protocols (LSP)](https://microsoft.github.io/language-server-protocol/)
* [Language Specific Debug Adapter Protocols (DAP)](https://microsoft.github.io/debug-adapter-protocol/)
* Keyboard shortcuts for enabling the debugger and code navigation (The keyboard shortcuts should be generally applicable to ensure consistency from one programming context to the next)
* Project Specific AI contexts for things like [avante.nvim](https://github.com/yetone/avante.nvim)


### Note Taking Context

For the note taking context I need markdown support and I don't need things like auto-complete. Spell check and AI integrations might also be included. 
