local Utils = require("nodezero.utils")
local Profiles = require("nodezero.profiles")
local color_scheme = require("plugins.core.colorscheme")
local M = Utils.mergeTables(color_scheme, Profiles.plugins)
return M
