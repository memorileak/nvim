vim.api.nvim_set_var("rust_recommended_style", 0)

vim.opt.title = true
vim.opt.titlestring = "nvim - " .. vim.fn.getcwd()

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.autoindent = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smarttab = true

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.autowriteall = true

vim.opt.foldenable = false
vim.opt.foldmethod = "manual"

-- Put anything you want to happen only in Neovide here
if vim.g.neovide then
  vim.opt.guifont = "JetBrainsMono Nerd Font:h9"
  vim.opt.linespace = 0
  vim.g.neovide_text_gamma = 1.0
  vim.g.neovide_text_contrast = 1.0

  -- Animation when resizing panes
  vim.g.neovide_position_animation_length = 0.00

  -- Animation when moving the cursor
  vim.g.neovide_cursor_animation_length = 0.00
  vim.g.neovide_cursor_trail_size = 0
  vim.g.neovide_cursor_animate_in_insert_mode = false
  vim.g.neovide_cursor_animate_command_line = false

  -- Animation when scrolling
  vim.g.neovide_scroll_animation_far_lines = 0
  vim.g.neovide_scroll_animation_length = 0.00
end
