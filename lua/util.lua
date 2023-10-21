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

return M
