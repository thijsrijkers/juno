-- plugins/colorscheme.lua
return {
  "EdenEast/nightfox.nvim",
  lazy     = false,
  priority = 1000,
  config = function()
    require("nightfox").setup({
      options = {
        transparent     = false,
        terminal_colors = true,
        styles = {
          comments  = "italic",
          keywords  = "italic",
          functions = "NONE",
          variables = "NONE",
        },
      },
    })
    vim.cmd("colorscheme nordfox")
  end,
}