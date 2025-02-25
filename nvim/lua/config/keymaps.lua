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
