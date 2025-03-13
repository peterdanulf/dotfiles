return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = function(_, opts)
      -- Ensure servers table exists
      opts.servers = opts.servers or {}

      -- Add Dart LSP (dartls) configuration
      opts.servers.dartls = {
        filetypes = { "dart" },
        root_dir = require("lspconfig.util").root_pattern("pubspec.yaml"),
        settings = {
          dart = {
            completeFunctionCalls = true, -- Auto-complete function calls
            enableSdkFormatter = true, -- Enable Dart formatter
          },
        },
      }

      -- Add Intelephense (PHP LSP) configuration
      opts.servers.intelephense = {
        settings = {
          intelephense = {
            files = {
              maxSize = 1000000, -- Adjust for large files
              exclude = { "**/node_modules/**", "**/vendor/**", "**/.git/**" },
            },
            stubs = {
              "wordpress",
              "core",
            },
            diagnostics = {
              enable = true,
              suppress = {
                "undefinedFunction",
                "undefinedMethod",
                "undefinedClass",
              },
            },
          },
        },
      }
    end,
  },
}
