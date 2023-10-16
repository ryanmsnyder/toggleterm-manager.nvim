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

function M.delete_terminal(prompt_bufnr)
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

function M.rename_terminal(prompt_bufnr)
	actions.close(prompt_bufnr) -- close telescope
	local selection = actions_state.get_selected_entry()
	if selection == nil then
		return
	end

	local toggle_number = selection.value.info.variables.toggle_number
	local term = require("toggleterm.terminal").get(toggle_number, false)

	local prompt = string.format("Rename terminal %s: ", term.display_name or toggle_number)
	vim.ui.input({ prompt = prompt }, function(name)
		if name and #name > 0 then
			term.display_name = name
			vim.cmd("echo ''") -- clear commandline
		end
	end)
end

return M
