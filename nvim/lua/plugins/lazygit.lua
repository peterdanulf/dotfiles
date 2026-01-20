return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      -- Auto-close lazygit when opening files via nvr
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(ev)
          if vim.bo[ev.buf].buftype == "" then
            vim.schedule(function()
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_get_name(buf):match("lazygit") then
                  pcall(vim.api.nvim_win_close, win, true)
                end
              end
            end)
          end
        end,
      })
    end,
  },
}
