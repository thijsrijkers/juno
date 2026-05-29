return {
  "ellisonleao/gruvbox.nvim",
  lazy     = false,
  priority = 1000,
  config = function()
    require("gruvbox").setup({
      contrast = "hard",
      bold = true,
      italic = {
        strings = true,
        comments = true,
        operators = false,
        folds = true,
      },
    })
    vim.cmd("colorscheme gruvbox")
  end,
}
