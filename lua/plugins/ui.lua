-- plugins/ui.lua  – statusline + a handful of quality-of-life extras
return {
  -- ── Lualine statusline ─────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme                = "tokyonight",
        globalstatus         = true,
        component_separators = { left = "", right = "" },
        section_separators   = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  -- ── Bufferline (tabs) ──────────────────────────────────────────────
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
      options = {
        mode            = "buffers",
        diagnostics     = "nvim_lsp",
        offsets         = { { filetype = "NvimTree", text = "Explorer", padding = 1 } },
        show_buffer_close_icons = true,
        separator_style = "slant",
      },
    },
  },

  -- ── Treesitter (syntax highlighting) ──────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc",
          "javascript", "typescript", "tsx",
          "python", "rust", "go",
          "json", "yaml", "toml", "markdown",
          "html", "css", "bash",
        },
        highlight    = { enable = true },
        indent       = { enable = true },
        auto_install = true,
      })
    end,
  },

  -- ── Which-key (keybinding popup) ──────────────────────────────────
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup{}
      wk.add({
        { "<leader>s", group = "[S]earch" },
        { "<leader>b", group = "[B]uffer" },
      })
    end,
  },

  -- ── Autopairs ─────────────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts  = {},
  },

  -- ── Comment.nvim ──────────────────────────────────────────────────
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    opts  = {},
  },

  -- ── Git signs in gutter ───────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    opts  = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
      },
    },
  },

  -- ── Dashboard (start screen) ───────────────────────────────────────
  {
    "nvimdev/dashboard-nvim",
    event        = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      theme = "doom",
      config = {
        header = {
          "",
          "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
          "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
          "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
          "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
          "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
          "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
          "",
        },
        center = {
          { icon = "  ", desc = "Find File          ", key = "f", action = "Telescope find_files" },
          { icon = "  ", desc = "Recent Files       ", key = "r", action = "Telescope oldfiles" },
          { icon = "  ", desc = "Live Grep          ", key = "g", action = "Telescope live_grep" },
          { icon = "  ", desc = "Config             ", key = "c", action = "e $MYVIMRC" },
          { icon = "  ", desc = "Quit               ", key = "q", action = "qa" },
        },
        footer = { "", "🚀 Happy coding!" },
      },
    },
  },
}