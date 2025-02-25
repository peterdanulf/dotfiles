return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local actions = require("fzf-lua.actions")
      require("fzf-lua").setup({
        files = {
          cwd_prompt = false,
          actions = {
            ["alt-i"] = actions.toggle_ignore,
            ["alt-h"] = actions.toggle_hidden,
          },
        },
        grep = {
          actions = {
            ["alt-i"] = actions.toggle_ignore,
            ["alt-h"] = actions.toggle_hidden,
          },
        },
      })
    end,
  },
}
