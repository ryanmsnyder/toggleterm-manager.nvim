local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")
local toggleterm_ui = require("toggleterm.ui")
local toggleterm_config = require("toggleterm.config")
local utils = require("lib.utils")
local Terminal = require("toggleterm.terminal").Terminal

local M = {}

--- Create a new terminal and open it. If `exit_on_action = true`, focus it. If the term's direction is `float` and
--- `exit_on_action = false`, don't automatically open the terminal upon creation to prevent flashes.
--- @param prompt_bufnr number The buffer number of the telescope prompt.
--- @param exit_on_action boolean Whether to exit the telescope buffer when the action executes.
function M.create_term(prompt_bufnr, exit_on_action)
	local float = toggleterm_config.get("direction") == "float"

	-- forward declare `term` so it can be used inside `on_open_terminal`.
	local term

	local function on_open_terminal()
		if not exit_on_action then
			vim.schedule(function()
				-- set origin window to current term before switching back to telescope
				-- this ensures the cursor is moved to the correct term window after closing a term
				toggleterm_ui.set_origin_window()
				utils.focus_on_telescope(prompt_bufnr)
				utils.refresh_picker(prompt_bufnr, term)
				-- remove the on_open callback to avoid potential side effects in future actions.
				term.on_open = nil
			end)
		end
	end

	if exit_on_action then
		actions.close(prompt_bufnr)

		-- the autocommand setup in telescope/init.lua that starts insert mode on leaving the telescope buffer
		-- won't work here since the cursor may move to a non-toggleterm buftype for a brief moment while the
		-- toggleterm buffer is being created
		utils.start_insert_mode()
	end

	term = Terminal:new({ hidden = float, on_open = on_open_terminal })

	if float and exit_on_action then
		term:open()
	elseif float then
		term:spawn()
		utils.refresh_picker(prompt_bufnr, term)
		-- remove the on_open callback to avoid potential side effects in future actions.
		term.on_open = nil
	else
		utils.focus_on_origin_win()
		term:open()
	end
end

--- Create and name a new terminal and open it. If exit_on_action is true, focus it.
--- @param prompt_bufnr number The buffer number of the telescope prompt.
--- @param exit_on_action boolean Whether to exit the telescope buffer when the action executes.
function M.create_and_name_term(prompt_bufnr, exit_on_action)
	local float = toggleterm_config.get("direction") == "float"

	local prompt = "Name terminal: "

	vim.ui.input({ prompt = prompt }, function(name)
		utils.clear_command_line()
		if name and #name > 0 then
			local term
			local function on_open_terminal()
				if not exit_on_action then
					vim.schedule(function()
						-- set origin window to current term before switching back to telescope
						-- this ensures the cursor is moved to the correct term window after closing a term
						toggleterm_ui.set_origin_window()
						utils.focus_on_telescope(prompt_bufnr)
						utils.refresh_picker(prompt_bufnr, term)
						-- remove the on_open callback to avoid potential side effects in future actions.
						term.on_open = nil
					end)
				end
			end

			if exit_on_action then
				actions.close(prompt_bufnr)

				-- the autocommand setup in telescope/init.lua that starts insert mode on leaving the telescope buffer
				-- won't work here since the cursor may move to a non-toggleterm buftype for a brief moment while the
				-- toggleterm buffer is being created
				utils.start_insert_mode()
			end

			term = Terminal:new({ display_name = name, hidden = float, on_open = on_open_terminal })

			if float and exit_on_action then
				term:open()
			elseif float then
				term:spawn()
				utils.refresh_picker(prompt_bufnr, term)
				-- remove the on_open callback to avoid potential side effects in future actions.
				term.on_open = nil
			else
				utils.focus_on_origin_win()
				term:open()
			end
		end
	end)
end

