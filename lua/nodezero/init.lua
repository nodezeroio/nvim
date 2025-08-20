local M = {}
local utils = require("nodezero.utils")
local hooks = utils.getHooks()
local loaded = require("nodezero.profiles").loaded
local pluginLoader = require('nodezero.plugins.loader')
M.profiles = loaded.profiles
M.plugins = loaded.plugins
pluginLoader.setup(M.plugins, hooks)
return M
