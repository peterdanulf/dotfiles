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
            ["default"] = actions.file_edit,
          },
        },
        grep = {
          actions = {
            ["alt-i"] = actions.toggle_ignore,
            ["alt-h"] = actions.toggle_hidden,
            ["default"] = actions.file_edit,
          },
        },
        git = {
          status = {
            actions = {
              ["default"] = actions.file_edit,
            },
          },
        },
      })
    end,
  },
}
