<p align="center">
A Telescope extension to manage toggleterm's terminal buffers
</p>

## ✨ Features

- List and switch between all terminal buffers opened with `toggleterm.nvim`
- Easily customize the appearance of the Telescope window
- Map pre-defined actions to keybindings
- Open buffer picker with `:Telescope toggleterm_manager`
or `lua require('telescope-toggleterm').open()`

## ⚡ Requirements

- [`telescope`](https://github.com/nvim-telescope/telescope.nvim) plugin.
- [`nvim-toggleterm`](https://github.com/akinsho/nvim-toggleterm.lua) plugin.

## 🛠️ Quickstart 

Install using [ `lazy.nvim` ](https://github.com/folke/lazy.nvim) in lua:

```lua
{
  "ryanmsnyder/toggleterm-manager.nvim",
  event = "TermOpen",
  dependencies = {
     "akinsho/nvim-toggleterm.lua",
     "nvim-telescope/telescope.nvim",
     "nvim-lua/popup.nvim",
     "nvim-lua/plenary.nvim",
  },
  config = require("toggleterm-manager").setup()
}
```

Open `toggleterm-manager` by either:
- running the command `:Telescope toggleterm_manager`
- calling `lua require('toggleterm-manager').open()`

Keep reading if you want to change the default configuration.

## ⚙️ Configuration

### Defaults

By default, the below table is passed to the `setup` function:

```lua
{
	mappings = {}, -- key mappings bound inside the telescope window
    telescope_titles = {
        preview = "Preview", -- title of the preview buffer in telescope
        prompt = " Pick Term", -- title of the prompt buffer in telescope
        results = "Results", -- title of the results buffer in telescope
    },
    results = {
        fields = {
            "state",
            "space",
            "term_icon",
            "term_name",
    	},
	    separator = " ", -- the character that will be used to separate each field provided in results_format
        term_icon = "", -- the icon that will be used for the term_icon in results_format

    },
    search = {
        field = "term_name" -- the field that telescope fuzzy search will use
    },
	sort = {
		field = "term_name", -- the field that will be used for sorting in the telesocpe results
		ascending = true, -- whether or not the field provided above will be sorted in ascending or descending order
	},
}
```

| Property           | Type                           | Default Value                                           | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
|--------------------|--------------------------------|---------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **mappings**       | `table`                        |                                                         | A table of key mappings for different modes. Each mode (like 'i' for insert mode, 'n' for normal mode) is a key in the table and maps to another table, where the key is the key combination (e.g., "<CR>") and the value is a table with the fields 'action' and 'exit_on_action'. The 'action' field is a function that will be called when the key combination is pressed, and 'exit_on_action' is a boolean that determines whether telescope should be exited after the action is performed. |
| **telescope_titles.preview**  | `string`                       | "Preview"                                               | Title of the preview buffer in telescope. Any string.                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| **telescope_titles.prompt**   | `string`                       | " Pick Term"                                           | Title of the prompt buffer in telescope. Any string.                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| **telescope_titles.results**  | `string`                       | "Results"                                               | Title of the results buffer in telescope. Any string.                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| **results.separator**      | `string`                       | " "                                                     | The character used to separate each field in `results_format`. Any string, though a space character and a pipe character are the most commonly used.                                                                                                                                                                                                                                                                                                                                              |
| **results.fields** | `{string\|{string, string}}[]` | {   "state",   "space",   "term_icon",   "term_name", } | The format and order of the results displayed in the telescope buffer. This accepts a table where each element is either:  an acceptable string a table of tuple-like tables where the first value in the tuple is one of the acceptable strings and the second is a valid NeoVim highlight group that the column should adhere to.  The acceptable strings are: `bufname`, `bufnr`, `space`, `state`, `term_name`, `term_icon`. See results_format for more info.                                |
| **results.term_icon**      | `string`                       | ""                                                     | The icon used for `term_icon` in `results_format`. Any string.                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **search.field**   | `string`                       | "term_name"                                             | The field that telescope's fuzzy search will use. Doesn't need to be a value provided in `results_format`. Valid strings are: `bufname`, `bufnr`, `state`, `term_name`.                                                                                                                                                                                                                                                                                                                           |
| **sort.field**     | `table`                        | "term_name"                                             | The field that will be used for sorting the results in telescope. Doesn't need to be a value provided in  `results_format`. Valid strings are: `bufnr`, `recency`, `state`, `term_name`.                                                                                                                                                                                                                                                                                                          |
| **sort.ascending** | `boolean`                      | true                                                    | Determines the order used for sorting the telescope results. `true` = ascending, `false` = descending.                                                                                                                                                                                                                                                                                                                                                                                            |


### `results_format`

This propery allows for easy customization of how the terminal buffers appear in the telescope window.
