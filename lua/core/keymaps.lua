local keymap = vim.keymap.set
local remap_opts = { remap = true, silent = true }

keymap({'n', 'v', 'o', 'i', 'c'}, '<C-j>', '<C-n>', remap_opts)
keymap({'n', 'v', 'o', 'i', 'c'}, '<C-k>', '<C-p>', remap_opts)
