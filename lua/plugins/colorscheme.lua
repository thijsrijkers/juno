return {
  "rebelot/kanagawa.nvim",
  lazy     = false,
  priority = 1000,
  config = function()
    require("kanagawa").setup({
      variant    = "wave",   -- "wave" | "dragon" | "lotus"
      background = {
        dark  = "wave",
        light = "lotus",
      },

      styles = {
        bold   = true,
        italic = true,
      },
    })
    vim.cmd("colorscheme kanagawa")
  end,
}