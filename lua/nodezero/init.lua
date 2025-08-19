local M = {}
local loaded = require("nodezero.profiles").loaded
M.profiles = loaded.profiles
M.plugins = loaded.plugins
return M
