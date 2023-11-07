local has_telescope = pcall(require, "telescope")
if not has_telescope then
	vim.notify("Telescope is not installed", vim.log.levels.ERROR)
	return
end

local M = {}
require("telescope").load_extension("toggleterm_manager")

M.actions = require("lib.actions")
M.open = require("lib.telescope").open
M.setup = function(opts)
	require("config").setup(opts)
end
return M
