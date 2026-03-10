return {
  -- Mason: automatically installs LSP servers
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

  -- Mason LSPconfig bridge
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "gopls",   -- Go
          "ts_ls",   -- TypeScript & JavaScript
        },
        automatic_installation = true,
      })
    end,
  },

  -- LSP config
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- Shared on_attach for keymaps
      local on_attach = function(_, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
        end

        map("gd", vim.lsp.buf.definition,          "Go to Definition")
        map("gD", vim.lsp.buf.declaration,         "Go to Declaration")
        map("gr", vim.lsp.buf.references,          "Go to References")
        map("gi", vim.lsp.buf.implementation,      "Go to Implementation")
        map("K",  vim.lsp.buf.hover,               "Hover Documentation")
        map("<leader>rn", vim.lsp.buf.rename,      "Rename")
        map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("<leader>lf", function()
          vim.lsp.buf.format({ async = true })
        end, "Format file")
      end

      -- Go
      vim.lsp.config("gopls", { on_attach = on_attach })
      vim.lsp.enable("gopls")

      -- TypeScript & JavaScript
      vim.lsp.config("ts_ls", { on_attach = on_attach })
      vim.lsp.enable("ts_ls")
    end,
  },
}
