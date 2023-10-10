local M = {}

local defaults = {
	-- Key mappings bound inside the telescope window
	mappings = {},
	prompt_title = " Pick Term",
	preview_title = "Preview",
	results_format = {
		"indicator",
		"space",
		"term_icon",
		"term_name",
	},
	separator = " ",
}
M.options = {}
function M.setup(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", defaults, opts)
end
M.setup()
return M
