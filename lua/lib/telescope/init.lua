local pickers, finders, telescope_actions, actions_state, conf
if pcall(require, "telescope") then
	pickers = require("telescope.pickers")
	finders = require("telescope.finders")
	telescope_actions = require("telescope.actions")
	actions_state = require("telescope.actions.state")
	conf = require("telescope.config").values
else
	error("Cannot find telescope!")
end
local status_ok, _ = pcall(require, "toggleterm")
if not status_ok then
	error("Cannot find toggleterm!")
end
local util = require("util")
local actions = require("lib.actions")

local M = {}
M.open = function(opts)
	local config = require("config").options

	-- set origin window, which will need to be retrieved in some actions (actions/init.lua)
	require("toggleterm.ui").set_origin_window()

	-- vim.api.nvim_create_augroup("InsertOnPickerLeave", {})
	-- vim.api.nvim_create_autocmd("BufLeave", {
	-- 	buffer = prompt_bufnr,
	-- 	group = "InsertOnPickerLeave",
	-- 	nested = true,
	-- 	once = true,
	-- 	callback = function()
	-- 		vim.schedule(function()
	-- 			-- if vim.bo.ft == "toggleterm" then
	-- 			vim.cmd("startinsert!")
	-- 			-- end
	-- 		end)
	-- 	end,
	-- })

	local picker = pickers.new(opts, {
		prompt_title = config.prompt_title,
		results_title = config.display_mappings and util.format_results_title(config.mappings) or config.results_title,
		preview_title = config.preview_title,
		previewer = conf.grep_previewer(opts),
		-- finder = finders.new_table({
		-- 	results = buffers,
		-- 	entry_maker = displayer(entry_maker_opts),
		-- }),
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

			telescope_actions.select_default:replace(function()
				-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, true, true), "i", true)

				-- actions.toggle_terminal(prompt_bufnr)
				-- telescope_actions.close(prompt_bufnr) -- close telescope
				-- local selection = actions_state.get_selected_entry()
				-- if selection == nil then
				-- 	return
				-- end
				-- local bufnr = tostring(selection.value.bufnr)
				-- local toggle_number = selection.value.info.variables.toggle_number
				-- require("toggleterm").toggle_command(bufnr, toggle_number)
				--
				-- --------------------------
				-- local desktopPath = os.getenv("HOME") .. "/Desktop/new.txt"
				-- local file, err = io.open(desktopPath, "a")
				-- if not file then
				-- 	print("Error opening file:", err)
				-- 	return
				-- end
				-- file:write(vim.inspect(selection) .. "\n")
				-- file:close()
				-- -- selection.value:focus()
				-- --------------------------
				-- -- if selection.value:is_open() then
				-- -- 	selection.value:focus()
				-- -- else
				-- -- 	selection.value:open()
				-- -- end
				--
				-- vim.defer_fn(function()
				-- 	vim.cmd("stopinsert")
				-- end, 0)
			end)

			-- mappings
			-- local mappings = config.mappings
			-- for keybind, action_tbl in pairs(mappings) do
			-- 	local action = action_tbl["action"]
			-- 	local exit_on_action = action_tbl["exit_on_action"]
			-- 	map("i", keybind, function()
			-- 		action(prompt_bufnr, exit_on_action)
			-- 	end)
			-- end
			return true
		end,
	})
	picker:find()

	-- TODO: create config option called insert_on_exit
	vim.api.nvim_create_augroup("InsertOnPickerLeave", {})
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = picker.prompt_bufnr,
		group = "InsertOnPickerLeave",
		nested = true,
		once = true,
		callback = function()
			vim.schedule(function()
				local win_is_valid = vim.api.nvim_win_is_valid(picker.original_win_id)
				if win_is_valid then
					local picker_orig_win_bufnr = vim.fn.winbufnr(picker.original_win_id)
					local buftype = vim.api.nvim_buf_get_option(picker_orig_win_bufnr, "filetype")
					if buftype == "toggleterm" then
						vim.cmd("startinsert!")
					end
				end
			end)
		end,
	})
end
return M
