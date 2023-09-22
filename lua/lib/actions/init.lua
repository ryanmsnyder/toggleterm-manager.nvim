local pickers, finders, actions, actions_state, conf
if pcall(require, "telescope") then
   pickers = require "telescope.pickers"
   finders = require "telescope.finders"
   actions = require "telescope.actions"
   actions_state = require "telescope.actions.state"
   conf = require("telescope.config").values
else
   error "Cannot find telescope!"
end
local M = {}
function M.exit_terminal(prompt_bufnr)
   local selection = actions_state.get_selected_entry()
   if selection == nil then
      return
   end
   local bufnr = selection.value.bufnr
   local current_picker = actions_state.get_current_picker(prompt_bufnr)
   current_picker:delete_selection(function(selection)
      vim.api.nvim_buf_delete(bufnr, { force = true })
   end)
end
return M
