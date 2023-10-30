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

function M.get_terminals()
	local bufnrs = vim.tbl_filter(function(b)
		return vim.api.nvim_buf_get_option(b, "filetype") == "toggleterm"
	end, vim.api.nvim_list_bufs())

	if #bufnrs == 0 then
		return {}, {}
	end
	local terminals = {}
	local entry_maker_opts = {}
	local term_name_lengths, bufname_lengths = {}, {}

	for _, bufnr in ipairs(bufnrs) do
		local id = vim.api.nvim_buf_get_var(bufnr, "toggle_number")
		local term = toggleterm.get(id)

		local info = vim.fn.getbufinfo(term.bufnr)[1]
		local term_name = term.display_name or tostring(term.id)
		local flag = (term.bufnr == vim.fn.bufnr("") and "%") or (term.bufnr == vim.fn.bufnr("#") and "#" or "")

		table.insert(term_name_lengths, #term_name)
		table.insert(bufname_lengths, #info.name)

		if flag ~= "" then
			entry_maker_opts.flag_exists = true
		end

		term.info, term.flag, term.term_name = info, flag, term_name
		table.insert(terminals, term)
	end

	entry_maker_opts.max_term_name_width = math.max(unpack(term_name_lengths))
	entry_maker_opts.max_bufnr_width = #tostring(math.max(unpack(bufnrs)))
	entry_maker_opts.max_bufname_width = math.max(unpack(bufname_lengths))

	return terminals, entry_maker_opts
end

function M.create_finder(cur_row_term_id)
	local config = require("config").options
	local terms, entry_maker_opts = M.get_terminals()

	local new_row_num
	if #terms > 0 then
		local sort_field = config.sort.field
		local ascending = config.sort.ascending
		local sort_funcs = {
			bufname = function(a, b) end,
			bufnr = function(a, b)
				if ascending then
					return a.bufnr < b.bufnr
				end
				return a.bufnr > b.bufnr
			end,
			creation = function(a, b) end,
			lastused = function(a, b)
				if ascending then
					return a.info.lastused > b.info.lastused
				end
				return a.info.lastused < b.info.lastused
			end,
			term_name = function(a, b)
				return a.term_name < b.term_name
			end,
		}

		table.sort(terms, sort_funcs[sort_field])

		-- get the new row number of the current_cur_row_term_id
		-- useful when the telescope picker is refreshed and you want the cursor to remain on the same item even after sorting
		if cur_row_term_id then
			for i, term in ipairs(terms) do
				if term.id == cur_row_term_id then
					new_row_num = i - 1
					break
				end
			end
		end
	end

	return finders.new_table({
		results = terms,
		entry_maker = require("lib.displayer").displayer(entry_maker_opts),
	}),
		new_row_num
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

function M.focus_on_telescope(prompt_bufnr)
	-- Go through all the windows
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		-- Check if the window's buffer is the one we're looking for
		if vim.api.nvim_win_get_buf(win) == prompt_bufnr then
			-- Set focus to that window
			vim.api.nvim_set_current_win(win)
			return
		end
	end
	print("Telescope buffer not visible in any window")
end

return M
