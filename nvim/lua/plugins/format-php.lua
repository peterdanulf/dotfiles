return {
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      opts.autoformat = true
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- Set up PHP formatting with prettier
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.php = { "prettier" }

      -- Add printWidth setting for 80 characters
      opts.formatters = opts.formatters or {}
      opts.formatters.prettier = {
        prepend_args = { "--print-width", "80" },
      }
    end,
  },
}

