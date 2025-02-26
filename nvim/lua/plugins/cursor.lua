return {
  {
    "rainbowhxch/accelerated-jk.nvim",
    config = function()
      require("accelerated-jk").setup({
        mode = "time_driven",
        enable_deceleration = false,
        acceleration_motions = {},
        acceleration_limit = 100, -- Very low value for quick acceleration
        acceleration_table = { 2, 4, 8, 16, 32, 64, 128, 256 }, -- Exponential growth for rapid acceleration
      })
    end,
  },
}
