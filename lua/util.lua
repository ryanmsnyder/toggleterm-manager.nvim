local finders = require("telescope.finders")
local toggleterm = require("toggleterm.terminal")
local toggleterm_ui = require("toggleterm.ui")

local M = {}
local function_name_to_description = {
	toggle_terminal = "Toggle term",
	create_terminal = "Create term",
	delete_terminal = "Delete term",
	rename_terminal = "Rename term",
}

function M.format_results_title(mappings)
	local actions = require("telescope-toggleterm").actions
	local mapping_descriptions = {}

	for mapping, action_tbl in pairs(mappings) do
		local key = mapping:match("<(.-)>")
		local action = action_tbl["action"]
		local func_name = next(vim.tbl_filter(function(val)
			return val == action
		end, actions))

		if func_name and function_name_to_description[func_name] then
			table.insert(mapping_descriptions, string.format("%s: %s", key, function_name_to_description[func_name]))
		end
	end

	return table.concat(mapping_descriptions, "  ")
end

function M.create_finder(sort)
	local terms = toggleterm.get_all(true)
	local entry_maker_opts = {}
	local bufnrs, term_name_lengths, bufname_lengths, buffers = {}, {}, {}, {}

	if #terms > 0 then
		if sort then
			table.sort(terms, function(a, b)
				return vim.fn.getbufinfo(a.bufnr)[1].lastused > vim.fn.getbufinfo(b.bufnr)[1].lastused
			end)
		end

		for _, term in ipairs(terms) do
			local info = vim.fn.getbufinfo(term.bufnr)[1]
			local term_name = term.display_name or tostring(term.id)
			local flag = (term.bufnr == vim.fn.bufnr("") and "%") or (term.bufnr == vim.fn.bufnr("#") and "#" or "")

			table.insert(bufnrs, term.bufnr)
			table.insert(term_name_lengths, #term_name)
			table.insert(bufname_lengths, #info.name)
			if flag ~= "" then
				entry_maker_opts.flag_exists = true
			end

			term.info, term.flag, term.term_name = info, flag, term_name
			table.insert(buffers, term)
		end

		entry_maker_opts.max_term_name_width = #terms > 0 and math.max(unpack(term_name_lengths))
		entry_maker_opts.max_bufnr_width = #terms > 0 and #tostring(math.max(unpack(bufnrs)))
		entry_maker_opts.max_bufname_width = #terms > 0 and math.max(unpack(bufname_lengths))
	end

	return finders.new_table({
		results = buffers,
		entry_maker = require("lib.displayer").displayer(entry_maker_opts),
	})
end

-- registering a callback is necessary to call set_selection (which is used to keep the selection on the entry
-- that was just renamed in this case) after calling the refresh method. Otherwise, because of the async behavior
-- of refresh, set_selection will be called before the refresh is complete and the selection will just move
-- to the first entry
function M.set_selection_row(picker)
	local current_row = picker:get_selection_row()

	local callbacks = { unpack(picker._completion_callbacks) } -- shallow copy
	picker:register_completion_callback(function(self)
		self:set_selection(current_row)
		self._completion_callbacks = callbacks
	end)
end

-- focuses on toggleterm's current origin window without closing telescope (the use of noautocmd prevents the
-- telescope prompt from automatically closing)
function M.focus_on_origin_win()
	local window = toggleterm_ui.get_origin_window()
	vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", window))
end

return M
