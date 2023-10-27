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

local function focus_on_telescope(prompt_bufnr)
	-- Go through all the windows
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		-- Check if the window's buffer is the one we're looking for
		if vim.api.nvim_win_get_buf(win) == prompt_bufnr then
			-- Set focus to that window
			-- print(win)
			vim.api.nvim_set_current_win(win)
			return
		end
	end
	print("Telescope buffer not visible in any window")
end

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
					focus_on_telescope(prompt_bufnr)
					current_picker:refresh(util.create_finder(false), { reset_prompt = false })

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

function M.delete_terminal(prompt_bufnr, exit_on_action)
	local current_picker = actions_state.get_current_picker(prompt_bufnr)
	current_picker:delete_selection(function(selection)
		--------------------------
		local desktopPath = os.getenv("HOME") .. "/Desktop/debug.txt"
		local file, err = io.open(desktopPath, "w")
		if not file then
			print("Error opening file:", err)
			return
		end
		file:write("prompt_bufnr:" .. prompt_bufnr .. "\n")
		file:write(vim.inspect(selection) .. "\n")
		--------------------------
		local force = vim.api.nvim_buf_get_option(selection.bufnr, "buftype") == "terminal"
		if exit_on_action then
			actions.close(prompt_bufnr)
			vim.api.nvim_buf_delete(selection.bufnr, { force = force })
			return
		end

		util.focus_on_origin_win()

		-- vim.api.nvim_buf_delete(selection.bufnr, { force = true })
		-- local force = vim.api.nvim_buf_get_option(selection.bufnr, "buftype") == "terminal"
		local ok = pcall(vim.api.nvim_buf_delete, selection.bufnr, { force = force })

		toggleterm_ui.set_origin_window()

		focus_on_telescope(prompt_bufnr)
		-- current_picker:refresh(util.create_finder(false), { reset_prompt = false })
		file:write("ok: " .. tostring(ok) .. "\n")
		file:close()
		return ok
	end)

	if exit_on_action then
	end
end

function M.rename_terminal(prompt_bufnr, exit_on_action)
	local selection = actions_state.get_selected_entry()
	if selection == nil then
		return
	end

	local term = selection.value

	local prompt = string.format("Rename terminal %s: ", selection.term_name)
	vim.ui.input({ prompt = prompt }, function(name)
		if name and #name > 0 then
			-- rename terminal within toggleterm
			term.display_name = name

			if exit_on_action then
				actions.close(prompt_bufnr)
			else
				local current_picker = actions_state.get_current_picker(prompt_bufnr)
				local current_row = current_picker:get_selection_row()
				-- current_picker:refresh(current_picker.finder, { reset_prompt = false })
				current_picker:refresh(util.create_finder(false), { reset_prompt = false })

				-- registering a callback is necessary to call set_selection (which is used to keep the selection on the entry
				-- that was just renamed in this case) after calling the refresh method. Otherwise, because of the async behavior
				-- of refresh, set_selection will be called before the refresh is complete and the selection will just move
				-- to the first entry
				local callbacks = { unpack(current_picker._completion_callbacks) } -- shallow copy
				current_picker:register_completion_callback(function(self)
					self:set_selection(current_row)
					self._completion_callbacks = callbacks
				end)
			end

			vim.cmd("echo ''") -- clear commandline
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

	focus_on_telescope(prompt_bufnr)
	current_picker:refresh(util.create_finder(false), { reset_prompt = false })
	util.set_selection_row(current_picker)

	current_picker.original_win_id = term.window
end

return M
