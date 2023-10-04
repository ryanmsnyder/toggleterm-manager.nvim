local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")
local strings = require("plenary.strings")
local Path = require("plenary.path")
local make_entry = require("telescope.make_entry")

local M = {}

-- TODO: cache this so it's not run everytime
local function results_formatter(opts)
	opts = opts or {}

	local config = require("config").options

	local disable_devicons = opts.disable_devicons
	local icon_width = 0
	local icon, hl_group
	if not disable_devicons then
		icon, hl_group = utils.get_devicons(".terminal", disable_devicons)
		icon_width = strings.strdisplaywidth(icon)
	end

	local items = {}
	for index, value in ipairs(config.results_format) do
		if value == "flag" then
			table.insert(items, index, { width = 4 })
		elseif value == "bufnr" then
			table.insert(items, index, { width = opts.max_bufnr_width })
		elseif value == "term_name" then
			table.insert(items, index, { width = opts.toggle_name_width })

			-- if user config set term_name_icon = true
			if config.term_name_icon then
				table.insert(items, index, { width = icon_width })
			end
		end

		-- if last iteration then replace last element of items table with remaining = true
		if index == #config.results_format then
			items[#items] = { remaining = true }
		end
	end

	local display_formatter = function(entry)
		entry = entry or {}

		local displayer_table = {}
		local display_bufname = utils.transform_path(opts, entry.filename)

		for index, value in ipairs(config.results_format) do
			if value == "flag" then
				table.insert(displayer_table, index, { entry.indicator, "TelescopeResultsComment" })
			elseif value == "bufnr" then
				-- DELETE
				local path_to_desktop = "/Users/ryan.snyder/Desktop/max_bufnr_width_displayer.txt"
				local file = io.open(path_to_desktop, "a") -- "a" means append mode
				if not file then
					vim.api.nvim_err_writeln("Failed to open debug file for writing.")
					return
				end
				file:write("max_bufnr_width: " .. (opts.max_bufnr_width and opts.max_bufnr_width or "") .. "\n") -- Write the content and a newline
				-- DELETE
				local leading_spaces = opts.max_bufnr_width
						and string.rep(" ", opts.max_bufnr_width - #tostring(entry.bufnr))
					or "" -- for right aligning the bufnr's
				-- table.insert(displayer_table, index, { leading_spaces .. tostring(entry.bufnr), "TelescopeResultsNumber" })
				table.insert(
					displayer_table,
					index,
					{ leading_spaces .. tostring(entry.bufnr), "TelescopeResultsNumber" }
				)
				file:write(
					"number leading spaces: "
						.. (opts.max_bufnr_width and (opts.max_bufnr_width - #tostring(entry.bufnr)) or "")
						.. "\n"
				)
				file:close()
			elseif value == "term_name" then
				table.insert(displayer_table, index, entry.ordinal)

				-- if user config set term_name_icon = true
				if config.term_name_icon then
					table.insert(displayer_table, index, { icon, hl_group })
				end
			end
		end

		return displayer_table
	end

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
		separator = " ",
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
