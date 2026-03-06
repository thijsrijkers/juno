# Juno
Automatically deploying my personal nvim configuration

---

## Quick deploy

```bash
# One-liner: clone + launch
bash <(curl -s https://raw.githubusercontent.com/thijsrijkers/juno/main/deploy.sh)
```

Or clone manually:

```bash
git clone https://github.com/thijsrijkers/juno ~/.config/nvim
cd ~/.config/nvim
nvim .          # plugins install automatically on first open
```

---

## What's included

| Plugin | Purpose |
|---|---|
| `tokyonight.nvim` | Tokyo Night colour scheme (moon variant) |
| `telescope.nvim` | Fuzzy file finder + live grep |
| `telescope-fzf-native` | Native FZF sorter (faster search) |
| `nvim-tree.lua` | File explorer sidebar |
| `lualine.nvim` | Status line |
| `bufferline.nvim` | Buffer / tab bar |
| `nvim-treesitter` | Syntax highlighting |
| `which-key.nvim` | Keybinding popup guide |
| `nvim-autopairs` | Auto-close brackets/quotes |
| `Comment.nvim` | Toggle comments (`gcc` / `gc`) |
| `gitsigns.nvim` | Git diff in gutter |
| `dashboard-nvim` | Start screen |

---

## Key bindings (Space is `<leader>`)

### Files & Search
| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep (search text in project) |
| `<leader>fr` | Recent files |
| `<leader>fs` | Grep word under cursor |
| `<leader>fb` | Browse open buffers |
| `<leader>e` | Toggle file tree |

### Editing
| Key | Action |
|---|---|
| `gcc` | Toggle line comment |
| `gc` (visual) | Toggle selection comment |
| `<C-h/j/k/l>` | Navigate between splits |
| `<S-h>` / `<S-l>` | Previous / next buffer |

---

## Requirements

- **Neovim** ≥ 0.9
- **git**
- **ripgrep** (`rg`) – for Telescope live grep
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal for icons