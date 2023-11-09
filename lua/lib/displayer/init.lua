local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")
local strings = require("plenary.strings")
local make_entry = require("telescope.make_entry")
local config = require("config").options

local M = {}

local function process_results_config(target_table, insert_val)
	for _, configItem in ipairs(config.results.fields) do
		-- if value in results_config is a table (contains the column type and highlight group)
		local col
		if type(configItem) == "table" then
			col = configItem[1]
		else
			col = configItem
		end
		if col == "state" then
			table.insert(target_table, insert_val.state)
		elseif col == "bufnr" then
			table.insert(target_table, insert_val.bufnr)
		elseif col == "bufname" then
			table.insert(target_table, insert_val.bufname)
		elseif col == "term_name" then
			table.insert(target_table, insert_val.term_name)
		elseif col == "term_icon" then
			table.insert(target_table, insert_val.term_icon)
		elseif col == "space" then
			local prevValue = target_table[#target_table]
			if prevValue and type(prevValue) == "table" and prevValue.width then
				prevValue.width = prevValue.width + 1
			end
		end

		-- if the target_table is the displayer_table and the current config item iterable is a table, replace the second item of the
		-- value (the highlight group) with the highlight group that the user provided in the config
		local currentValue = target_table[#target_table]
		if currentValue and type(configItem) == "table" and not currentValue.width then
			currentValue[2] = configItem[2]
		end
	end
end

local function results_formatter(opts)
	opts = opts or {}

	local items = {}

	local icon_width = 0
	local term_icon = config.results.term_icon
	icon_width = strings.strdisplaywidth(term_icon)

	local items_col_widths = {
		bufname = { width = opts.max_bufname_width },
		bufnr = { width = opts.max_bufnr_width },
		state = { width = (opts.flag_exists and 2 or 1) },
		term_icon = { width = icon_width },
		term_name = { width = opts.max_term_name_width },
	}

	process_results_config(items, items_col_widths)
	-- replace last element of items table with remaining = true
	items[#items] = { remaining = true }

	local display_formatter = function(entry)
		entry = entry or {}

		local displayer_table = {}
		local display_bufname = utils.transform_path(opts, entry.filename)
		local _, hl_group = utils.get_devicons(".terminal", false)

		local bufnr_leading_spaces = opts.max_bufnr_width
				and string.rep(" ", opts.max_bufnr_width - #tostring(entry.bufnr))
			or "" -- for right aligning bufnr column
		local state_leading_spaces = opts.flag_exists and #entry.state == 1 and " " or "" -- for right aligning state column
		local displayer_col_vals = {
			bufname = { display_bufname, "TelescopeResultsIdentifier" },
			bufnr = { bufnr_leading_spaces .. tostring(entry.bufnr), "TelescopeResultsNumber" },
			state = { state_leading_spaces .. entry.state, "TelescopeResultsComment" },
			term_icon = { term_icon, hl_group },
			term_name = { entry.term_name },
		}
		process_results_config(displayer_table, displayer_col_vals)

		return displayer_table
	end

	return items, display_formatter
end

function M.displayer(opts)
	opts = opts or {}

	local items, create_display_table = results_formatter(opts)

	local displayer = entry_display.create({
		separator = config.results.separator,
		items = items,
	})

	local make_display = function(entry)
		return displayer(create_display_table(entry))
	end

	return function(entry)
		-- helper for mapping user config for search_field to the appropriate value
		local ordinal_values = {
			bufname = entry._bufname,
			bufnr = tostring(entry.bufnr),
			state = entry._state,
			term_name = entry._term_name,
		}

		return make_entry.set_default_entry_mt({
			value = entry,
			ordinal = ordinal_values[config.search.field], -- for filtering in telescope search
			display = make_display,
			bufnr = entry.bufnr,
			filename = entry._bufname,
			state = entry._state,
			term_name = entry._term_name,
		}, opts)
	end
end

return M
