<h1 align="center">
A Telescope extension to manage Toggleterm's terminals in NeoVim
</h1>

## ✨ Features

- List all terminal buffers
- Create, delete, toggle, and rename terminal buffers within the Telescope window
- Easily customize the appearance of the Telescope window

## 🛠️ Requirements

- [`telescope`](https://github.com/nvim-telescope/telescope.nvim) plugin
- [`toggleterm`](https://github.com/akinsho/nvim-toggleterm.lua) plugin

## ⚡ Quickstart

### Lazy

```lua
{
  "ryanmsnyder/toggleterm-manager.nvim",
  dependencies = {
     "akinsho/nvim-toggleterm.lua",
     "nvim-telescope/telescope.nvim",
     "nvim-lua/plenary.nvim",
  },
  config = function()
    require("toggleterm-manager").setup()
  end
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
    mappings = {
        i = {
            ["<CR>"] = { action = actions.toggle_term, exit_on_action = false }, -- toggles terminal open/closed
            ["<C-i>"] = { action = actions.create_term, exit_on_action = false }, -- creates a new terminal buffer
            ["<C-d>"] = { action = actions.delete_term, exit_on_action = false }, -- deletes a terminal buffer
            ["<C-r>"] = { action = actions.rename_term, exit_on_action = false }, -- provides a prompt to rename a terminal
        },
}, -- key mappings bound inside the telescope window
    telescope_titles = {
        preview = "Preview", -- title of the preview buffer in telescope
        prompt = " Terminals", -- title of the prompt buffer in telescope
        results = "Results", -- title of the results buffer in telescope
    },
    results = {
        fields = { -- fields that will appear in the results of the telescope window
            "state", -- the state of the terminal buffer: h = hidden, a = active
            "space", -- adds space between fields, if desired
            "term_icon", -- a terminal icon
            "term_name", -- toggleterm's display_name if it exists, else the terminal's id assigned by toggleterm
    	},
	    separator = " ", -- the character that will be used to separate each field provided in results.fields 
        term_icon = "", -- the icon that will be used for term_icon in results.fields

    },
    search = {
        field = "term_name" -- the field that telescope fuzzy search will use when typing in the prompt
    },
	sort = {
		field = "term_name", -- the field that will be used for sorting in the telesocpe results
		ascending = true, -- whether or not the field provided above will be sorted in ascending or descending order
	},
}
```


| Property           | Type                           | Default Value                                           | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
|--------------------|--------------------------------|---------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **mappings**       | `table`                        |                                                         | A table of key mappings for different modes. Each mode (`i` for insert mode, `n` for normal mode) is a key in the table and maps to another table, where the key is the key combination (e.g., "<C-r>") and the value is a table with the fields `action` and `exit_on_action`. The `action` field is a function that will be called when the key combination is pressed, and `exit_on_action` is a boolean that determines whether telescope should be exited after the action is performed. See [Mappings](https://github.com/ryanmsnyder/toggleterm-manager.nvim/blob/readme/README.md#mappings) for more info. |
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

If you'd like to override the default keybindings, the `mappings` table should look something like this:

```lua
local toggleterm_manager = require("toggleterm-manager")
local actions = toggleterm_manager.actions

toggleterm_manager.setup {
	mappings = {
	    i = {
	      ["<CR>"] = { action = actions.create_and_name_term, exit_on_action = true },
	      ["<C-d>"] = { action = actions.delete_term, exit_on_action = false },
	    },
	    n = {
	      ["<CR>"] = { action = actions.create_and_name_term, exit_on_action = true },
	      ["x"] = { action = actions.delete_term, exit_on_action = false },
	    },
	},
}
```

Note that each key in the table should correspond to the NeoVim mode that the mappings should apply to (`i` for insert, `n` for normal). Each mode key should contain another table of key/value pairs where the key is the keybinding and the value is another table of key/value pairs. The valid keys of that table are `action`, which takes a function that manipulates a terminal in some way and `exit_on_action`, which determines if the telescope window should be closed on the execution of the action.

#### Actions

There are six pre-defined actions that can be mapped to key bindings within the telescope window.

> **Floating toggleterm windows:** When configuring `toggleterm` (not `toggleterm-manager`), there is a property called `direction`, which takes a value of `horizontal`, `vertical`, or `float`. Some of the actions behave differently if `direction = float`. This is because of how NeoVim handles floating windows. Telescope is already a floating window so if, for example, `direction = float`, and the `create_term` action is called with `exit_on_action = false`, there would normally be a flash caused by opening a `toggleterm` float and switching back to telescope really fast. To prevent this, the `toggleterm` window will be created as a `hidden` terminal. Note that the `open_mapping` in `toggleterm` config won't be able to toggle these terminals open/closed.

The below table displays the behavior of each action in `actions/init.lua` given different values for `exit_on_action` and `toggleterm`'s' `direction` property that's passed to its [`setup`](https://github.com/akinsho/toggleterm.nvim#setup) function.

<table>
    <tr>
        <th>Action</th>
        <th colspan="2"><code>exit_on_action = true</code></th>
        <th colspan="2"><code>exit_on_action = false</code></th>
    </tr>
    <tr>
        <th></th>
        <th><code>direction = float</code></th>
        <th><code>direction != float</code></th>
        <th><code>direction = float</code></th>
        <th><code>direction != float</code></th>
    </tr>
    <tr>
        <td><code>create_term</code></td>
        <td>Create and focus a new terminal</td>
        <td>Create and focus a new terminal</td>
        <td>Create a <i>hidden</i> terminal</td>
        <td>Create a new terminal</td>
    </tr>
    <tr>
        <td><code>create_and_name_term</code></td>
        <td>Create, name, and focus a new terminal</td>
        <td>Create, name, and focus a new terminal</td>
        <td>Create a <i>hidden</i> terminal and name it</td>
        <td>Create and name a new terminal</td>
    </tr>
    <tr>
        <td><code>rename_term</code></td>
        <td>Rename and focus the terminal if open</td>
        <td>Rename and focus the terminal if open</td>
        <td>Rename the terminal</td>
        <td>Rename the terminal</td>
    </tr>
    <tr>
        <td><code>open_term</code></td>
        <td>Open and focus the terminal</td>
        <td>Open and focus the terminal</td>
        <td>Nothing will happen</td>
        <td>Open the terminal</td>
    </tr>
    <tr>
        <td><code>toggle_term</code></td>
        <td>Toggle terminal open or closed, focus if open</td>
        <td>Toggle terminal open or closed, focus if open</td>
        <td>Toggle terminal open or closed</td>
        <td>Toggle terminal open or closed</td>
    </tr>
    <tr>
        <td><code>delete_term</code></td>
        <td>Delete the terminal</td>
        <td>Delete the terminal</td>
        <td>Delete the terminal</td>
        <td>Delete the terminal</td>
    </tr>
</table>




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

Example of only providing fields (no highlight groups). When a highlight group is not specified for a field, `toggleterm-manager` chooses the highlight group:

```lua
local toggleterm_manager = require("toggleterm-manager")
local actions = toggleterm_manager.actions

toggleterm_manager.setup {
	results = {
		fields = { "term_icon", "term_name", "space", "state" }
	},
}
```

Example of providing highlight groups for some fields and not for others. When a highlight group is paired with a field in a table, that highlight group overrides the default that `toggleterm-manager` chooses.

```lua
results = {
	fields = { "state", "space", { "bufnr", "TelescopeResultsIdentifier" }, "space", "term_icon", { "bufname", "Function" }}
}
```
