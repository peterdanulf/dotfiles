return {
  -- Add PHP and other languages to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "php",  -- Add PHP parser
      },
      -- Optional: Add specific PHP highlighting settings if needed
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
    },
  },
  -- Auto-install parsers on startup
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    config = function(_, opts)
      -- This will run after the default configuration
      require("nvim-treesitter.install").ensure_installed_sync(opts.ensure_installed)
    end,
  },
}