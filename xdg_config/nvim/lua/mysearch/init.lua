-- mysearch.lua
local api = vim.api
local fn = vim.fn

-- Create namespace for highlights
local ns_id = api.nvim_create_namespace("mysearch")

local M = {}

-- Store buffers and windows
M.state = {
  results_buf = nil,
  preview_buf = nil,
  filter_buf = nil,
  results_win = nil,
  preview_win = nil,
  filter_win = nil,
  current_files = {},
  filtered_files = {},
}

-- Debug function
local function debug_print(...)
  local args = { ... }
  local str = ""
  for i, v in ipairs(args) do
    if type(v) == "table" then
      str = str .. vim.inspect(v)
    else
      str = str .. tostring(v)
    end
    if i < #args then
      str = str .. " "
    end
  end
  api.nvim_echo({ { str, "WarningMsg" } }, true, {})
end

-- Get dimensions for floating windows
local function get_window_dimensions()
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  local results_width = math.floor(width * 0.3)
  local preview_width = math.floor(width * 0.5)
  local filter_height = 1
  local win_height = math.floor(height * 0.8)

  local main_row = math.floor((height - win_height) / 2)
  local filter_row = main_row + win_height + 1
  local results_col = math.floor((width - (results_width + preview_width)) / 2)
  local preview_col = results_col + results_width

  return {
    results_width = results_width,
    preview_width = preview_width,
    win_height = win_height,
    filter_height = filter_height,
    main_row = main_row,
    filter_row = filter_row,
    results_col = results_col,
    preview_col = preview_col,
  }
end

-- Create floating window
local function create_floating_window(width, height, row, col, border)
  local buf = api.nvim_create_buf(false, true)
  if buf == 0 then
    debug_print("Failed to create buffer")
    return nil, nil
  end

  local win_opts = {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = border or "single",
  }

  local ok, win = pcall(api.nvim_open_win, buf, true, win_opts)
  if not ok then
    debug_print("Failed to create window:", win)
    return nil, nil
  end

  return buf, win
end

-- Check if ripgrep is available
local function check_dependencies()
  local rg_exists = vim.fn.executable("rg") == 1
  if not rg_exists then
    debug_print("ripgrep (rg) is not installed. Please install it first.")
    return false
  end
  return true
end

-- Apply filter to files
local function apply_filter(filter_text)
  if filter_text == "" then
    M.state.filtered_files = M.state.current_files
  else
    M.state.filtered_files = {}
    for _, file in ipairs(M.state.current_files) do
      if file:lower():find(filter_text:lower()) then
        table.insert(M.state.filtered_files, file)
      end
    end
  end

  -- Update results window
  if M.state.results_buf then
    api.nvim_buf_set_lines(M.state.results_buf, 0, -1, false, M.state.filtered_files)
  end
end

-- Create filter window
local function create_filter_window(dims)
  -- Create filter buffer and window
  debug_print("Creating filter window...")

  local buf = api.nvim_create_buf(false, true)
  if not buf then
    debug_print("Failed to create filter buffer")
    return nil, nil
  end

  local filter_opts = {
    relative = "editor",
    row = dims.filter_row,
    col = dims.results_col,
    width = dims.results_width + dims.preview_width,
    height = dims.filter_height,
    style = "minimal",
    border = "single",
    zindex = 50, -- Make sure filter window is on top
  }

  local ok, win = pcall(api.nvim_open_win, buf, true, filter_opts)
  if not ok then
    debug_print("Failed to create filter window:", win)
    return nil, nil
  end

  return buf, win
end

-- Setup filter window
local function setup_filter_window(dims)
  -- Create the filter window
  local buf, win = create_filter_window(dims)
  if not buf or not win then
    debug_print("Failed to create filter window components")
    return
  end

  M.state.filter_buf = buf
  M.state.filter_win = win

  -- Set buffer options
  vim.bo[buf].buftype = "prompt"
  vim.fn.prompt_setprompt(buf, "Filter: ")

  -- Start in insert mode
  vim.cmd("startinsert")

  -- Set up autocommands for filter updates
  local filter_group = api.nvim_create_augroup("MySearchFilter", { clear = true })
  api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = filter_group,
    buffer = buf,
    callback = function()
      local filter_text = vim.fn.getline("."):sub(#"Filter: " + 1)
      apply_filter(filter_text)
    end,
  })

  -- Add keymap to move to results window
  api.nvim_buf_set_keymap(
    buf,
    "i",
    "<CR>",
    '<ESC>:lua vim.api.nvim_set_current_win(require("mysearch").state.results_win)<CR>',
    { noremap = true, silent = true }
  )

  debug_print("Filter window setup complete")
end

-- Update preview window with file content
local function update_preview()
  if not M.state.results_win or not M.state.preview_buf then
    return
  end

  local ok, pos = pcall(api.nvim_win_get_cursor, M.state.results_win)
  if not ok then
    debug_print("Failed to get cursor position:", pos)
    return
  end

  local current_line = pos[1]
  local file_path = M.state.filtered_files[current_line]

  if file_path then
    -- Check if file exists
    if vim.fn.filereadable(file_path) == 0 then
      debug_print("File not readable:", file_path)
      return
    end

    -- Clear existing content
    pcall(api.nvim_buf_set_option, M.state.preview_buf, "modifiable", true)
    pcall(api.nvim_buf_set_lines, M.state.preview_buf, 0, -1, false, {})

    -- Read file content
    local ok, lines = pcall(vim.fn.readfile, file_path)
    if not ok then
      debug_print("Failed to read file:", file_path)
      return
    end

    pcall(api.nvim_buf_set_lines, M.state.preview_buf, 0, -1, false, lines)

    -- Set filetype for syntax highlighting
    local filetype = vim.filetype.match({ filename = file_path })
    if filetype then
      pcall(api.nvim_buf_set_option, M.state.preview_buf, "filetype", filetype)
    end

    pcall(api.nvim_buf_set_option, M.state.preview_buf, "modifiable", false)
  end
