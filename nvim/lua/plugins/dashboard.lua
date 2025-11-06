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
        sections = {}, -- Built dynamically in config
      },
    },

    config = function(_, opts)
      -- ============================================================================
      -- HELPER FUNCTIONS
      -- ============================================================================

      local function has_open_prs()
        local handle = io.popen(
          'gh pr list --search "involves:@me state:open sort:updated-desc" --limit 1 --json number 2>&1'
        )
        local result = handle:read("*a")
        handle:close()

        local ok, prs = pcall(vim.fn.json_decode, result)
        return ok and prs and #prs > 0
      end

      local function get_status_icon(review_decision)
        if review_decision == "APPROVED" then
          return "✓", "DiagnosticOk"
        elseif review_decision == "CHANGES_REQUESTED" then
          return "✗", "DiagnosticError"
        elseif review_decision == "REVIEW_REQUIRED" then
          return "○", "DiagnosticWarn"
        else
          return "•", "Comment"
        end
      end

      local function get_author_initials(login)
        return login:gsub("-", " "):gsub("%w+", function(w)
          return w:sub(1, 1):upper()
        end):gsub(" ", "")
      end

      local function pad_pr_number(number, width)
        return string.format("%0" .. width .. "d", number)
      end

      -- ============================================================================
      -- DASHBOARD SETUP
      -- ============================================================================

      local sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
      }

      -- Add PR section if PRs exist
      if has_open_prs() then
        table.insert(sections, {
          title = {
            { "Pull Requests", hl = "SnacksDashboardTitle" },
            { string.rep(" ", 46) .. "b", hl = "SnacksDashboardKey" },
          },
          section = "terminal",
          cmd = [[bash -c 'echo "" && gh pr list --search "involves:@me state:open sort:updated-desc" --limit 10 --json number,title,author,reviewDecision | jq -r '"'"'def lpad(n): tostring | (n - length) as $l | if $l > 0 then ("0" * $l) + . else . end; (max_by(.number) | .number | tostring | length) as $width | .[] | [if .reviewDecision == "APPROVED" then "✓" elif .reviewDecision == "CHANGES_REQUESTED" then "✗" elif .reviewDecision == "REVIEW_REQUIRED" then "○" else "•" end, ("#" + (.number | lpad($width))), ("(" + (.author.login | split("-") | map(.[0:1]) | join("") | ascii_upcase) + ")"), (if (.title|length) > 43 then .title[0:43] + "..." else .title end)] | join("  ")'"'"' | sed "s/✓/\x1b[32m✓\x1b[0m/g" | sed "s/✗/\x1b[31m✗\x1b[0m/g" | sed "s/○/\x1b[33m○\x1b[0m/g" | sed "s/#\([0-9]*\)/\x1b[32m#\1\x1b[0m/g"']],
          height = 13,
          ttl = 300,
        })
      end

      opts.dashboard.sections = sections
      require("snacks").setup(opts)

      -- ============================================================================
      -- PR PICKER FUNCTION
      -- ============================================================================

      local function pick_pr()
        -- Fetch PRs from GitHub
        local handle = io.popen(
          'gh pr list --search "involves:@me state:open sort:updated-desc" --limit 20 --json number,title,author,url,reviewDecision 2>&1'
        )
        local result = handle:read("*a")
        handle:close()

        if result == "" then
          return
        end

        local ok, prs = pcall(vim.fn.json_decode, result)
        if not ok or not prs or #prs == 0 then
          return
        end

        -- Calculate padding width for PR numbers
        local max_num = 0
        for _, pr in ipairs(prs) do
          max_num = math.max(max_num, pr.number)
        end
        local pad_width = #tostring(max_num)

        -- Format PRs for picker
        local items = {}
        for _, pr in ipairs(prs) do
          local icon, _ = get_status_icon(pr.reviewDecision)
          local initials = get_author_initials(pr.author.login)
          local padded_num = pad_pr_number(pr.number, pad_width)
          local display = string.format("%s  #%s  (%s)  %s", icon, padded_num, initials, pr.title)

          table.insert(items, {
            text = display .. string.rep(" ", 500), -- Padding for full-width highlight
            number = pr.number,
            url = pr.url,
            status_icon = icon,
            padded_num = padded_num,
            initials = initials,
            title = pr.title,
            reviewDecision = pr.reviewDecision,
          })
        end

        -- ========================================================================
        -- PICKER FORMAT FUNCTION
        -- ========================================================================

        local function format_pr(item)
          local title = item.title
          if #title > 80 then
            title = title:sub(1, 77) .. "..."
          end

          local _, icon_hl = get_status_icon(item.reviewDecision)

          return {
            { item.status_icon .. "  ", icon_hl },
            { "#" .. item.padded_num .. "  ", "String" },
            { "(" .. item.initials .. ")  ", "Function" },
            { title .. string.rep(" ", 500) }, -- No highlight = inherits selection
          }
        end

        -- ========================================================================
        -- PREVIEW FUNCTION
        -- ========================================================================

        local function preview_pr(ctx)
          ctx.preview:reset()
          ctx.preview:set_title("PR #" .. ctx.item.number)

          -- Fetch detailed PR info
          local handle = io.popen(string.format(
            'gh pr view %d --json number,title,author,state,reviewDecision,createdAt,updatedAt,url,body,commits,additions,deletions',
            ctx.item.number
          ))
          local result = handle:read("*a")
          handle:close()

          local ok, pr_data = pcall(vim.fn.json_decode, result)
          if not ok or not pr_data then
            ctx.preview:notify("Error loading PR details", "error")
            return
          end

          -- Build preview content
          local text = {}
          local highlights = {}

          local function add_line(content, value_hl, label_hl)
            local line_num = #text
            table.insert(text, content)

            if value_hl and label_hl then
              local colon_pos = content:find(":")
              if colon_pos then
                table.insert(highlights, { row = line_num, col = 0, end_col = colon_pos, hl_group = label_hl })
                table.insert(highlights, {
                  row = line_num,
                  col = colon_pos + 1,
                  end_col = #content,
                  hl_group = value_hl,
                })
              end
            elseif value_hl then
              table.insert(highlights, { row = line_num, col = 0, end_col = #content, hl_group = value_hl })
            end
          end

          -- Header
          add_line("PR #" .. pr_data.number, "String")
          add_line("")

          -- Metadata
          add_line("Title: " .. pr_data.title, "Normal", "Function")
          add_line("")
          add_line("Author: " .. pr_data.author.login, "Identifier", "Function")
          add_line("State: " .. pr_data.state, pr_data.state == "OPEN" and "DiagnosticInfo" or "DiagnosticOk", "Function")

          if pr_data.reviewDecision then
            local review_hl = ({
              APPROVED = "DiagnosticOk",
              CHANGES_REQUESTED = "DiagnosticError",
              REVIEW_REQUIRED = "DiagnosticWarn",
            })[pr_data.reviewDecision] or "Normal"
            add_line("Review: " .. pr_data.reviewDecision, review_hl, "Function")
          end

          add_line("")
          add_line("Created: " .. pr_data.createdAt:gsub("T", " "):gsub("Z", ""), "Comment", "Function")
          add_line("Updated: " .. pr_data.updatedAt:gsub("T", " "):gsub("Z", ""), "Comment", "Function")
          add_line("")
          add_line("Changes: +" .. pr_data.additions .. " -" .. pr_data.deletions, "String", "Function")
          add_line("Commits: " .. #pr_data.commits, "String", "Function")
          add_line("")
          add_line("URL: " .. pr_data.url, "Underlined", "Function")
          add_line("")

          -- Body
          if pr_data.body and pr_data.body ~= "" then
            for line in pr_data.body:gsub("\r\n", "\n"):gsub("\r", "\n"):gmatch("[^\n]*") do
              table.insert(text, line)
            end
          else
            add_line("No description provided", "Comment")
          end

          -- Apply content and highlights
          ctx.preview:set_lines(text)

          local ns = vim.api.nvim_create_namespace("pr_preview")
          for _, hl in ipairs(highlights) do
            vim.api.nvim_buf_set_extmark(ctx.buf, ns, hl.row, hl.col, {
              end_col = hl.end_col,
              hl_group = hl.hl_group,
            })
          end

          ctx.preview:highlight({ ft = "markdown" })
        end

        -- ========================================================================
        -- OPEN PICKER
        -- ========================================================================

        Snacks.picker.pick({
          title = "Select PR(s) (Tab to multi-select)",
          items = items,
          format = format_pr,
          layout = "default",
          win = {
            preview = {
              wo = { wrap = true, linebreak = true },
            },
          },
          preview = preview_pr,
          actions = {
            confirm = function(picker)
              local selected = picker:selected({ fallback = true })
              picker:close()
              vim.schedule(function()
                for _, item in ipairs(selected) do
                  vim.fn.system("gh pr view " .. item.number .. " --web")
                end
              end)
            end,
          },
        })
      end

      -- ============================================================================
      -- KEYMAPS
      -- ============================================================================

      -- Dashboard keymap
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "snacks_dashboard",
        callback = function()
          vim.schedule(function()
            local buf = vim.api.nvim_get_current_buf()
            pcall(vim.keymap.del, "n", "b", { buffer = buf })
            vim.keymap.set("n", "b", pick_pr, { buffer = buf, desc = "Browse PRs", nowait = true })
          end)
        end,
      })

      -- Global keymap
      vim.keymap.set("n", "<leader>gp", pick_pr, { desc = "Pick and open PR" })
    end,
  },
}
