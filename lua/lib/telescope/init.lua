local pickers = require("telescope.pickers")
local telescope_actions = require("telescope.actions")
local conf = require("telescope.config").values
local util = require("util")

--- Create autocommand to enter insert mode when the cursor leaves the telescope buffer.
--- Useful for actions that are called with exit_on_action set to false b/c it allows the user
--- to manually exit telescope but still automatically enter insert mode in the terminal buffer
--- @param picker table The telescope picker object.
local function telescope_leave_autocmd(picker)
	vim.api.nvim_create_augroup("InsertOnPickerLeave", {})
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = picker.prompt_bufnr,
		group = "InsertOnPickerLeave",
		nested = true,
		once = true,
		callback = function()
			local desktopPath = os.getenv("HOME") .. "/Desktop/new.txt"
			local file, err = io.open(desktopPath, "a")
			if not file then
				print("Error opening file:", err)
				return
			end
			file:write("leave" .. "\n")

			local win_is_valid = vim.api.nvim_win_is_valid(picker.original_win_id)
			file:write("picker.original_win_id: " .. picker.original_win_id .. "\n")
			if win_is_valid then
				file:write("win_is_valid" .. "\n")
				local picker_orig_win_bufnr = vim.fn.winbufnr(picker.original_win_id)
				local buftype = vim.api.nvim_buf_get_option(picker_orig_win_bufnr, "filetype")
				file:write("buftype: " .. buftype .. "\n")
				if buftype == "toggleterm" then
					util.start_insert_mode()
				end
			end
			file:write("\n")
			file:close()
		end,
	})
end

local M = {}

--- Entry point. Opens a telescope picker.
--- @param opts table The options for the picker.
M.open = function(opts)
	local config = require("config").options
	-- set origin window, which will need to be retrieved in some actions (actions/init.lua)
	require("toggleterm.ui").set_origin_window()

	local picker = pickers.new(opts, {
		prompt_title = config.prompt_title,
		results_title = config.display_mappings and util.format_results_title(config.mappings) or config.results_title,
		preview_title = config.preview_title,
		previewer = conf.grep_previewer(opts),
		finder = util.create_finder(),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			local mappings = config.mappings
			for mode, mode_mappings in pairs(mappings) do
				for keybind, action_tbl in pairs(mode_mappings) do
					local action = action_tbl["action"]
					local exit_on_action = action_tbl["exit_on_action"]
					map(mode, keybind, function()
						action(prompt_bufnr, exit_on_action)
					end)
				end
			end

			telescope_actions.select_default:replace(function() end)

			return true
		end,
	})
	picker:find()
	telescope_leave_autocmd(picker)
end
return M
