## vis-commentary

`vis-commentary` aims to port Tim Pope's [vim-commentary](https://github.com/tpope/vim-commentary) to [vis](https://github.com/martanne/vis).

| Keybind | Description |
|---------|-------------|
| `gcc`   | Toggle comment of the current line in NORMAL mode.|
| `gc`    | Toggle comment of the current selection in VISUAL mode. |

Should you find bugs or unsupported languages, please report them.

### Usage
Add this to your `visrc.lua`:
```
require("vis-commentary")
```
