return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
          { text = { "", "" }, padding = 1 },
          {
            title = "Pull Request Activity",
            section = "terminal",
            cmd = [[bash -c 'echo "" && gh pr list --search "involves:@me state:open sort:updated-desc" --limit 10 --json number,title,author,reviewDecision | jq -r '"'"'.[] | [if .reviewDecision == "APPROVED" then "✓" elif .reviewDecision == "CHANGES_REQUESTED" then "✗" elif .reviewDecision == "REVIEW_REQUIRED" then "○" else "•" end, ("#" + (.number|tostring)), ("(" + (.author.login | split("-") | map(.[0:1]) | join("") | ascii_upcase) + ")"), (if (.title|length) > 43 then .title[0:43] + "..." else .title end)] | join("  ")'"'"' | sed "s/✓/\x1b[32m✓\x1b[0m/g" | sed "s/✗/\x1b[31m✗\x1b[0m/g" | sed "s/○/\x1b[33m○\x1b[0m/g" | sed "s/#\([0-9]*\)/\x1b[32m#\1\x1b[0m/g"']],
            height = 13,
            padding = 1,
            ttl = 300,
          },
        },
      },
    },
  },
}
