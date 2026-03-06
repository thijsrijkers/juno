# Juno

My personal Neovim configuration with theme, fuzzy file search, and live grep — managed by [lazy.nvim](https://github.com/folke/lazy.nvim).

---

## Requirements

Before installing, make sure you have the following installed:

- **Neovim** >= 0.9
- **Git**
- **Ripgrep** — used for live grep search inside files

### Install Ripgrep

| OS | Command |
|---|---|
| Windows | `winget install BurntSushi.ripgrep.MSVC` |
| macOS | `brew install ripgrep` |
| Linux | `sudo apt install ripgrep` |

---

## Installation

### Windows (PowerShell)

```powershell
git clone https://github.com/thijsrijkers/juno $env:LOCALAPPDATA\nvim
nvim
```

### macOS & Linux

```bash
git clone https://github.com/thijsrijkers/juno ~/.config/nvim
nvim
```

On first launch, lazy.nvim will automatically install all plugins. Wait for it to finish, then restart Neovim.

---

## Uninstall / Reset

If you want a clean reinstall, remove the config and plugin data first.

### Windows (PowerShell)
```powershell
Remove-Item -Recurse -Force $env:LOCALAPPDATA\nvim
Remove-Item -Recurse -Force $env:LOCALAPPDATA\nvim-data
```

### macOS & Linux
```bash
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
```

Then run the installation steps again.

---

## Keybindings

Space is the leader key.

### Search
| Key | Action |
|---|---|
| `Space sf` | Search files |
| `Space sg` | Search text across project (grep) |
| `Space sw` | Search word under cursor |
| `Space sr` | Resume last search |
| `Space sd` | Search diagnostics |
| `Space sk` | Search keymaps |
| `Space /` | Search text in current file |
| `Space Space` | Browse open buffers |

### Files
| Key | Action |
|---|---|
| `Space e` | Toggle file explorer |
| `:E` | Open file explorer at current file location |

### Navigation
| Key | Action |
|---|---|
| `Shift h` | Previous tab |
| `Shift l` | Next tab |
| `Ctrl h/j/k/l` | Move between splits |

### Editing
| Key | Action |
|---|---|
| `gcc` | Toggle line comment |
| `gc` (visual) | Toggle comment on selection |
| `Space w` | Save file |
| `Space q` | Quit |

---

## Plugins

| Plugin | Purpose |
|---|---|
| `sainnhe/everforest` | Everforest colour scheme |
| `telescope.nvim` | Fuzzy file finder and live grep |
| `nvim-tree.lua` | File explorer sidebar |
| `lualine.nvim` | Status line |
| `bufferline.nvim` | Tab bar |
| `nvim-treesitter` | Syntax highlighting |
| `which-key.nvim` | Keybinding popup guide |
| `nvim-autopairs` | Auto-close brackets and quotes |
| `Comment.nvim` | Toggle comments |
| `gitsigns.nvim` | Git changes in the gutter |