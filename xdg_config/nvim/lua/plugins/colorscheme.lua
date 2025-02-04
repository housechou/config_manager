-- return {
--   -- {
--   --   "folke/tokyonight.nvim",
--   --   lazy = true,
--   --   opts = { style = "storm" },
--   -- },
--   { "ntk148v/habamax.nvim", dependencies = { "rktjmp/lush.nvim" } },
--   -- { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
--   -- Configure LazyVim to load colorscheme
--   {
--     "LazyVim/LazyVim",
--     opts = {
--       -- colorscheme = "catppuccin-mocha",
--       colorscheme = "habamax.nvim",
--     },
--   },
-- }
return {
  {
    "navarasu/onedark.nvim", -- Plugin for the OneDark theme
    priority = 1000, -- Ensure it loads before LazyVim's default theme
    config = function()
      require("onedark").setup({
        style = "darker", -- Set the style to 'darker'
      })
      require("onedark").load() -- Apply the configuration
    end,
  },
}
