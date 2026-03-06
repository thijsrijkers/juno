-- core/keymaps.lua
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- ── General ──────────────────────────────────────────────────────────
map("n", "<leader>w", "<cmd>w<CR>",          { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>",          { desc = "Quit" })
map("n", "<leader>x", "<cmd>x<CR>",          { desc = "Save & quit" })
map("n", "<Esc>",     "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- ── Window navigation ─────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- ── Buffer navigation ─────────────────────────────────────────────────
map("n", "<S-l>", "<cmd>bnext<CR>",     { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- ── Better indenting in visual mode ───────────────────────────────────
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- ── Move lines ────────────────────────────────────────────────────────
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- ── Telescope (file search & grep) ───────────────────────────────────
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>",  { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>",   { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>",     { desc = "Find buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>",   { desc = "Help tags" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>",    { desc = "Recent files" })
map("n", "<leader>fs", "<cmd>Telescope grep_string<CR>", { desc = "Grep word under cursor" })
map("n", "<leader>fc", "<cmd>Telescope commands<CR>",    { desc = "Commands" })

-- ── File tree ─────────────────────────────────────────────────────────
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })

-- ── Diagnostics ───────────────────────────────────────────────────────
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open diagnostic float" })