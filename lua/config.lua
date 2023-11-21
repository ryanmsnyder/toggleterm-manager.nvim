local actions = require("lib.actions")
local M = {}

local defaults = {
	mappings = {
		i = {
			["<CR>"] = { action = actions.toggle_term, exit_on_action = false },
			["<C-i>"] = { action = actions.create_term, exit_on_action = false },
			["<C-d>"] = { action = actions.delete_term, exit_on_action = false },
			["<C-r>"] = { action = actions.rename_term, exit_on_action = false },
		},
	}, -- key mappings bound inside the telescope window
	titles = {
		preview = "Preview", -- title of the preview buffer in telescope
		prompt = " Terminals", -- title of the prompt buffer in telescope
		results = "Results", -- title of the results buffer in telescope
	},
	results = {
		fields = {
			"state",
			"space",
			"term_icon",
			"term_name",
		},
		separator = " ", -- the character that will be used to separate each field provided in results.fields
		term_icon = "", -- the icon that will be used for the term_icon in results.fields
	},
	search = {
		field = "term_name", -- the field that telescope fuzzy search will use
	},
	sort = {
		field = "term_name", -- the field that will be used for sorting in the telesocpe results
		ascending = true, -- whether or not the field provided above will be sorted in ascending or descending order
	},
}
-- local defaults = {
-- 	mappings = {}, -- key mappings bound inside the telescope window
-- 	preview_title = "Preview", -- title of the preview buffer in telescope
-- 	prompt_title = " Pick Term", -- title of the prompt buffer in telescope
-- 	results_title = "Results", -- title of the results buffer in telescope
-- 	separator = " ", -- the character that will be used to separate each field provided in results_format
-- 	results_format = {
-- 		"state",
-- 		"space",
-- 		"term_icon",
-- 		"term_name",
-- 	},
-- 	term_icon = "", -- the icon that will be used for the term_icon in results_format
-- 	search_field = "term_name", -- the field that telescope fuzzy search will use
-- 	sort = {
-- 		field = "term_name", -- the field that will be used for sorting in the telesocpe results
-- 		ascending = true, -- whether or not the field provided above will be sorted in ascending or descending order
-- 	},
-- }

M.options = {}
function M.setup(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", defaults, opts)
end
M.setup()
return M
