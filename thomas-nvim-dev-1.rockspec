package = "thomas-nvim"
rockspec_format = "3.0"
version = "dev-1"
source = {
   url = "git+https://github.com/thomasbellio/thomas.nvim.git",
   branch = "main"
}
description = {
   summary = "Custom Neovim configuration with lightweight plugin management",
   detailed = [[
      A custom Neovim configuration built from the ground up with a simple
      plugin management system designed for rapid context switching between
      different development contexts (coding, note-taking, etc.).

      Features:
      - Custom lightweight plugin manager
      - Profile-based plugin loading
      - Security-focused approach
      - Minimal dependencies
   ]],
   homepage = "https://github.com/thomasbellio/thomas.nvim",
   license = "MIT"
}
dependencies = {
   -- Strict Lua 5.1 requirement to match Neovim's LuaJIT
   "lua == 5.1",

   -- Testing framework
   "busted >= 2.0.0",

   "luacov",

   -- Linting and static analysis
   "luacheck >= 0.23.0",

   -- Optional: LuaRocks development tools
   "ldoc >= 1.4.6"
}
build = {
   type = "builtin",
   modules = {
      -- Define your main modules here if you want them installable
      ["thomas-nvim.utils.plugin-manager"] = "lua/utils/plugin-manager.lua",
      ["thomas-nvim.profiles.init"] = "lua/profiles/init.lua",
   },
   copy_directories = {
      "lua",
      "tests"
   }
}
test_dependencies = {
   "busted >= 2.0.0"
}
test = {
   type = "busted"
}
