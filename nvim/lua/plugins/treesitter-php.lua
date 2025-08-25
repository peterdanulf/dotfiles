return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    opts = {
      ensure_installed = {
        "php",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-Space>", -- starta
          node_incremental = "<C-Space>", -- expandera
          node_decremental = "<BS>", -- krymp
          scope_incremental = false,
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
