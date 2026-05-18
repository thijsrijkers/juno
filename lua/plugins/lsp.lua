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
          "rust_analyzer",
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
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local function auto_import(bufnr)
        local ft = vim.bo[bufnr].filetype
        local filter = nil
        if ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact" then
          filter = function(action)
            return action.kind == "source.addMissingImports.ts"
          end
        elseif ft == "go" then
          filter = function(action)
            return action.title:match("[Oo]rganize [Ii]mports")
          end
        end
        if filter then
          vim.lsp.buf.code_action({
            apply  = true,
            filter = filter,
            context = { only = ft == "go" and { "source.organizeImports" } or { "source.addMissingImports" } },
          })
        end
      end

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

        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer   = bufnr,
          callback = function() auto_import(bufnr) end,
        })
      end

      vim.lsp.config("gopls", { on_attach = on_attach, capabilities = capabilities })
      vim.lsp.enable("gopls")

      vim.lsp.config("ts_ls", { on_attach = on_attach, capabilities = capabilities })
      vim.lsp.enable("ts_ls")

      vim.lsp.config("rust_analyzer", {
        on_attach    = on_attach,
        capabilities = capabilities,
        settings = {
          ["rust-analyzer"] = {
            cargo    = { allFeatures = true },
            checkOnSave = { command = "clippy" },
          },
        },
      })
      vim.lsp.enable("rust_analyzer")
    end,
  },
}
