local pickers, finders, actions, actions_state, conf
if pcall(require, "telescope") then
	pickers = require("telescope.pickers")
	finders = require("telescope.finders")
	actions = require("telescope.actions")
	actions_state = require("telescope.actions.state")
	conf = require("telescope.config").values
else
	error("Cannot find telescope!")
end
local toggleterm_ui = require("toggleterm.ui")
local util = require("util")

local M = {}

function M.create_terminal(prompt_bufnr, exit_on_action)
	local current_picker = actions_state.get_current_picker(prompt_bufnr)

	local Terminal = require("toggleterm.terminal").Terminal

	local term
	term = Terminal:new({
		-- called when the terminal is opened in any way (i.e. term:open())
		on_open = function()
			if not exit_on_action then
				vim.schedule(function()
					-- set origin window to current term before switching back to telescope
					-- this ensures the cursor is moved to the correct term window after closing a term
					toggleterm_ui.set_origin_window()
					util.focus_on_telescope(prompt_bufnr)
					local finder, new_row_number = util.create_finder(term.id)
					current_picker:refresh(finder, { reset_prompt = false })

					util.set_selection_row(current_picker, new_row_number)

					-- remove on_open callback after it's used to prevent side effects when opening the terminal
					-- in other actions
					term.on_open = nil
				end)
			end
		end,
	})

	if exit_on_action then
		actions.close(prompt_bufnr)
		vim.schedule(function()
			vim.cmd("startinsert!")
		end)
	else
		util.focus_on_origin_win()
	end
	term:open()

	-- update the telescope picker's original window id to the term window id that was just created
	-- this ensures that when telescope is exited manually, the cursor returns to the most recent terminal created
	current_picker.original_win_id = term.window
end

-- function M.delete_terminal(prompt_bufnr, exit_on_action)
-- 	local current_picker = actions_state.get_current_picker(prompt_bufnr)
-- 	current_picker:delete_selection(function(selection)
-- 		if selection == nil then
-- 			return
-- 		end
--
-- 		local term = selection.value
--
-- 		if exit_on_action then
-- 			actions.close(prompt_bufnr)
-- 			term:shutdown()
-- 			return
-- 		end
--
-- 		-- this prevents toggleterm from doing additional processing that would cause the telescope
-- 		-- window to close. Toggleterm's __handle_exit is called when a terminal buffer is deleted,
-- 		-- which calls term:close(). term.close() calls close_split(), which changes window focus
-- 		-- and causes telescope to exit. See toggleterm's terminal.lua:__handle_exit and ui.lua:close_split.
-- 		term.close_on_exit = false
--
-- 		-- util.focus_on_origin_win()
-- 		local force = vim.api.nvim_buf_get_option(selection.bufnr, "buftype") == "terminal"
-- 		local ok, err = pcall(function()
-- 			vim.api.nvim_buf_delete(selection.bufnr, { force = force })
-- 		end)
--
-- 		if not ok then
-- 			print("Error while deleting buffer:", err)
-- 		end
--
-- 		toggleterm_ui.set_origin_window()
-- 		-- util.focus_on_telescope(prompt_bufnr)
-- 		-- local finder, new_row_number = util.create_finder(term.id)
-- 		-- current_picker:refresh(finder, { reset_prompt = false })
-- 		-- util.set_selection_row(current_picker, new_row_number)
-- 	end)
-- end

