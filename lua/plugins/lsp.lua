return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed   = "✓",
            package_pending     = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "gopls",
          "ts_ls",
        },
        automatic_installation = true,
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Pass cmp capabilities to LSP so autocomplete works
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local on_attach = function(_, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
        end

        map("gd", vim.lsp.buf.implementation,     "Go to Implementation")
        map("gD", vim.lsp.buf.declaration,        "Go to Declaration")
        map("gT", vim.lsp.buf.type_definition,    "Go to Type Definition")
        map("K",  vim.lsp.buf.hover,              "Hover Documentation")
        map("<leader>lr", vim.lsp.buf.references,          "Go to References")
        map("<leader>li", vim.lsp.buf.implementation,      "Go to Implementation")
        map("<leader>ld", vim.lsp.buf.definition,          "Go to Definition")
        map("<leader>rn", vim.lsp.buf.rename,              "Rename")
        map("<leader>ca", vim.lsp.buf.code_action,         "Code Action")
        map("<leader>lf", function()
          vim.lsp.buf.format({ async = true })
        end, "Format file")
      end

      vim.lsp.config("gopls", { on_attach = on_attach, capabilities = capabilities })
      vim.lsp.enable("gopls")

      vim.lsp.config("ts_ls", { on_attach = on_attach, capabilities = capabilities })
      vim.lsp.enable("ts_ls")
    end,
  },
}
