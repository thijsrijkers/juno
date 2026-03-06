-- plugins/telescope.lua
return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    -- Compatibility shim for newer Neovim builds
    local ok_parsers, ts_parsers = pcall(require, "nvim-treesitter.parsers")
    if ok_parsers then
      if not ts_parsers.ft_to_lang then
        ts_parsers.ft_to_lang = function(ft) return ft end
      end
    end
    local ok_configs, ts_configs = pcall(require, "nvim-treesitter.configs")
    if ok_configs then
      if not ts_configs.is_enabled then
        ts_configs.is_enabled = function() return false end
      end
    end

    local telescope = require("telescope")
    local actions   = require("telescope.actions")

    telescope.setup({
      defaults = {
        prompt_prefix    = " 🔍 ",
        selection_caret  = " ❯ ",
        path_display     = { "truncate" },
        sorting_strategy = "ascending",
        preview = {
          treesitter = false,
        },
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width   = 0.55,
          },
          width  = 0.87,
          height = 0.80,
        },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["<Esc>"] = actions.close,
          },
        },
        file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/" },
        vimgrep_arguments = {
          "rg", "--color=never", "--no-heading",
          "--with-filename", "--line-number",
          "--column", "--smart-case", "--hidden",
          "--glob=!.git/",
        },
      },
      pickers = {
        find_files = {
          hidden       = true,
          find_command = { "rg", "--files", "--hidden", "--glob=!.git/" },
        },
        live_grep = {
          additional_args = function()
            return { "--hidden" }
          end,
        },
        current_buffer_fuzzy_find = {
          previewer = false,
        },
        buffers = {
          sort_lastused         = true,
          ignore_current_buffer = true,
        },
      },
      extensions = {
        fzf = {
          fuzzy                   = true,
          override_generic_sorter = true,
          override_file_sorter    = true,
          case_mode               = "smart_case",
        },
      },
    })

    pcall(telescope.load_extension, "fzf")
  end,
}