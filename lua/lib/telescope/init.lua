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
local status_ok, _ = pcall(require, "toggleterm")
if not status_ok then
	error("Cannot find toggleterm!")
end
local util = require("lib.util")

local M = {}
M.open = function(opts)
	local config = require("config").options

	local bufnrs = vim.tbl_filter(function(b)
		return vim.api.nvim_buf_get_option(b, "filetype") == "toggleterm"
	end, vim.api.nvim_list_bufs())

	if not next(bufnrs) then
		print("no terminal buffers are opened/hidden")
		return
	end

	table.sort(bufnrs, function(a, b)
		return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
	end)
	local entry_maker_opts = {}
	local buffers = {}
	local term_name_lengths = {}
	local bufname_lengths = {}
	for _, bufnr in ipairs(bufnrs) do
		local info = vim.fn.getbufinfo(bufnr)[1]
		local term_number = vim.api.nvim_buf_get_var(info.bufnr, "toggle_number")
		local display_name = require("toggleterm.terminal").get(term_number, false).display_name
		local term_name = display_name or tostring(term_number)

		table.insert(term_name_lengths, #term_name)
		table.insert(bufname_lengths, #info.name)

		local flag = (bufnr == vim.fn.bufnr("") and "%") or (bufnr == vim.fn.bufnr("#") and "#" or "")
		if flag ~= "" then
			entry_maker_opts.flag_exists = true
		end

		local element = {
			bufnr = bufnr,
			flag = flag,
			-- term_name = term_name,
			-- changed = info.changed,
			-- changedtick = info.changedtick,
			-- hidden = info.hidden,
			-- lastused = info.lastused,
			-- linecount = info.linecount,
			-- listed = info.listed,
			-- lnum = info.lnum,
			-- loaded = info.loaded,
			-- name = info.name,
			-- name = term_name,
			term_name = term_name,
			info = info,
			-- windows = info.windows,
			-- terminal_job_id = info.variables.terminal_job_id,
			-- terminal_job_pid = info.variables.terminal_job_pid,
			-- toggle_number = info.variables.toggle_number,
		}
		table.insert(buffers, element)
	end

	local max_toggleterm_name_length = math.max(unpack(term_name_lengths))
	entry_maker_opts.max_term_name_width = max_toggleterm_name_length

	local max_bufnr = math.max(unpack(bufnrs))
	entry_maker_opts.max_bufnr_width = #tostring(max_bufnr)

	local max_bufname = math.max(unpack(bufname_lengths))
	entry_maker_opts.max_bufname_width = max_bufname

	local displayer = require("lib.displayer").gen_displayer

	pickers
		.new(opts, {
			prompt_title = config.prompt_title,
			results_title = config.display_mappings and util.format_results_title(config.mappings)
				or config.results_title,
			preview_title = config.preview_title,
			previewer = conf.grep_previewer(opts),
			finder = finders.new_table({
				results = buffers,
				entry_maker = displayer(entry_maker_opts),
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr) -- close telescope
					local selection = actions_state.get_selected_entry()
					if selection == nil then
						return
					end
					local bufnr = tostring(selection.value.bufnr)
					local toggle_number = selection.value.info.variables.toggle_number
					require("toggleterm").toggle_command(bufnr, toggle_number)
					vim.defer_fn(function()
						vim.cmd("stopinsert")
					end, 0)
				end)

				-- mappings
				local mappings = config.mappings
				for keybind, action in pairs(mappings) do
					map("i", keybind, function()
						action(prompt_bufnr)
					end)
				end
				return true
			end,
		})
		:find()
end
return M
