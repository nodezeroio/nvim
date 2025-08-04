std = "luajit"

-- Files/directories to exclude
exclude_files = {
  "luarocks",
  ".luarocks",
  "lua_modules"
}
-- Global Neovim variables
globals = {
  "vim",
  "_G",
  "NodeZeroVim"
}
-- Test-specific configuration
files["tests/**/*_spec.lua"] = {
  std = "+busted"
}

files["tests/**/*test*.lua"] = {
  std = "+busted"
}

files["tests/**/spec_*.lua"] = {
  std = "+busted"
}
