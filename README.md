<p align="center">
A simple Telescope extension to manage Terminal buffers
</p>

## ✨ Features

- List and switch between all terminal buffers opened with `toggleterm.nvim`.
- Kill terminal buffers easily with keybindings.
- Open buffer picker with `:Telescope toggleterm`
or `lua require('telescope-toggleterm').open()`

## ⚡ Requirements

- [`telescope`](https://github.com/nvim-telescope/telescope.nvim) plugin.
- [`nvim-toggleterm`](https://github.com/akinsho/nvim-toggleterm.lua) plugin.

## 🛠️ Installation
Using [ `lazy.nvim` ](https://github.com/folke/lazy.nvim) in lua:
```lua
{
  "ryanmsnyder/telescope-toggleterm.nvim",
  event = "TermOpen",
  dependencies = {
     "akinsho/nvim-toggleterm.lua",
     "nvim-telescope/telescope.nvim",
     "nvim-lua/popup.nvim",
     "nvim-lua/plenary.nvim",
  },
  config = function()
     require("telescope").load_extension "toggleterm"
  end,
}
```

## ⚙️ Configuration

```lua
require("telescope-toggleterm").setup {
   mappings = {
      -- <ctrl-c> : kill the terminal buffer (default) .
      ["<C-c>"] = require("telescope-toggleterm").actions.exit_terminal,
   },
}
```


