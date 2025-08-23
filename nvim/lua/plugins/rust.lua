return {
  {
    "mrcjkb/rustaceanvim",
    opts = function(_, opts)
      opts.server = opts.server or {}

      -- use system rust-analyzer if available (optional)
      local ra = vim.fn.exepath("rust-analyzer")
      if ra ~= "" then
        opts.server.cmd = { ra }
      end

      -- Force matching position encoding (UTF-16) to stop the warning
      local caps = vim.lsp.protocol.make_client_capabilities()
      caps.general = caps.general or {}
      caps.general.positionEncodings = { "utf-16" } -- <-- key bit
      opts.server.capabilities = vim.tbl_deep_extend("force", opts.server.capabilities or {}, caps)

      -- your normal settings
      opts.server.default_settings = vim.tbl_deep_extend(
        "force",
        opts.server.default_settings or {},
        { ["rust-analyzer"] = { rustc = { source = "discover" } } }
      )

      return opts
    end,
  },
}
