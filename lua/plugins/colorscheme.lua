-- plugins/colorscheme.lua
return {
  "ellisonleao/gruvbox.nvim",
  lazy     = false,
  priority = 1000,
  config = function()
    require("gruvbox").setup({
      contrast      = "hard",  -- "hard" | "medium" | "soft"
      transparent_mode = false,
      italic = {
        strings   = false,
        comments  = true,
        operators = false,
        folds     = true,
      },
    })
    vim.cmd("colorscheme gruvbox")
  end,
}