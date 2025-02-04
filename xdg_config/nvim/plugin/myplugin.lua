-- plugin/myplugin.lua

-- Create a user command that calls `say_hello()` from our module
vim.api.nvim_create_user_command("MyPluginHello", function()
  require("myplugin").say_hello()
end, {})

-- Create a user command that calls `say_goodbye()` from our module
vim.api.nvim_create_user_command("MyPluginGoodbye", function()
  require("myplugin").say_goodbye()
end, {})

-- Create a user command that calls the function from our module
vim.api.nvim_create_user_command("MyPluginFloatingLs", function()
  require("myplugin").open_floating_ls()
end, {})
