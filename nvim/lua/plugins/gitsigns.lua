return {
  "lewis6991/gitsigns.nvim",
  opts = function(_, opts)
    opts.on_attach = function(buf)
      local gs = package.loaded.gitsigns
      vim.keymap.set("n", "ö", gs.next_hunk, { buffer = buf })
      vim.keymap.set("n", "ä", gs.prev_hunk, { buffer = buf })
    end
  end,
}