function M.delete_terminal(prompt_bufnr, exit_on_action)
	local selection = actions_state.get_selected_entry()
	if selection == nil then
		return
	end

	local term = selection.value

	if exit_on_action then
		actions.close(prompt_bufnr)
		term:shutdown()
		return
	end

	-- this prevents toggleterm from doing additional processing that would cause the telescope
	-- window to close. Toggleterm's __handle_exit is called when a terminal buffer is deleted,
	-- which calls term:close(). term.close() calls close_split(), which changes window focus
	-- and causes telescope to exit. See toggleterm's terminal.lua:__handle_exit and ui.lua:close_split.
	term.close_on_exit = false

	util.focus_on_origin_win()
	local force = vim.api.nvim_buf_get_option(selection.bufnr, "buftype") == "terminal"
	local ok, err = pcall(function()
		vim.api.nvim_buf_delete(selection.bufnr, { force = force })
	end)

	if not ok then
		print("Error while deleting buffer:", err)
	end

	toggleterm_ui.set_origin_window()
	util.focus_on_telescope(prompt_bufnr)

	local current_picker = actions_state.get_current_picker(prompt_bufnr)
	local finder = util.create_finder(term.id)
	local new_row_number
	if selection.index > 1 then
		new_row_number = selection.index - 2
	else
		new_row_number = 0
	end
	current_picker:refresh(finder, { reset_prompt = false })
	util.set_selection_row(current_picker, new_row_number)
end

function M.rename_terminal(prompt_bufnr, exit_on_action)
	local selection = actions_state.get_selected_entry()
	if selection == nil then
		return
	end

	local term = selection.value

	local prompt = string.format("Rename terminal %s: ", selection.term_name)
	vim.ui.input({ prompt = prompt }, function(name)
		util.clear_command_line()
		if name and #name > 0 then
			-- rename terminal within toggleterm
			term._display_name = name

			if exit_on_action then
				actions.close(prompt_bufnr)
			else
				local current_picker = actions_state.get_current_picker(prompt_bufnr)
				local finder, new_row_number = util.create_finder(term.id)
				current_picker:refresh(finder, { reset_prompt = false })

				util.set_selection_row(current_picker, new_row_number)
			end
		end
	end)
end

function M.toggle_terminal(prompt_bufnr, exit_on_action)
	local current_picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)

	local selection = actions_state.get_selected_entry()
	if selection == nil then
		return
	end

	local term = selection.value

	util.focus_on_origin_win()
	-- toggleterm_ui.set_origin_window()
	if term:is_open() then
		term:close()
	else
		function open_term()
			term:open()
		end
		vim.cmd("noautocmd lua open_term()")
	end

	util.focus_on_telescope(prompt_bufnr)
	local finder, new_row_number = util.create_finder(term.id)
	current_picker:refresh(finder, { reset_prompt = false })

	util.set_selection_row(current_picker, new_row_number)

	current_picker.original_win_id = term.window
end

function M.create_and_name_terminal(prompt_bufnr, exit_on_action)
	local current_picker = actions_state.get_current_picker(prompt_bufnr)

	local prompt = "Name terminal: "

	vim.ui.input({ prompt = prompt }, function(name)
		util.clear_command_line()
		if name and #name > 0 then
			local Terminal = require("toggleterm.terminal").Terminal

			local term
			term = Terminal:new({
				display_name = name,
				-- called when the terminal is opened in any way (i.e. term:open())
				on_open = function()
					if not exit_on_action then
						vim.schedule(function()
							-- set origin window to current term before switching back to telescope
							-- this ensures the cursor is moved to the correct term window after closing a term
							toggleterm_ui.set_origin_window()
							util.focus_on_telescope(prompt_bufnr)

							local finder, new_row_number = util.create_finder(term.id)
							current_picker:refresh(finder, { reset_prompt = false })

							util.set_selection_row(current_picker, new_row_number)

							-- remove on_open callback after it's used to prevent side effects when opening the terminal
							-- in other actions
							term.on_open = nil
						end)
					end
				end,
			})

			if exit_on_action then
				actions.close(prompt_bufnr)
				vim.schedule(function()
					vim.cmd("startinsert!")
				end)
			else
				util.focus_on_origin_win()
			end
			term:open()

			-- update the telescope picker's original window id to the term window id that was just created
			-- this ensures that when telescope is exited manually, the cursor returns to the most recent terminal created
			current_picker.original_win_id = term.window
		end
	end)
end

return M
