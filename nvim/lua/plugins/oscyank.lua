return {
  {
    "ojroques/nvim-oscyank",
    config = function()
      require("osc52").setup({
        max_length = 0, -- Maximum length of selection (0 for no limit)
        silent = false, -- Disable message on successful copy
        trim = false, -- Trim surrounding whitespaces before copy
        tmux_passthrough = false, -- Use tmux passthrough (requires tmux: set -g allow-passthrough on)
      })

      -- Set up keymaps for visual mode
      vim.keymap.set("v", "<leader>c", require("osc52").copy_visual, { desc = "Copy to clipboard (OSC52)" })
      vim.keymap.set("v", "<leader>cc", require("osc52").copy_visual, { desc = "Copy to clipboard (OSC52)" })

      -- Optional: Set up autocmd to copy yanked text automatically
      -- vim.api.nvim_create_autocmd("TextYankPost", {
      --   callback = function()
      --     if vim.v.event.operator == "y" and vim.v.event.regname == "" then
      --       require("osc52").copy_register('"')
      --     end
      --   end,
      -- })
    end,
  },
}