local function results_formatter(opts, entry)
	local results_format = require("config").options.results_format

	local items = {}
	local displayer_table = {}
	for index, value in pairs(results_format) do
		if value == "flag" then
			table.insert(items, index, { width = 4 })
			table.insert(displayer_table, index, { entry.indicator, "telescoperesultscomment" })
		elseif value == "bufnr" then
			table.insert(items, index, { opts.bufnr_width })
			table.insert(displayer_table, index, { entry.bufnr, "telescoperesultsnumber" })
		elseif value == "term_name" then
			table.insert(items, index, { opts.toggle_name_width })
			table.insert(displayer_table, index, entry.ordinal)
		end
	end

	return items, displayer_table
end
