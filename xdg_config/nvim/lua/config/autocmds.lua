-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Disable autoformat for c files
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "c" },
  callback = function()
    vim.b.autoformat = false
    vim.api.nvim_set_hl(0, "@lsp.type.comment.c", {})
    -- vim.o.shiftwidth = 8
    -- vim.o.tabstop = 8
    -- vim.o.softtabstop = 8
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    -- vim.notify(string.format("Yanking: %s", vim.inspect(vim.v.event.regcontents)), vim.log.levels.INFO)
    local copy_to_unnamedplus = require("vim.ui.clipboard.osc52").copy("+")
    copy_to_unnamedplus(vim.v.event.regcontents)
    local copy_to_unnamed = require("vim.ui.clipboard.osc52").copy("*")
    copy_to_unnamed(vim.v.event.regcontents)
  end,
})

-- vim.api.nvim_create_autocmd("TextYankPost", {
--   callback = function()
--     -- Get the yanked content
--     local yanked_text = table.concat(vim.v.event.regcontents, "\n")
--
--     -- Create a pipe command
--     local cmd = io.popen("~/bin/myosc52.sh", "w")
--     if cmd then
--       cmd:write(yanked_text)
--       cmd:close()
--     end
--   end,
-- })
