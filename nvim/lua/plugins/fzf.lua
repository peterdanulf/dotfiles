return {
  "ibhagwan/fzf-lua",
  opts = {
    actions = {
      files = {
        ["default"] = require("fzf-lua.actions").file_edit,
      },
    },
  },
}
