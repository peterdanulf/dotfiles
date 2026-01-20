-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

--- Normal mode: Move line down
vim.api.nvim_set_keymap("n", "<D-j>", ":m .+1<CR>==", { noremap = true, silent = true })
-- Normal mode: Move line up
vim.api.nvim_set_keymap("n", "<D-k>", ":m .-2<CR>==", { noremap = true, silent = true })

-- Insert mode: Move line down
vim.api.nvim_set_keymap("i", "<D-j>", "<Esc>:m .+1<CR>==gi", { noremap = true, silent = true })
-- Insert mode: Move line up
vim.api.nvim_set_keymap("i", "<D-k>", "<Esc>:m .-2<CR>==gi", { noremap = true, silent = true })

-- Visual mode: Move selection down
vim.api.nvim_set_keymap("v", "<D-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
-- Visual mode: Move selection up
vim.api.nvim_set_keymap("v", "<D-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })


-- Search next and center
vim.api.nvim_set_keymap("n", "n", "nzzzv", { noremap = true, silent = true })
-- Search previous and center
vim.api.nvim_set_keymap("n", "N", "Nzzzv", { noremap = true, silent = true })
-- Paragraph backward and center
vim.api.nvim_set_keymap("n", "{", "{zz", { noremap = true, silent = true })
-- Paragraph forward and center
vim.api.nvim_set_keymap("n", "}", "}zz", { noremap = true, silent = true })

-- Telescope keybindings
local telescope = require("telescope.builtin")

-- 1. Search in opened buffers
vim.keymap.set("n", "<leader>sB", function()
  telescope.live_grep({ grep_open_files = true })
end, { desc = "Grep Open Buffers" })

-- 2. Search in modified git files
vim.keymap.set("n", "<leader>sf", function()
  local files = vim.fn.systemlist("git diff --name-only")
  if vim.tbl_isempty(files) then
    print("No modified files")
    return
  end
  telescope.live_grep({ search_dirs = files })
end, { desc = "Grep Modified Git Files" })

-- LazyDocker
if vim.fn.executable("lazydocker") == 1 then
  vim.keymap.set("n", "<leader>gD", function()
    LazyVim.terminal("lazydocker", { ctrl_hjkl = true })
  end, { desc = "LazyDocker" })
end
