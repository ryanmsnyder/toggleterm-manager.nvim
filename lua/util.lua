local finders = require("telescope.finders")
local toggleterm = require("toggleterm.terminal")
local toggleterm_ui = require("toggleterm.ui")
local Path = require("plenary.path")
local actions_state = require("telescope.actions.state")

local M = {}
local function_name_to_description = {
	toggle_terminal = "Toggle term",
	create_terminal = "Create term",
	delete_terminal = "Delete term",
	rename_terminal = "Rename term",
}

function M.format_results_title(mappings)
	print(vim.inspect(mappings))
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

--- Get the list of terminals and their properties.
--- @return table, table A tuple containing a list of toggleterm/terminal objects and a table of options that will be used for
--- creating the telescope entries.
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

	local cwd = vim.fn.expand(vim.loop.cwd())

	for _, bufnr in ipairs(bufnrs) do
		local id = vim.api.nvim_buf_get_var(bufnr, "toggle_number")
		local term = toggleterm.get(id)

		local info = vim.fn.getbufinfo(term.bufnr)[1]

		local flag = (term.bufnr == vim.fn.bufnr("") and "%") or (term.bufnr == vim.fn.bufnr("#") and "#" or "")
		local visibility = info.hidden == 1 and "h" or "a"
		local state = flag .. visibility

		local term_name = term.display_name or tostring(term.id)

		local bufname = info.name ~= "" and info.name or "No Name"
		bufname = Path:new(bufname):normalize(cwd) -- if bufname is inside the cwd, trim that part of the string

		table.insert(term_name_lengths, #term_name)
		table.insert(bufname_lengths, #info.name)

		if flag ~= "" then
			entry_maker_opts.flag_exists = true
		end

		term._info, term._state, term._term_name, term._bufname = info, state, term_name, bufname
		table.insert(terminals, term)
	end

	entry_maker_opts.max_term_name_width = math.max(unpack(term_name_lengths))
	entry_maker_opts.max_bufnr_width = #tostring(math.max(unpack(bufnrs)))
	entry_maker_opts.max_bufname_width = math.max(unpack(bufname_lengths))

	return terminals, entry_maker_opts
end

--- Create a telescope finder with the current terminals. Sort the terminal objects based on the user's
--- sort table provided in their config. This determines the order they appear in the telescope buffer.
--- @param cur_row_term_id number|nil The id of the current terminal to find.
--- @return function, number A new finder function and the row number of the current terminal.
function M.create_finder(cur_row_term_id)
	local config = require("config").options
	local terms, entry_maker_opts = M.get_terminals()

	local new_row_num
	if terms and #terms > 0 then
		local sort_field = config.sort.field
		local ascending = config.sort.ascending
		local sort_funcs = {
			bufnr = function(a, b)
				if ascending then
					return a.bufnr < b.bufnr
				end
				return a.bufnr > b.bufnr
			end,
			state = function(a, b)
				if ascending then
					return a._state < b._state
				end
				return a._state > b._state
			end,
			recency = function(a, b)
				if ascending then
					return a._info.lastused < b._info.lastused
				end
				return a._info.lastused > b._info.lastused
			end,
			term_name = function(a, b)
				local numA = tonumber(a._term_name)
				local numB = tonumber(b._term_name)

				local result
				if numA and numB then
					if ascending then
						result = numA < numB
					else
						result = numA > numB
					end
				elseif numA then
					result = ascending
				elseif numB then
					result = not ascending
				else
					if ascending then
						result = a._term_name < b._term_name
					else
						result = a._term_name > b._term_name
					end
				end

				return result
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

--- Focuses on toggleterm's current origin window without closing telescope (the use of noautocmd prevents the
--- telescope prompt from automatically closing). Useful for actions where exit_on_action is false.
function M.focus_on_origin_win()
	local window = toggleterm_ui.get_origin_window()
	vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", window))
end

--- Focus on the telescope prompt buffer window. Useful for actions where exit_on_action is false. This would typically be called
--- after calling focus_on_origin_win and manipulating terminal buffers (i.e. open, close, create).
--- @param prompt_bufnr number The buffer number of the telescope prompt.
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

--- Focus on the open telescope buffer and refresh the picker so the changes to the terminal buffers caused by an action in
--- actions/init.lua are reflected in telescope.
--- @param prompt_bufnr number The buffer number of the prompt.
--- @param selection table The current selection object.
--- @param deleted boolean|nil A boolean indicating if the selection was deleted.
function M.refresh_picker(prompt_bufnr, selection, deleted)
	local current_picker = actions_state.get_current_picker(prompt_bufnr)
	local finder, new_row_number = M.create_finder(selection.id)

	-- If an item has been deleted, we need to adjust the row number
	if deleted and selection.index > 1 then
		new_row_number = selection.index - 2
	end

	current_picker:refresh(finder, { reset_prompt = false })
	M.set_selection_row(current_picker, new_row_number)

	if not deleted then
		-- Update the telescope picker's original window id to the term window id that was just created
		current_picker.original_win_id = selection.window
	end
end

--- Set the selection row in the telescope picker. Useful for keeping the selection on the current entry after an action in
--- actions/init.lua is run and refresh_picker is run.
--- @param picker table The telescope picker object.
--- @param row_number number The row number to set the selection to.
function M.set_selection_row(picker, row_number)
	local current_row = picker:get_selection_row()

	-- Registering a callback is necessary to call set_selection after calling the
	-- refresh method. Otherwise, because of the async behavior of refresh, set_selection will be called before the refresh is complete
	-- and the selection will just move to the first entry
	local callbacks = { unpack(picker._completion_callbacks) } -- shallow copy
	picker:register_completion_callback(function(self)
		self:set_selection(row_number or current_row)
		self._completion_callbacks = callbacks
	end)
end

--- Clear the command line after naming a toggleterm terminal.
function M.clear_command_line()
	vim.cmd("echo ''")
end

--- Start insert mode.
function M.start_insert_mode()
	vim.schedule(function()
		vim.cmd("startinsert!")
	end)
end

return M
