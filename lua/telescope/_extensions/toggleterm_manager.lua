local telescope = require("telescope")
local open = require("lib.telescope").open

return telescope.register_extension({
	exports = {
		toggleterm_manager = open,
	},
})
