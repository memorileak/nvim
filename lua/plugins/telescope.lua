local builtin = require('telescope.builtin')
local opts = { noremap = true, silent = true }

vim.keymap.set('n', '<leader>ff', builtin.find_files, opts)
vim.keymap.set('n', '<leader>fg', builtin.live_grep, opts)
vim.keymap.set('n', '<leader>fb', builtin.buffers, opts)
vim.keymap.set('n', '<leader>fh', builtin.help_tags, opts)
vim.keymap.set('v', '<leader>fw', function()
	local text = vim.getVisualSelection()
	builtin.live_grep({ default_text = text })
end, opts)

-- local keymap = vim.keymap.set
-- local tb = require('telescope.builtin')
-- local opts = { noremap = true, silent = true }
--
-- keymap('n', '<space>g', ':Telescope current_buffer_fuzzy_find<cr>', opts)
-- keymap('v', '<space>g', function()
-- 	local text = vim.getVisualSelection()
-- 	tb.current_buffer_fuzzy_find({ default_text = text })
-- end, opts)
--
-- keymap('n', '<space>G', ':Telescope live_grep<cr>', opts)

