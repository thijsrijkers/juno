require("core.options")
require("core.keymaps")
require("core.lazy")

-- Compatibility shim: patch nvim-treesitter.parsers immediately after lazy
local ok, ts_parsers = pcall(require, "nvim-treesitter.parsers")
if ok then
  if not ts_parsers.ft_to_lang then
    ts_parsers.ft_to_lang = function(ft) return ft end
  end
  if not ts_parsers.is_enabled then
    ts_parsers.is_enabled = function() return false end
  end
end