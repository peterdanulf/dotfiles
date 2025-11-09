return {
  {
    dir = "/Users/peterdanulf/dev/reviewer",
    name = "reviewer.nvim",
    dependencies = {
      "ibhagwan/fzf-lua",
    },
    config = function()
      require("reviewer").setup({
        picker_order = { "fzf", "telescope", "snacks" },
        pr_search_filter = "involves:@me state:open sort:updated-desc",
        pr_limit = 20,
        auto_assign_to_me = true,
        auto_open_browser = "ask",
        show_resolved_comments = false,
        default_reviewers = {},
        exclude_reviewers = {},
      })
    end,
    keys = {
      { "<leader>gr", function() require("reviewer").pick_pr() end, desc = "Review PRs" },
      { "<leader>go", function() require("reviewer").create_pr() end, desc = "Create PR" },
    },
  },
}
