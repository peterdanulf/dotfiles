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
        -- PR section - lazy loaded via terminal command with spinner
        {
          title = {
            { "Pull Requests", hl = "SnacksDashboardTitle" },
            { string.rep(" ", 46) .. "p", hl = "SnacksDashboardKey" },
          },
          section = "terminal",
          cmd = [[bash -c '(echo ""; echo -n "⠋ Loading PRs..." & sleep 0.1 && printf "\r⠙ Loading PRs..." & sleep 0.1 && printf "\r⠹ Loading PRs..." & sleep 0.1 && printf "\r⠸ Loading PRs..." & PRS=$(gh pr list --search "involves:@me state:open sort:updated-desc" --limit 10 --json number,title,author,reviewDecision 2>/dev/null); if [ -z "$PRS" ] || [ "$PRS" = "[]" ]; then clear; echo ""; echo "No open PRs"; exit 0; fi; clear; echo "" && echo "$PRS" | jq -r '"'"'def lpad(n): tostring | (n - length) as $l | if $l > 0 then ("0" * $l) + . else . end; (max_by(.number) | .number | tostring | length) as $width | .[] | [if .reviewDecision == "APPROVED" then "✓" elif .reviewDecision == "CHANGES_REQUESTED" then "✗" elif .reviewDecision == "REVIEW_REQUIRED" then "○" else "•" end, ("#" + (.number | lpad($width))), ("(" + (.author.login | split("-") | map(.[0:1]) | join("") | ascii_upcase) + ")"), (if (.title|length) > 43 then .title[0:43] + "..." else .title end)] | join("  ")'"'"' | sed "s/✓/\x1b[32m✓\x1b[0m/g" | sed "s/✗/\x1b[31m✗\x1b[0m/g" | sed "s/○/\x1b[33m○\x1b[0m/g" | sed "s/#\([0-9]*\)/\x1b[32m#\1\x1b[0m/g")']],
          height = 13,
          ttl = 0,
        },
      }

      opts.dashboard.sections = sections
      require("snacks").setup(opts)

      -- ============================================================================
      -- PR PICKER FUNCTION
      -- ============================================================================

      local function pick_pr()
        -- Cache for PR preview data (cleared on each picker open)
        local pr_cache = {}

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
        -- PREFETCH PR DETAILS
        -- ========================================================================

        -- Prefetch all PR details in parallel
        for _, pr in ipairs(prs) do
          vim.system(
            {
              "gh",
              "pr",
              "view",
              tostring(pr.number),
              "--json",
              "number,title,author,state,reviewDecision,createdAt,updatedAt,url,body,commits,additions,deletions,comments,reviewRequests,statusCheckRollup,mergeable,headRefName",
            },
            {},
            vim.schedule_wrap(function(result)
              if result.code == 0 then
                local ok_decode, pr_data = pcall(vim.fn.json_decode, result.stdout)
                if ok_decode and pr_data then
                  pr_cache[pr.number] = pr_data
                end
              end
            end)
          )
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

          local pr_data

          -- Check cache first
          if pr_cache[ctx.item.number] then
            pr_data = pr_cache[ctx.item.number]
          else
            -- Fetch detailed PR info if not cached
            local handle = io.popen(string.format(
              'gh pr view %d --json number,title,author,state,reviewDecision,createdAt,updatedAt,url,body,commits,additions,deletions,comments,reviewRequests,statusCheckRollup,mergeable,headRefName',
              ctx.item.number
            ))
            local result = handle:read("*a")
            handle:close()

            local ok
            ok, pr_data = pcall(vim.fn.json_decode, result)
            if not ok or not pr_data then
              ctx.preview:notify("Error loading PR details", "error")
              return
            end

            -- Cache the result
            pr_cache[ctx.item.number] = pr_data
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

          -- Reviewers
          if pr_data.reviewRequests and #pr_data.reviewRequests > 0 then
            local reviewers = {}
            for _, req in ipairs(pr_data.reviewRequests) do
              table.insert(reviewers, req.login)
            end
            add_line("Reviewers: " .. table.concat(reviewers, ", "), "Identifier", "Function")
          end

          -- Mergeable status
          if pr_data.mergeable then
            local mergeable_text = pr_data.mergeable == "MERGEABLE" and "✓ No conflicts"
              or pr_data.mergeable == "CONFLICTING" and "✗ Has conflicts"
              or "? Unknown"
            local mergeable_hl = pr_data.mergeable == "MERGEABLE" and "DiagnosticOk"
              or pr_data.mergeable == "CONFLICTING" and "DiagnosticError"
              or "DiagnosticWarn"
            add_line("Mergeable: " .. mergeable_text, mergeable_hl, "Function")
          end

          -- CI/CD Status
          if pr_data.statusCheckRollup and #pr_data.statusCheckRollup > 0 then
            local passing = 0
            local failing = 0
            local pending = 0

            for _, check in ipairs(pr_data.statusCheckRollup) do
              if check.conclusion == "SUCCESS" or check.state == "SUCCESS" then
                passing = passing + 1
              elseif check.conclusion == "FAILURE" or check.state == "FAILURE" then
                failing = failing + 1
              else
                pending = pending + 1
              end
            end

            local status_text = string.format("✓ %d  ✗ %d  ○ %d", passing, failing, pending)
            local status_hl = failing > 0 and "DiagnosticError"
              or pending > 0 and "DiagnosticWarn"
              or "DiagnosticOk"
            add_line("Checks: " .. status_text, status_hl, "Function")
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

          -- Comments (filter out test results and bot comments)
          if pr_data.comments and #pr_data.comments > 0 then
            -- Filter comments to exclude test results and automated comments
            local filtered_comments = {}
            for _, comment in ipairs(pr_data.comments) do
              local is_bot = comment.author and comment.author.login and (
                comment.author.login:match("bot$") or
                comment.author.login:match("^github%-actions") or
                comment.author.login:match("^dependabot")
              )
              local is_test_result = comment.body and (
                comment.body:match("^## Test Results") or
                comment.body:match("^### Test Summary") or
                comment.body:match("^CI/CD") or
                comment.body:match("^Build Status") or
                comment.body:match("^Tests:") or
                comment.body:match("✓.*tests passing") or
                comment.body:match("✗.*tests failing")
              )

              if not is_bot and not is_test_result then
                table.insert(filtered_comments, comment)
              end
            end

            -- Sort comments by date descending (most recent first)
            table.sort(filtered_comments, function(a, b)
              return a.createdAt > b.createdAt
            end)

            -- Only show comments section if there are filtered comments
            if #filtered_comments > 0 then
              add_line("")
              add_line("─────────────────────────────────────────────────────────────", "Comment")
              add_line("")
              add_line("Comments (" .. #filtered_comments .. ")", "Function")
              add_line("")

              for i, comment in ipairs(filtered_comments) do
                -- Comment header
                local time = comment.createdAt:gsub("T", " "):gsub("Z", "")
                add_line("@" .. comment.author.login .. " • " .. time, "Identifier")
                add_line("")

                -- Comment body
                if comment.body and comment.body ~= "" then
                  for line in comment.body:gsub("\r\n", "\n"):gsub("\r", "\n"):gmatch("[^\n]*") do
                    -- Skip image lines completely (both HTML and markdown)
                    local has_html_img = line:match('<img[^>]*>')
                    local has_md_img = line:match("!%[([^%]]*)%]%(([^%)]+)%)")

                    if not has_html_img and not has_md_img then
                      -- Handle markdown quote blocks - convert > to readable format
                      local is_quote = line:match("^>+%s*")
                      line = line:gsub("^>+%s*", "  │ ")

                      local line_num = #text
                      table.insert(text, line)

                      -- Add grey highlight for quoted lines
                      if is_quote then
                        table.insert(highlights, {
                          row = line_num,
                          col = 0,
                          end_col = #line,
                          hl_group = "Comment",
                        })
                      end
                    end
                  end
                end

                -- Separator between comments
                if i < #filtered_comments then
                  add_line("")
                  add_line("─────────────────────────────────────────────────────────────", "Comment")
                  add_line("")
                end
              end
            end
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

        -- Set up Ctrl+O globally before opening picker
        local ctrl_o_set = false

        vim.keymap.set({ "n", "i" }, "<C-o>", function()
          -- Check if we're in a picker buffer
          local ft = vim.bo.filetype
          local mode = vim.fn.mode()

          -- Check for all picker-related filetypes
          if ft ~= "snacks_picker_list" and ft ~= "snacks_picker" and ft ~= "snacks_picker_input" then
            -- Not in picker, use default Ctrl+O behavior
            if mode == "i" then
              return vim.api.nvim_replace_termcodes("<C-o>", true, false, true)
            end
            return
          end

          -- We're in the picker - do checkout
          -- If in input field, need to get the line from the list buffer
          local line
          if ft == "snacks_picker_input" then
            -- Find the picker list buffer
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local buf = vim.api.nvim_win_get_buf(win)
              local list_ft = vim.api.nvim_buf_get_option(buf, "filetype")
              if list_ft == "snacks_picker_list" then
                -- Get the cursor position in the list window
                local cursor = vim.api.nvim_win_get_cursor(win)
                line = vim.api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1]
                break
              end
            end
          else
            line = vim.api.nvim_get_current_line()
          end

          local pr_num = line and line:match("#(%d+)")

          if pr_num then
            vim.cmd("close")
            pcall(vim.keymap.del, { "n", "i" }, "<C-o>") -- Clean up
            vim.schedule(function()
              vim.notify("Checking out PR #" .. pr_num .. "...", vim.log.levels.INFO)

              -- Use vim.system for cross-shell compatibility
              vim.system({ "gh", "pr", "checkout", pr_num }, {}, function(result)
                vim.schedule(function()
                  if result.code == 0 then
                    vim.notify("✓ Checked out PR #" .. pr_num, vim.log.levels.INFO)
                  else
                    local err = result.stderr or result.stdout or "Unknown error"
                    vim.notify("✗ Failed: " .. vim.trim(err), vim.log.levels.ERROR)
                  end
                end)
              end)
            end)
          else
            vim.notify("No PR number found", vim.log.levels.WARN)
          end
        end, { desc = "PR Checkout", expr = false, nowait = true })

        ctrl_o_set = true

        Snacks.picker.pick({
          title = "Select PR(s) (Enter: browser, Ctrl+O: checkout)",
          items = items,
          format = format_pr,
          layout = "default",
          win = {
            preview = {
              wo = { wrap = true, linebreak = true },
            },
          },
          preview = preview_pr,
          confirm = function(picker)
            -- Clean up Ctrl+O keymap when closing via Enter
            pcall(vim.keymap.del, { "n", "i" }, "<C-o>")

            local selected = picker:selected({ fallback = true })
            picker:close()
            vim.schedule(function()
              for _, item in ipairs(selected) do
                vim.fn.system("gh pr view " .. item.number .. " --web")
              end
            end)
          end,
        })

        -- Set up autocmd to clean up Ctrl+O when any picker buffer is closed
        local cleanup_group = vim.api.nvim_create_augroup("PRPickerCleanup", { clear = false })
        vim.api.nvim_create_autocmd("BufDelete", {
          group = cleanup_group,
          pattern = "*",
          callback = function()
            -- Check if any picker buffers still exist
            vim.defer_fn(function()
              local has_picker = false
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(buf) then
                  local ok, ft = pcall(vim.api.nvim_buf_get_option, buf, "filetype")
                  if ok and (ft == "snacks_picker" or ft == "snacks_picker_list") then
                    has_picker = true
                    break
                  end
                end
              end

              -- If no picker buffers exist, clean up
              if not has_picker then
                pcall(vim.keymap.del, { "n", "i" }, "<C-o>")
                vim.api.nvim_del_augroup_by_name("PRPickerCleanup")
              end
            end, 50)
          end,
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
            pcall(vim.keymap.del, "n", "p", { buffer = buf })
            vim.keymap.set("n", "p", pick_pr, { buffer = buf, desc = "Browse PRs", nowait = true })
          end)
        end,
      })

      -- Global keymap
      vim.keymap.set("n", "<leader>gp", pick_pr, { desc = "Pick and open PR" })
    end,
  },
}
