local Utils = require("nodezero.utils")
local plugins = require("nodezero.profiles.plugins")
local color_scheme = require("plugins.core.colorscheme")
local M = Utils.mergeTables(color_scheme, plugins)
return M
