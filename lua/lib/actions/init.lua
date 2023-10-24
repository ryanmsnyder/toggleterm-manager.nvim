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

-- function M.exit_terminal(prompt_bufnr)
-- 	local selection = actions_state.get_selected_entry()
-- 	if selection == nil then
-- 		return
-- 	end
-- 	local bufnr = selection.value.bufnr
-- 	local current_picker = actions_state.get_current_picker(prompt_bufnr)
-- 	current_picker:delete_selection(function(selection)
-- 		vim.api.nvim_buf_delete(bufnr, { force = true })
-- 	end)
-- end

-- function M.new_terminal(prompt_bufnr, exit_on_action)
-- 	-- create terminal
--
-- 	local current_picker = actions_state.get_current_picker(prompt_bufnr)
-- 	local current_row = current_picker:get_selection_row()
--
-- 	actions.close(prompt_bufnr)
-- 	local Terminal = require("toggleterm.terminal").Terminal
-- 	local term = Terminal:new({ hidden = false })
-- 	term:toggle()
-- 	--------------------------
-- 	-- local desktopPath = os.getenv("HOME") .. "/Desktop/debug.txt"
-- 	-- local file, err = io.open(desktopPath, "w")
-- 	-- if not file then
-- 	-- 	print("Error opening file:", err)
-- 	-- 	return
-- 	-- end
-- 	-- file:write(vim.inspect(term) .. "\n")
-- 	-- file:close()
-- 	--------------------------
-- 	if not exit_on_action then
-- 		vim.cmd("Telescope toggleterm")
--
-- 		-- require("telescope.builtin").resume()
-- 		-- open_telescope()
-- 		-- vim.cmd("Telescope resume")
-- 		-- current_picker:refresh
-- 	end
-- end
function M.create_terminal(prompt_bufnr, exit_on_action)
	local current_picker = actions_state.get_current_picker(prompt_bufnr)

	local Terminal = require("toggleterm.terminal").Terminal

	local term = Terminal:new({
		-- called when the terminal is opened in any way (i.e. term:open())
		on_open = function(term)
			if not exit_on_action then
				vim.schedule(function()
					-- set origin window to current term before switching back to telescope
					-- this ensures the cursor is moved to the correct term window after closing a term
					require("toggleterm.ui").set_origin_window()
					focus_on_telescope(prompt_bufnr)
					current_picker:refresh(util.create_finder(), { reset_prompt = false })

					vim.api.nvim_create_augroup("InsertOnPickerLeave", {})
					vim.api.nvim_create_autocmd("BufLeave", {
						buffer = prompt_bufnr,
						group = "InsertOnPickerLeave",
						nested = true,
						once = true,
						callback = function()
							vim.schedule(function()
								vim.cmd("startinsert!")
							end)
						end,
					})
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
		local window = require("toggleterm.ui").get_origin_window()
		vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", window))
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

		-- vim.api.nvim_buf_delete(selection.bufnr, { force = true })
		local force = vim.api.nvim_buf_get_option(selection.bufnr, "buftype") == "terminal"
		file:write("force: " .. tostring(force) .. "\n")

		local ok = pcall(vim.api.nvim_buf_delete, selection.bufnr, { force = force })

		file:write("ok: " .. tostring(ok) .. "\n")
		file:close()
		return ok
	end)

	if exit_on_action then
		actions.close(prompt_bufnr)
	end
end

function M.rename_terminal(prompt_bufnr, exit_on_action)
	local selection = actions_state.get_selected_entry()
	if selection == nil then
		return
	end

	local toggle_number = selection.value.info.variables.toggle_number
	local term = require("toggleterm.terminal").get(toggle_number, false)

	local prompt = string.format("Rename terminal %s: ", term.display_name or toggle_number)
	vim.ui.input({ prompt = prompt }, function(name)
		if name and #name > 0 then
			-- rename terminal within toggleterm
			term.display_name = name

			if exit_on_action then
				actions.close(prompt_bufnr)
			else
				-- refresh name within telescope results
				selection.term_name = name
				selection.ordinal = name

				local current_picker = actions_state.get_current_picker(prompt_bufnr)
				local current_row = current_picker:get_selection_row()
				current_picker:refresh(current_picker.finder, { reset_prompt = false })

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

	local bufnr = tostring(selection.value.bufnr)
	local toggle_number = selection.value.info.variables.toggle_number

	if exit_on_action then
		actions.close(prompt_bufnr) -- close telescope
		require("toggleterm").toggle_command(bufnr, toggle_number)

		-- if the terminal was hidden and then toggled on, enter insert mode
		if selection.value.info.hidden == 1 then
			vim.defer_fn(function()
				vim.cmd("startinsert")
			end, 0)
		end
	else
		-- prevent autocmds from running while executing toggle_command
		-- this prevents the telescope prompt from automatically closing when a toggleterm terminal is toggled open,
		-- which would normally move the focus to the terminal window, thereby closing the telescope prompt automatically
		vim.cmd(string.format('noautocmd lua require("toggleterm").toggle_command("%s", %s)', bufnr, toggle_number))

		-- the focus will be moved to the toggleterm window when toggle_command is called so we need to move the focus
		-- back to the telescope prompt
		focus_on_telescope(prompt_bufnr)

		current_picker:refresh(util.create_finder(), { reset_prompt = false })
	end
end

return M
