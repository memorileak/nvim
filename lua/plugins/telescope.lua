require('telescope').setup {
  defaults = {
    layout_strategy = 'horizontal',
    layout_config = {}
  },
  pickers = {
    find_files = {
      hidden = false
    }
  }
}

local builtin = require('telescope.builtin')
local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set

keymap('n', '<leader>ff', builtin.find_files, opts)
keymap('n', '<leader>fg', builtin.live_grep, opts)
keymap('n', '<leader>fb', builtin.buffers, opts)
keymap('n', '<leader>fh', builtin.help_tags, opts)
keymap('v', '<leader>fw', function()
	local text = vim.getVisualSelection()
	builtin.live_grep({ default_text = text })
end, opts)
keymap('n', '<leader>fc', builtin.current_buffer_fuzzy_find, opts)
keymap('v', '<leader>fc', function()
	local text = vim.getVisualSelection()
	builtin.current_buffer_fuzzy_find({ default_text = text })
end, opts)
