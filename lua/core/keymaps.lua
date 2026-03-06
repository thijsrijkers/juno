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
map("n", "<S-l>", "<cmd>bnext<CR>",        { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<CR>",    { desc = "Previous buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- ── Better indenting in visual mode ───────────────────────────────────
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- ── Move lines ────────────────────────────────────────────────────────
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- ── Telescope ── kickstart.nvim style ────────────────────────────────
map("n", "<leader>sh", "<cmd>Telescope help_tags<CR>",   { desc = "[S]earch [H]elp" })
map("n", "<leader>sk", "<cmd>Telescope keymaps<CR>",     { desc = "[S]earch [K]eymaps" })
map("n", "<leader>sf", "<cmd>Telescope find_files<CR>",  { desc = "[S]earch [F]iles" })
map("n", "<leader>ss", "<cmd>Telescope builtin<CR>",     { desc = "[S]earch [S]elect Telescope" })
map("n", "<leader>sw", "<cmd>Telescope grep_string<CR>", { desc = "[S]earch current [W]ord" })
map("n", "<leader>sg", "<cmd>Telescope live_grep<CR>",   { desc = "[S]earch by [G]rep" })
map("n", "<leader>sd", "<cmd>Telescope diagnostics<CR>", { desc = "[S]earch [D]iagnostics" })
map("n", "<leader>sr", "<cmd>Telescope resume<CR>",      { desc = "[S]earch [R]esume" })
map("n", "<leader>s.", "<cmd>Telescope oldfiles<CR>",    { desc = "[S]earch Recent Files" })
map("n", "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "[/] Fuzzily search in current buffer" })
map("n", "<leader><leader>", "<cmd>Telescope buffers<CR>", { desc = "[ ] Find existing buffers" })

-- ── File tree ─────────────────────────────────────────────────────────
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })

-- :e opens the file explorer focused on the current file's directory
vim.api.nvim_create_user_command("e", function()
  require("nvim-tree.api").tree.find_file({ open = true, focus = true })
end, { desc = "Open file explorer at current file" })

-- ── Diagnostics ───────────────────────────────────────────────────────
map("n", "[d", vim.diagnostic.goto_prev,  { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next,  { desc = "Next diagnostic" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open diagnostic float" })