local keymap = vim.keymap.set
local remap_opts = { remap = true, silent = true }

keymap({ "n", "v", "o", "i", "c" }, "<C-j>", "<C-n>", remap_opts)
keymap({ "n", "v", "o", "i", "c" }, "<C-k>", "<C-p>", remap_opts)

-- Quickfix List navigation
keymap("n", "]q", "<cmd>cnext<CR>", remap_opts)
keymap("n", "[q", "<cmd>cprev<CR>", remap_opts)

-- Location List navigation
keymap("n", "]l", "<cmd>lnext<CR>", remap_opts)
keymap("n", "[l", "<cmd>lprev<CR>", remap_opts)
