local finders = require("telescope.finders")

local M = {}

local function_name_to_description = {
	delete_terminal = "Delete term",
	rename_terminal = "Rename term",
	-- Add other mappings as needed
}

function M.format_results_title(mappings)
	local telescope_toggleterm_actions = require("telescope-toggleterm").actions
	local mapping_descriptions = {}

	for mapping, action_tbl in pairs(mappings) do
		local key = mapping:match("<(.-)>")
		local func_name
		local action = action_tbl["action"]

		for action_name, action_func in pairs(telescope_toggleterm_actions) do
			if action == action_func then
				func_name = action_name
				break
			end
		end

		if func_name and function_name_to_description[func_name] then
			local description = string.format("%s: %s", key, function_name_to_description[func_name])
			table.insert(mapping_descriptions, description)
		end
	end

	return table.concat(mapping_descriptions, "  ")
end

function M.create_finder()
	local bufnrs = vim.tbl_filter(function(b)
		return vim.api.nvim_buf_get_option(b, "filetype") == "toggleterm"
	end, vim.api.nvim_list_bufs())

	-- if not next(bufnrs) then
	-- 	print("no terminal buffers are opened/hidden")
	-- 	return
	-- end

	if not next(bufnrs) then
		print("no terminal buffers are opened/hidden")
		-- return
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
			term_name = term_name,
			info = info,
		}
		table.insert(buffers, element)
	end

	local max_toggleterm_name_length = #bufnrs > 0 and math.max(unpack(term_name_lengths))
	entry_maker_opts.max_term_name_width = max_toggleterm_name_length

	local max_bufnr = #bufnrs > 0 and math.max(unpack(bufnrs))
	entry_maker_opts.max_bufnr_width = #tostring(max_bufnr)

	local max_bufname = #bufnrs > 0 and math.max(unpack(bufname_lengths))
	entry_maker_opts.max_bufname_width = max_bufname

	local displayer = require("lib.displayer").gen_displayer

	return finders.new_table({
		results = buffers,
		entry_maker = displayer(entry_maker_opts),
	})
end

function M.prepare_data()
	local bufnrs = vim.tbl_filter(function(b)
		return vim.api.nvim_buf_get_option(b, "filetype") == "toggleterm"
	end, vim.api.nvim_list_bufs())

	if not next(bufnrs) then
		print("no terminal buffers are opened/hidden")
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
			term_name = term_name,
			info = info,
		}
		table.insert(buffers, element)
	end

	local max_toggleterm_name_length = #bufnrs > 0 and math.max(unpack(term_name_lengths))
	entry_maker_opts.max_term_name_width = max_toggleterm_name_length

	local max_bufnr = #bufnrs > 0 and math.max(unpack(bufnrs))
	entry_maker_opts.max_bufnr_width = #tostring(max_bufnr)

	local max_bufname = #bufnrs > 0 and math.max(unpack(bufname_lengths))
	entry_maker_opts.max_bufname_width = max_bufname

	-- Return the values that will be used in the open function
	return entry_maker_opts, buffers
end

return M
