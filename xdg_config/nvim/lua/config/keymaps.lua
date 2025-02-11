-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "qfh", "<cmd>FzfLua quickfix_stack<cr>", { desc = "Fzf quickfix stack (history)" })
vim.keymap.set("i", "jj", "<esc>", { desc = "go to normal mode" })
