return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Ensure PHP is in the list of installed parsers
      vim.list_extend(opts.ensure_installed, {
        "php",
      })
    end,
  },
}
