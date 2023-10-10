local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")
local strings = require("plenary.strings")
local Path = require("plenary.path")
local make_entry = require("telescope.make_entry")
local config = require("config").options

local M = {}

local function process_results_config(target_table, action)
	for _, configItem in ipairs(config.results_format) do
		-- if value in results_config is a table (contains the column type and highlight group)
		local col
		if type(configItem) == "table" then
			col = configItem[1]
		else
			col = configItem
		end
		if col == "indicator" then
			table.insert(target_table, action.indicator)
		elseif col == "bufnr" then
			table.insert(target_table, action.bufnr)
		elseif col == "display_bufname" then
			table.insert(target_table, action.display_bufname)
		elseif col == "term_name" then
			table.insert(target_table, action.term_name)
		elseif col == "term_icon" then
			table.insert(target_table, action.term_icon)
		elseif col == "space" then
			local prevValue = target_table[#target_table]
			if prevValue and type(prevValue) == "table" and prevValue.width then
				prevValue.width = prevValue.width + 1
			end
		end

		-- if the target_table is the displayer_table and the value just inserted was a table, replace the second item of the
		-- value (the highlight group) with the highlight group that the user provided in the config
		local currentValue = target_table[#target_table]
		if currentValue and type(currentValue) == "table" and not currentValue.width then
			currentValue[2] = configItem[2]
		end
	end
end

local function results_formatter(opts)
	opts = opts or {}

	local items = {}

	local disable_devicons = opts.disable_devicons
	local icon_width = 0
	local icon, hl_group
	if not disable_devicons then
		icon, hl_group = utils.get_devicons(".terminal", disable_devicons)
		icon_width = strings.strdisplaywidth(icon)
	end

	local items_action = {
		indicator = { width = (opts.flag_exists and 2 or 1) },
		bufnr = { width = opts.max_bufnr_width },
		term_name = { width = opts.toggle_name_width },
		term_icon = { width = icon_width },
		display_bufname = { width = opts.max_bufname_width },
	}

	process_results_config(items, items_action)
	-- replace last element of items table with remaining = true
	items[#items] = { remaining = true }

	local display_formatter = function(entry)
		entry = entry or {}

		local displayer_table = {}
		local display_bufname = utils.transform_path(opts, entry.filename)

		local bufnr_leading_spaces = opts.max_bufnr_width
				and string.rep(" ", opts.max_bufnr_width - #tostring(entry.bufnr))
			or "" -- for right aligning bufnr column
		local indicator_leading_spaces = opts.flag_exists and #entry.indicator == 1 and " " or "" -- for right aligning indicator column
		local displayer_action = {
			indicator = { indicator_leading_spaces .. entry.indicator, "TelescopeResultsComment" },
			bufnr = { bufnr_leading_spaces .. tostring(entry.bufnr), "TelescopeResultsNumber" },
			display_bufname = { display_bufname, "Normal" },
			term_name = { entry.ordinal, "Normal" },
			term_icon = { icon, hl_group },
		}
		process_results_config(displayer_table, displayer_action)
		-- DELETE
		local path_to_desktop = "/Users/ryan.snyder/Desktop/displayer_table.txt"
		local file = io.open(path_to_desktop, "a") -- "a" means append mode
		if not file then
			vim.api.nvim_err_writeln("Failed to open debug file for writing.")
			return
		end
		file:write(vim.inspect(displayer_table) .. "\n") -- Write the content and a newline
		file:close()
		-- DELETE

		return displayer_table
	end

	-- DELETE
	local path_to_desktop = "/Users/ryan.snyder/Desktop/items.txt"
	local file = io.open(path_to_desktop, "a") -- "a" means append mode
	if not file then
		vim.api.nvim_err_writeln("Failed to open debug file for writing.")
		return
	end
	file:write(vim.inspect(items) .. "\n") -- Write the content and a newline
	file:close()
	-- DELETE

	return items, display_formatter
end

function M.gen_displayer(opts)
	opts = opts or {}

	local items, create_display_table = results_formatter(opts)

	local disable_devicons = opts.disable_devicons

	local icon_width = 0
	if not disable_devicons then
		local icon, _ = utils.get_devicons("fname", disable_devicons)
		icon_width = strings.strdisplaywidth(icon)
	end

	local displayer = entry_display.create({
		separator = config.separator,
		items = items,
	})

	local cwd = vim.fn.expand(opts.cwd or vim.loop.cwd())

	local make_display = function(entry)
		-- max_bufnr_width + modes + icon + 3 spaces + : + lnum
		-- opts.__prefix = opts.max_bufnr_width + 4 + icon_width + 3 + 1 + #tostring(entry.lnum)
		-- TODO: make a conditional statement that calculates the prefix based on the user's results_format
		opts.__prefix = opts.max_bufnr_width + 4 + icon_width + 3 + 1

		return displayer(create_display_table(entry))
	end

	return function(entry)
		local bufname = entry.info.name ~= "" and entry.info.name or "No Name"
		-- if bufname is inside the cwd, trim that part of the string
		bufname = Path:new(bufname):normalize(cwd)

		local hidden = entry.info.hidden == 1 and "h" or "a"
		-- local readonly = vim.api.nvim_buf_get_option(entry.bufnr, "readonly") and "=" or " "
		-- local changed = entry.info.changed == 1 and "+" or " "
		-- local indicator = entry.flag .. hidden .. readonly .. changed
		local indicator = entry.flag .. hidden
		local lnum = 1

		-- account for potentially stale lnum as getbufinfo might not be updated or from resuming buffers picker
		if entry.info.lnum ~= 0 then
			-- but make sure the buffer is loaded, otherwise line_count is 0
			if vim.api.nvim_buf_is_loaded(entry.bufnr) then
				local line_count = vim.api.nvim_buf_line_count(entry.bufnr)
				lnum = math.max(math.min(entry.info.lnum, line_count), 1)
			else
				lnum = entry.info.lnum
			end
		end

		return make_entry.set_default_entry_mt({
			-- value = bufname,
			value = entry,
			-- ordinal = entry.bufnr .. " : " .. bufname,
			ordinal = entry.term_name, -- for filtering
			display = make_display,

			bufnr = entry.bufnr,
			filename = bufname,
			lnum = lnum,
			indicator = indicator,
		}, opts)
	end
end
return M
