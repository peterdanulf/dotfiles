local M = {}

-- Required for Telescope picker
local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  vim.notify("Telescope is required for PHP finder", vim.log.levels.ERROR)
  return M
end

-- Find PHP functions and closures in the current file
M.find_php_functions = function()
  -- Get buffer info
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo.filetype
  
  -- Check if we're in a PHP file
  if filetype ~= "php" then
    vim.notify("Not a PHP file", vim.log.levels.WARN)
    return
  end
  
  -- Use simple regex approach instead of treesitter for better compatibility
  local functions = {}
  
  -- Get buffer content
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  
  -- First, try to get LSP symbols for the current file
  local lsp_symbols = {}
  
  -- Get LSP symbols if available
  local function collect_symbols()
    local params = { textDocument = vim.lsp.util.make_text_document_params() }
    vim.lsp.buf_request(bufnr, 'textDocument/documentSymbol', params, function(err, result, _, _)
      if err or not result then return end
      
      -- Process the symbols
      for _, symbol in ipairs(result) do
        -- Only include functions/methods
        if symbol.kind == 12 or symbol.kind == 6 then  -- Function or Method
          table.insert(lsp_symbols, {
            name = symbol.name,
            kind = symbol.kind,
            range = symbol.range or symbol.location.range,
            children = symbol.children,
            detail = symbol.detail,
          })
        end
      end
      
      -- Add LSP symbols to results
      for _, symbol in ipairs(lsp_symbols) do
        -- Skip anonymous functions
        if symbol.name ~= "" and not symbol.name:match("function") then
          local start_line = symbol.range.start.line + 1
          local end_line = symbol.range["end"].line + 1
          
          -- Get context
          local context_start = math.max(1, start_line)
          local context_end = math.min(context_start + 2, #lines)
          local context_lines = {}
          
          for j = context_start, context_end do
            if lines[j] then
              table.insert(context_lines, lines[j])
            end
          end
          
          local context = table.concat(context_lines, " "):gsub("%s+", " ")
          
          -- Trim to reasonable length for display
          if #context > 60 then
            context = string.sub(context, 1, 57) .. "..."
          end
          
          -- Store file info
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
          local file_info = filename .. ":" .. start_line .. " → "
          
          -- Add to functions array
          table.insert(functions, {
            function_name = symbol.name,
            line = start_line,
            col = 0,
            context = context,
            file_info = file_info,
            symbol_type = symbol.kind == 12 and "function" or "method"
          })
        end
      end
    end)
  end
  
  -- Collect symbols first
  collect_symbols()
  
  -- Allow LSP to process
  vim.wait(100)
  
  -- Find function calls with closures using patterns
  for i, line in ipairs(lines) do
    local owner_function = line:match("([%w_]+)%s*%(.-function%s*%(")
    if owner_function then
      -- Get context
      local context_start = math.max(1, i-1)
      local context_end = math.min(#lines, i+2)
      local context_lines = {}
      
      for j = context_start, context_end do
        if lines[j] then
          table.insert(context_lines, lines[j])
        end
      end
      
      local context = table.concat(context_lines, " "):gsub("%s+", " ")
      
      -- Trim to reasonable length for display
      if #context > 60 then
        context = string.sub(context, 1, 57) .. "..."
      end
      
      -- Store file info
      local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
      local file_info = filename .. ":" .. i .. " → "
      
      -- Add to functions array
      table.insert(functions, {
        function_name = owner_function,
        line = i,
        col = line:find("function") or 0,
        context = context,
        file_info = file_info,
        symbol_type = "closure"
      })
    end
  end
  
  -- Display results
  vim.notify(string.format("Found %d PHP functions and closures", #functions), vim.log.levels.INFO)
  
  -- Exit if none found
  if #functions == 0 then
    return
  end
  
  -- Show in Telescope
  require("telescope.pickers").new({}, {
    prompt_title = "PHP Functions and Closures",
    finder = require("telescope.finders").new_table({
      results = functions,
      entry_maker = function(entry)
        local context = entry.context
        local display_prefix = ""
        
        -- Add file info if available
        if entry.file_info and type(entry.file_info) == "string" then
          display_prefix = entry.file_info
        end
        
        -- Create display text with symbol type
        local symbol_icon = "λ"
        if entry.symbol_type == "function" then
          symbol_icon = "ƒ"
        elseif entry.symbol_type == "method" then
          symbol_icon = "𝓶"
        end
        
        local display = display_prefix .. symbol_icon .. " " .. entry.function_name .. ": " .. context
        
        return {
          value = entry,
          display = display,
          ordinal = display,
          filename = vim.api.nvim_buf_get_name(bufnr),
          lnum = entry.line,
          col = entry.col,
        }
      end
    }),
    sorter = require("telescope.config").values.generic_sorter({}),
    previewer = require("telescope.config").values.qflist_previewer({}),
    attach_mappings = function(_, map)
      map('i', '<CR>', function(bufnr)
        local selection = require("telescope.actions.state").get_selected_entry()
        require("telescope.actions").close(bufnr)
        
        -- Jump to the selection
        if selection then
          vim.api.nvim_win_set_cursor(0, {selection.lnum, selection.col})
          vim.cmd("normal zz") -- Center in view
        end
      end)
      return true
    end,
  }):find()
end

-- Setup function to initialize keymaps and commands
M.setup = function()
  -- Create commands
  vim.api.nvim_create_user_command("FindPHPFunctions", M.find_php_functions, {})
  
  -- Create keymaps
  vim.keymap.set("n", "<leader>cc", M.find_php_functions, {desc = "Find PHP Functions & Closures"})
end

return M
