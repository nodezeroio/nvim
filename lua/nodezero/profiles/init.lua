local M = {}

M.utils = require("nodezero.profiles.utils")
M.loaded = require("nodezero.profiles.loader").setup().load()

return M
