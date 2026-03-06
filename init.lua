-- Compatibility shim for older telescope with newer Neovim builds
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  once = true,
  callback = function()
    local ok, ts_parsers = pcall(require, "nvim-treesitter.parsers")
    if ok then
      if not ts_parsers.ft_to_lang then
        ts_parsers.ft_to_lang = function(ft) return ft end
      end
      if not ts_parsers.is_enabled then
        ts_parsers.is_enabled = function() return false end
      end
    end
  end,
})

require("core.options")
require("core.keymaps")
require("core.lazy")