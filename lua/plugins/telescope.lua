-- plugins/telescope.lua
return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- native FZF sorter for much faster fuzzy matching
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
    -- shows file icons in results
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local telescope = require("telescope")
    local actions   = require("telescope.actions")

    telescope.setup({
      defaults = {
        prompt_prefix   = " 🔍 ",
        selection_caret = " ❯ ",
        path_display    = { "truncate" },
        sorting_strategy = "ascending",
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
        -- Respect .gitignore by default; still search hidden files
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
          hidden      = true,
          find_command = { "rg", "--files", "--hidden", "--glob=!.git/" },
        },
        live_grep = {
          additional_args = function()
            return { "--hidden" }
          end,
        },
        buffers = {
          sort_lastused     = true,
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

    -- Load extensions if available
    pcall(telescope.load_extension, "fzf")
  end,
}