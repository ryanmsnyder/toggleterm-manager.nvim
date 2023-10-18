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
local M = {}

local function set_term_name(name, term)
	term.display_name = name
end

function M.exit_terminal(prompt_bufnr)
	local selection = actions_state.get_selected_entry()
	if selection == nil then
		return
	end
	local bufnr = selection.value.bufnr
	local current_picker = actions_state.get_current_picker(prompt_bufnr)
	current_picker:delete_selection(function(selection)
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end

function M.delete_terminal(prompt_bufnr, exit_on_action)
	local current_picker = actions_state.get_current_picker(prompt_bufnr)
	current_picker:delete_selection(function(selection)
		vim.api.nvim_buf_delete(selection.bufnr, { force = true })
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

return M
