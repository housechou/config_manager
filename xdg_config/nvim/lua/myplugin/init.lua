-- lua/myplugin/init.lua

local M = {}

function M.say_hello()
  print("Hello from myplugin!")
end

function M.say_goodbye()
  print("Goodbye from myplugin!")
end

--- Opens a floating window and lists the files in the current directory (using `ls`).
function M.open_floating_ls()
  -- 1. Get a list of files from the current directory
  --    (On Windows, you might replace 'ls' with 'dir', or use a cross-platform method.)
  local lines = vim.fn.systemlist("ls") -- returns a Lua table of lines

  -- 2. Create a new, scratch buffer (not listed, no file)
  local buf = vim.api.nvim_create_buf(false, true)

  -- 3. Set the lines in the buffer to the output of `ls`
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- 4. Determine the size of the floating window
  --    We'll base the height on the number of items returned, but cap it at 15.
  local height = math.min(#lines, 15)
  local width = 40

  -- 5. Set up the window options (centered, minimal style, etc.)
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2, -- Center horizontally
    row = (vim.o.lines - height) / 2, -- Center vertically
    style = "minimal",
    border = "rounded", -- You can use "single" or "none" or others
  }

  -- 6. Open the floating window
  vim.api.nvim_open_win(buf, true, opts)

  -- Optionally, you could make the buffer modifiable or read-only, set keymaps, etc.
end

return M
