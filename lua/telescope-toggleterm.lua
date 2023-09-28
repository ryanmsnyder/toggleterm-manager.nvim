local M = {}
require("telescope").load_extension("toggleterm")

M.actions = require("lib.actions")
M.open = require("lib.telescope").open
M.setup = function(opts)
	require("config").setup(opts)
end
return M