end

-- Open the selected file
local function open_selected_file()
  if not M.state.results_win then
    return
  end

  local ok, pos = pcall(api.nvim_win_get_cursor, M.state.results_win)
  if not ok then
    return
  end

  local current_line = pos[1]
  local file_path = M.state.filtered_files[current_line]

  if file_path then
    M.close_windows()
    vim.cmd("edit " .. vim.fn.fnameescape(file_path))
  end
end

-- Execute the ripgrep search
local function execute_search(word, callback)
  local files = {}
  local function on_stdout(_, data, _)
    for _, line in ipairs(data) do
      if line ~= "" then
        table.insert(files, line)
      end
    end
  end

  local function on_exit(_, code, _)
    debug_print("Search completed with code:", code)
    debug_print("Found files:", #files)
    callback(files)
  end

  local cmd = { "rg", "--files-with-matches", word, "." }
  debug_print("Running command:", vim.inspect(cmd))

  local job_id = vim.fn.jobstart(cmd, {
    cwd = vim.fn.getcwd(),
    on_stdout = on_stdout,
    on_exit = on_exit,
    stdout_buffered = true,
  })

  if job_id <= 0 then
    debug_print("Failed to start job")
    callback({})
  end
end

-- Initialize windows and content
function M.init_windows(search_word)
  if not check_dependencies() then
    return
  end

  if not search_word or search_word == "" then
    debug_print("No search word provided")
    return
  end

  local dims = get_window_dimensions()

  -- Create results window first
  M.state.results_buf, M.state.results_win =
    create_floating_window(dims.results_width, dims.win_height, dims.main_row, dims.results_col)

  if not M.state.results_buf or not M.state.results_win then
    debug_print("Failed to create results window")
    return
  end

  -- Create preview window
  M.state.preview_buf, M.state.preview_win =
    create_floating_window(dims.preview_width, dims.win_height, dims.main_row, dims.preview_col)

  if not M.state.preview_buf or not M.state.preview_win then
    debug_print("Failed to create preview window")
    M.close_windows()
    return
  end

  -- Set buffer options
  pcall(api.nvim_buf_set_option, M.state.results_buf, "buftype", "nofile")
  pcall(api.nvim_buf_set_option, M.state.preview_buf, "buftype", "nofile")

  -- Set up keymaps for results window
  api.nvim_buf_set_keymap(
    M.state.results_buf,
    "n",
    "<CR>",
    ':lua require("mysearch").open_selected_file()<CR>',
    { noremap = true, silent = true }
  )
  api.nvim_buf_set_keymap(
    M.state.results_buf,
    "n",
    "q",
    ':lua require("mysearch").close_windows()<CR>',
    { noremap = true, silent = true }
  )

  -- Execute search
  execute_search(search_word, function(files)
    if #files == 0 then
      debug_print("No files found containing word:", search_word)
      M.close_windows()
      return
    end

    M.state.current_files = files
    M.state.filtered_files = files

    -- Populate results window
    pcall(api.nvim_buf_set_lines, M.state.results_buf, 0, -1, false, files)

    -- Set up autocmd for cursor movement
    local augroup = api.nvim_create_augroup("MySearch", { clear = true })
    pcall(api.nvim_create_autocmd, "CursorMoved", {
      group = augroup,
      buffer = M.state.results_buf,
      callback = update_preview,
    })

    -- Create and setup filter window
    setup_filter_window(dims)

    -- Update preview with first result
    if #files > 0 then
      update_preview()
    end

    -- Move cursor to results window
    api.nvim_set_current_win(M.state.results_win)
  end)
end

-- Close all windows and clean up
function M.close_windows()
  if M.state.filter_win and api.nvim_win_is_valid(M.state.filter_win) then
    pcall(api.nvim_win_close, M.state.filter_win, true)
  end
  if M.state.results_win and api.nvim_win_is_valid(M.state.results_win) then
    pcall(api.nvim_win_close, M.state.results_win, true)
  end
  if M.state.preview_win and api.nvim_win_is_valid(M.state.preview_win) then
    pcall(api.nvim_win_close, M.state.preview_win, true)
  end

  M.state.filter_buf = nil
  M.state.results_buf = nil
  M.state.preview_buf = nil
  M.state.filter_win = nil
  M.state.results_win = nil
  M.state.preview_win = nil
  M.state.current_files = {}
  M.state.filtered_files = {}
end

-- Main command function
function M.mysearch()
  local word = vim.fn.expand("<cword>")
  debug_print("Initial word under cursor:", word)

  M.close_windows()

  if word == "" then
    word = vim.fn.input("Enter search term: ")
    if word == "" then
      debug_print("No search term provided")
      return
    end
  end

  debug_print("Searching for word:", word)
  M.init_windows(word)
end

-- Open selected file (exposed for keymapping)
function M.open_selected_file()
  open_selected_file()
end

-- Setup function to be called from init.lua
function M.setup()
  api.nvim_create_user_command("MySearch", M.mysearch, {})
  api.nvim_set_keymap("n", "<leader>ms", ":MySearch<CR>", { noremap = true, silent = true })
end

return M
