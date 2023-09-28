local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")
local strings = require("plenary.strings")
local Path = require("plenary.path")
local make_entry = require("telescope.make_entry")

local M = {}

function M.gen_displayer(opts)
	opts = opts or {}

	local disable_devicons = opts.disable_devicons

	local icon_width = 0
	if not disable_devicons then
		local icon, _ = utils.get_devicons("fname", disable_devicons)
		icon_width = strings.strdisplaywidth(icon)
	end

	local displayer = entry_display.create({
		separator = " ",
		items = {
			-- { width = opts.bufnr_width },
			{ width = 4 },
			{ width = icon_width },
			{ remaining = true },
		},
	})

	local cwd = vim.fn.expand(opts.cwd or vim.loop.cwd())

	local make_display = function(entry)
		-- bufnr_width + modes + icon + 3 spaces + : + lnum
		-- opts.__prefix = opts.bufnr_width + 4 + icon_width + 3 + 1 + #tostring(entry.lnum)
		opts.__prefix = opts.bufnr_width + 4 + icon_width + 3 + 1
		local display_bufname = utils.transform_path(opts, entry.filename)
		local icon, hl_group = utils.get_devicons(".terminal", disable_devicons)

		-- local term_number = vim.api.nvim_buf_get_var(entry.bufnr, "toggle_number")
		-- local display_name = require("toggleterm.terminal").get(term_number, false).display_name
		-- local term_name = display_name or term_number -- number icon if id is less than 11

		return displayer({
			-- { entry.bufnr, "TelescopeResultsNumber" },
			-- { display_bufname, "TelescopeResultsNumber" },
			-- { term_name, "TelescopeResultsNumber" },
			{ entry.indicator, "TelescopeResultsComment" },
			{ icon, hl_group },
			entry.ordinal, -- term_name
			-- display_bufname
			-- 	.. ":"
			-- 	.. entry.lnum,
			-- entry.filename,
		})
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
