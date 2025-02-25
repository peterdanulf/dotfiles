return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = function(_, opts)
      -- Ensure servers table exists
      opts.servers = opts.servers or {}

      -- Add intelephense configuration
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
