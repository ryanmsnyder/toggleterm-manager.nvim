local M = {}

local defaults = {
	-- Key mappings bound inside the telescope window
	mappings = {},
	prompt_title = " Pick Term",
	preview_title = "Preview",
}
M.options = {}
function M.setup(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", defaults, opts)
end
M.setup()
return M