--- Rename a terminal. If exit_on_action is true and the terminal is open, focus it.
--- @param prompt_bufnr number The buffer number of the telescope prompt.
--- @param exit_on_action boolean Whether to exit the telescope buffer when the action executes.
function M.rename_term(prompt_bufnr, exit_on_action)
	local selection = actions_state.get_selected_entry()
	if selection == nil then
		return
	end

	local term = selection.value

	local prompt = string.format("Rename terminal %s: ", selection.term_name)
	vim.ui.input({ prompt = prompt }, function(name)
		utils.clear_command_line()
		if name and #name > 0 then
			-- rename terminal within toggleterm
			term.display_name = name

			if exit_on_action then
				actions.close(prompt_bufnr)
				term:focus()
			else
				local current_picker = actions_state.get_current_picker(prompt_bufnr)
				local finder, new_row_number = utils.create_finder(term.id)
				current_picker:refresh(finder, { reset_prompt = false })

				utils.set_selection_row(current_picker, new_row_number)
			end
		end
	end)
end

--- Open a terminal. If exit_on_action is true, focus it.
--- @param prompt_bufnr number The buffer number of the telescope prompt.
--- @param exit_on_action boolean Whether to exit the telescope buffer when the action executes.
function M.open_term(prompt_bufnr, exit_on_action)
	local selection = actions_state.get_selected_entry()
	if selection == nil then
		return
	end

	local term = selection.value

	if exit_on_action then
		actions.close(prompt_bufnr)
		if not term:is_open() then
			term:open()
		end
		term:focus()
		utils.start_insert_mode()
		return
	end

	utils.focus_on_origin_win()
	if not term:is_open() then
		term:open()
	end

	utils.focus_on_telescope(prompt_bufnr)
	utils.refresh_picker(prompt_bufnr, term)
end

--- Toggle a terminal open or closed. If toggling open and exit_on_action is true, focus it.
--- @param prompt_bufnr number The buffer number of the telescope prompt.
--- @param exit_on_action boolean Whether to exit the telescope buffer when the action executes.
function M.toggle_term(prompt_bufnr, exit_on_action)
	local current_picker = actions_state.get_current_picker(prompt_bufnr)

	local selection = actions_state.get_selected_entry()
	if selection == nil then
		return
	end

	local term = selection.value

	if exit_on_action then
		actions.close(prompt_bufnr)
		term:toggle()
		utils.start_insert_mode()
		return
	end

	utils.focus_on_origin_win()
	if term:is_open() then
		term:close()
		current_picker.original_win_id = toggleterm_ui.get_origin_window()
	else
		term:open()
		current_picker.original_win_id = term.window
	end

	utils.focus_on_telescope(prompt_bufnr)
	utils.refresh_picker(prompt_bufnr, term)
end

--- Delete a terminal.
--- @param prompt_bufnr number The buffer number of the telescope prompt.
--- @param exit_on_action boolean Whether to exit the telescope buffer when the action executes.
function M.delete_term(prompt_bufnr, exit_on_action)
	local selection = actions_state.get_selected_entry()
	if selection == nil then
		return
	end

	local term = selection.value

	-- If exit_on_action is true, we want to close the picker and shutdown the terminal.
	if exit_on_action then
		actions.close(prompt_bufnr)
		term:shutdown()
		return
	end

	-- This prevents toggleterm from doing additional processing that would cause the telescope
	-- window to close. Toggleterm's __handle_exit is called when a terminal buffer is deleted,
	-- which calls term:close(). term.close() calls close_split(), which changes window focus
	-- and causes telescope to exit. See toggleterm's terminal.lua:__handle_exit and ui.lua:close_split.
	term.close_on_exit = false

	utils.focus_on_origin_win()

	local force = vim.api.nvim_buf_get_option(selection.bufnr, "buftype") == "terminal"

	utils.delete_buffer(selection.bufnr, force)

	toggleterm_ui.set_origin_window()

	utils.focus_on_telescope(prompt_bufnr)

	utils.refresh_picker(prompt_bufnr, selection, true)
end

return M
