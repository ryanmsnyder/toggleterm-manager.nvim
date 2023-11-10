<p align="center">
A Telescope extension to manage toggleterm's terminal buffers
</p>

## ✨ Features

- List and switch between all terminal buffers opened with `toggleterm.nvim`
- Easily customize the appearance of the Telescope window
- Map pre-defined and custom actions to keybindings

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
	    separator = " ", -- the character that will be used to separate each field provided in results.fields 
        term_icon = "", -- the icon that will be used for the term_icon in results.fields

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
| **mappings**       | `table`                        |                                                         | A table of key mappings for different modes. Each mode (like 'i' for insert mode, 'n' for normal mode) is a key in the table and maps to another table, where the key is the key combination (e.g., "<CR>") and the value is a table with the fields 'action' and 'exit_on_action'. The 'action' field is a function that will be called when the key combination is pressed, and 'exit_on_action' is a boolean that determines whether telescope should be exited after the action is performed. See Mappings for more info. |
| **telescope_titles.preview**  | `string`                       | "Preview"                                               | Title of the preview buffer in telescope. Any string.                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| **telescope_titles.prompt**   | `string`                       | " Pick Term"                                           | Title of the prompt buffer in telescope. Any string.                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| **telescope_titles.results**  | `string`                       | "Results"                                               | Title of the results buffer in telescope. Any string.                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| **results.separator**      | `string`                       | " "                                                     | The character used to separate each field in `results.field`. Any string, though a space character and a pipe character are the most commonly used.                                                                                                                                                                                                                                                                                                                                              |
| **results.fields** | `{string\|{string, string}}[]` | {   "state",   "space",   "term_icon",   "term_name", } | The format and order of the results displayed in the telescope buffer. This accepts a table where each element is either:  an acceptable string a table of tuple-like tables where the first value in the tuple is one of the acceptable strings and the second is a valid NeoVim highlight group that the column should adhere to.  The acceptable strings are: `bufname`, `bufnr`, `space`, `state`, `term_name`, `term_icon`. See results for more info.                                |
| **results.term_icon**      | `string`                       | ""                                                     | The icon used for `term_icon` in `results.fields`. Any string.                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **search.field**   | `string`                       | "term_name"                                             | The field that telescope's fuzzy search will use. Doesn't need to be a value provided in `results.fields`. Valid strings are: `bufname`, `bufnr`, `state`, `term_name`.                                                                                                                                                                                                                                                                                                                           |
| **sort.field**     | `table`                        | "term_name"                                             | The field that will be used for sorting the results in telescope. Doesn't need to be a value provided in `results.fields`. Valid strings are: `bufnr`, `recency`, `state`, `term_name`.                                                                                                                                                                                                                                                                                                          |
| **sort.ascending** | `boolean`                      | true                                                    | Determines the order used for sorting the telescope results. `true` = ascending, `false` = descending.                                                                                                                                                                                                                                                                                                                                                                                            |
### Mappings

The `mappings` table should look something like this:

```lua
local toggleterm_manager = require("toggleterm-manager")
local actions = toggleterm_manager.actions

toggleterm_manager.setup {
	mappings = {
	    i = {
	      ["<CR>"] = { action = actions.open_term, exit_on_action = true },
	      ["<C-d>"] = { action = actions.delete_term, exit_on_action = false },
	    },
	    n = {
	      ["<CR>"] = { action = actions.open_term, exit_on_action = true },
	      ["x"] = { action = actions.delete_term, exit_on_action = false },
	    },
	},
}
```

Note that each key in the table should correspond to the NeoVim mode that the mappings should apply to (`i` for insert, `n` for normal). Each mode key should contain another table of key/value pairs where the key is the keybinding and the value is another table of key/value pairs. The valid keys of that table are `action`, which takes a function that manipulates a terminal in some way and `exit_on_action`, which determines if the telescope window should be closed on the execution of the action.

#### Actions

There are six pre-built actions that can be mapped to key bindings within the telescope window.

- `create_term`: Create a new terminal and open it. If `exit_on_action = true`, focus it. If `toggleterm`'s direction is `float` and `exit_on_action = false`, create a hidden terminal.
- `create_and_name_term`: Create and name a new terminal and open it. If `exit_on_action = true`, focus it. If `toggleterm`'s direction is `float` and `exit_on_action = false`, create a hidden terminal. The name will be reflected in the `term_name` field if it's provided in `results.field`.
- `rename_term`: Rename a terminal. If `exit_on_action = true` and the terminal is open, focus it. The name will be reflected in the `term_name` field if it's provided in `results.field`.
- `open_term`: Open a terminal. If `exit_on_action = true`, focus it. If `exit_on_action = false` and `toggleterm`'s direction is `float`, this action won't do anything.
- `toggle_term`: Toggle a terminal open or closed. If toggling open and `exit_on_action = true`, focus it.
- `delete_term`: Delete a terminal.

> [!Floating toggleterm windows]
> When configuring `toggleterm` (not `toggleterm-manager`), there is a property called `direction`, which takes a value of `horizontal`, `vertical`, or `float`. Some of the actions behave differently if `direction` is `float`. This is because of how NeoVim handles floating windows. Telescope is already a floating window so if, for example, `direction` is set to `float`, and the `create_term` action is called with `exit_on_action = false`, there would normally be a flash caused by opening a `toggleterm` float and switching back to telescope really fast. To prevent this, the `toggleterm` window will be created as a `hidden` terminal. Note that the `open_mapping` in `toggleterm` config won't be able to toggle these terminals open/closed.

#### Custom Actions

User-created functions can also be provided. Any function passed in as an action will receive two arguments: `prompt_bufnr` and `exit_on_action`.

```lua
local function my_custom_action(prompt_bufnr, exit_on_action)

end
```

See `actions/init.lua` for examples of creating actions.

### Results

The `results` property allows for easy customization of how toggleterm's terminal buffers appear in the telescope results buffer. `results.fields` allows for specifying the order that the results fields should appear, from left to right. Any combination and any number of the valid fields may be provided.

#### Valid Strings for `results.fields`

| Field       | Description                                                                                                                                        |
|-------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| `bufname`   | File name of the terminal buffer.                                                                                                                  |
| `bufnr`     | Buffer number of the terminal.                                                                                                                     |
| `space`     | Create additional space in between fields.                                                                                                         |
| `state`     | Current state of the terminal buffer. `h` = hidden, `a` = active                                                                                   |
| `term_icon` |  An icon of a terminal. This icon can be overridden with the `results.term_icon` property. |
| `term_name` | `toggleterm`'s `display_name` of the terminal, if assigned. Else, the `id`/`toggle_number` of the terminal assigned by `toggleterm` upon creation.                                                          |

#### Results Highlight Groups

The background and foreground colors of the results fields can also be customized by pairing any one of the above fields with a valid highlight group.

#### Examples

```lua
local toggleterm_manager = require("toggleterm-manager")
local actions = toggleterm_manager.actions

toggleterm_manager.setup {
	results = {
		fields = { "term_icon", "term_name", "space", "state" }
	},
}
```

Example of providing highlight groups:

```lua
results = {
	fields = { "state", "space", { "bufnr", "TelescopeResultsIdentifier" }, "space", "term_icon", { "bufname", "Function" }}
}
```
