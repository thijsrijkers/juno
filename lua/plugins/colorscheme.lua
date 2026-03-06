-- plugins/colorscheme.lua
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000, -- load first
  opts = {
    style = "moon",      -- "storm" | "night" | "moon" | "day"
    transparent = false,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      functions = {},
      variables = {},
      sidebars = "dark",
      floats = "dark",
    },
    on_highlights = function(hl, c)
      -- subtle tweak: make line numbers a bit brighter
      hl.LineNr = { fg = c.dark5 }
      hl.CursorLineNr = { fg = c.orange, bold = true }
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd("colorscheme tokyonight-night")
  end,
}