-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.expandtab = false
vim.opt.smartindent = false
vim.diagnostic.enable(false)
vim.opt.relativenumber = false
vim.opt.swapfile = false
vim.g.editorconfig = true
vim.opt.list = true
vim.opt.listchars = {
  tab = "» ",
  trail = ".",
  multispace = ".",
  space = ".",
  eol = "↲",
  nbsp = "␣",
}

vim.opt.clipboard = unnamedplus

function unnamed_paste(reg)
  return function(lines)
    local content = vim.fn.getreg('"')
    return vim.split(content, "\n")
  end
end

vim.g.clipboard = {
  -- name = "dummy clipboard",
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = unnamed_paste("+"),
    ["*"] = unnamed_paste("*"),
  },
}
