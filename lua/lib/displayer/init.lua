local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")
local strings = require("plenary.strings")
local Path = require("plenary.path")
local make_entry = require("telescope.make_entry")

local M = {}

-- TODO: cache this so it's not run everytime
local function results_formatter(opts, entry)
	opts = opts or {}
	entry = entry or {}

	local config = require("config").options

	local disable_devicons = opts.disable_devicons

	local icon_width = 0
	local icon, hl_group
	if not disable_devicons then
		icon, hl_group = utils.get_devicons(".terminal", disable_devicons)
		icon_width = strings.strdisplaywidth(icon)
	end

	local display_bufname = utils.transform_path(opts, entry.filename)

	local items = {}
	local displayer_table = {}
	for index, value in pairs(config.results_format) do
		if value == "flag" then
			table.insert(items, index, { width = 4 })
			table.insert(displayer_table, index, { entry.indicator, "TelescopeResultsComment" })
		elseif value == "bufnr" then
			table.insert(items, index, { opts.bufnr_width })
			table.insert(displayer_table, index, { tostring(entry.bufnr), "TelescopeResultsNumber" })
		elseif value == "term_name" then
			table.insert(items, index, { opts.toggle_name_width })
			table.insert(displayer_table, index, entry.ordinal)

			if config.term_name_icon then
				table.insert(items, index, { width = icon_width })
				table.insert(displayer_table, index, { icon, hl_group })
			end
			-- elseif value == "bufname" then
			-- 	table.insert(items, index, { opts.toggle_name_width })
			-- 	table.insert(displayer_table, index, entry.ordinal)
			--
			-- 	if config.term_name_icon then
			-- 		table.insert(items, index, { width = icon_width })
			-- 		table.insert(displayer_table, index, { icon, hl_group })
			-- 	end
		end
	end

	return items, displayer_table
end

function M.gen_displayer(opts)
	opts = opts or {}

	local items, _ = results_formatter(opts)

	-- DELETE
	local path_to_desktop = "/Users/ryan.snyder/Desktop/debug.txt"
	local file = io.open(path_to_desktop, "a") -- "a" means append mode
	if not file then
		vim.api.nvim_err_writeln("Failed to open debug file for writing.")
		return
	end
	file:write(vim.inspect(items) .. "\n") -- Write the content and a newline
	file:close()
	-- DELETE

	local disable_devicons = opts.disable_devicons

	local icon_width = 0
	if not disable_devicons then
		local icon, _ = utils.get_devicons("fname", disable_devicons)
		icon_width = strings.strdisplaywidth(icon)
	end

	local displayer = entry_display.create({
		separator = " ",
		-- items = {
		-- 	-- { width = opts.bufnr_width },
		-- 	{ width = 4 },
		-- 	{ width = icon_width },
		-- 	{ remaining = true },
		-- },
		items = items,
	})

	local cwd = vim.fn.expand(opts.cwd or vim.loop.cwd())

	local make_display = function(entry)
		local _, displayer_table = results_formatter(nil, entry)

		local path = "/Users/ryan.snyder/Desktop/displayer_table.txt"

		local nfile = io.open(path, "a") -- "a" means append mode
		if not nfile then
			vim.api.nvim_err_writeln("Failed to open debug file for writing.")
			return
		end
		nfile:write(vim.inspect(displayer_table) .. "\n") -- Write the content and a newline
		nfile:close()

		-- bufnr_width + modes + icon + 3 spaces + : + lnum
		-- opts.__prefix = opts.bufnr_width + 4 + icon_width + 3 + 1 + #tostring(entry.lnum)
		-- TODO: make a conditional statement that calculates the prefix based on the user's results_format
		opts.__prefix = opts.bufnr_width + 4 + icon_width + 3 + 1

		-- return displayer({
		-- 	-- { entry.bufnr, "TelescopeResultsNumber" },
		-- 	-- { display_bufname, "TelescopeResultsNumber" },
		-- 	-- { term_name, "TelescopeResultsNumber" },
		-- 	{ entry.indicator, "TelescopeResultsComment" },
		-- 	{ icon, hl_group },
		-- 	entry.ordinal, -- term_name
		-- 	-- display_bufname
		-- 	-- 	.. ":"
		-- 	-- 	.. entry.lnum,
		-- 	-- entry.filename,
		-- })
		return displayer(displayer_table)
	end

	return function(entry)
		local bufname = entry.info.name ~= "" and entry.info.name or "[No Name]"
		-- if bufname is inside the cwd, trim that part of the string
		bufname = Path:new(bufname):normalize(cwd)

		local hidden = entry.info.hidden == 1 and "h" or "a"
		local readonly = vim.api.nvim_buf_get_option(entry.bufnr, "readonly") and "=" or " "
		local changed = entry.info.changed == 1 and "+" or " "
		local indicator = entry.flag .. hidden .. readonly .. changed
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
