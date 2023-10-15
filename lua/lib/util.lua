local M = {}

local function_name_to_description = {
	exit_terminal = "Quit term",
	rename_terminal = "Rename term",
	-- Add other mappings as needed
}

function M.format_results_title(mappings)
	local telescope_toggleterm_actions = require("telescope-toggleterm").actions
	local mapping_descriptions = {}

	for k, v in pairs(mappings) do
		local key = k:match("<(.-)>")
		local func_name

		for action_name, action_func in pairs(telescope_toggleterm_actions) do
			if v == action_func then
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
