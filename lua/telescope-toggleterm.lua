local M = {}
M.actions = require('lib.actions')
M.open = require("lib.telescope").open
M.setup = function(opts) require('config').setup(opts) end
return M
