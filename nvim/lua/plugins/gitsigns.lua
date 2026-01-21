return {
  "lewis6991/gitsigns.nvim",
  keys = {
    { "ö", function() require("gitsigns").next_hunk() end, desc = "Next Hunk" },
    { "ä", function() require("gitsigns").prev_hunk() end, desc = "Prev Hunk" },
  },
}
