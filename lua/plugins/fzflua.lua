local fzflua = require('fzf-lua')
local actions = fzflua.actions

require('fzf-lua').setup({
  'hide',
  keymap = {
    fzf = {
      true,
      -- fzf '--bind=' options
      -- true,        -- uncomment to inherit all the below in your custom config
      -- ["ctrl-z"]      = "abort",
      -- ["ctrl-u"]      = "unix-line-discard",
      -- ["ctrl-f"]      = "half-page-down",
      -- ["ctrl-b"]      = "half-page-up",
      -- ["ctrl-a"]      = "beginning-of-line",
      -- ["ctrl-e"]      = "end-of-line",
      -- ["alt-a"]       = "toggle-all",
      -- ["alt-g"]       = "first",
      -- ["alt-G"]       = "last",
      -- Only valid with fzf previewers (bat/cat/git/etc)
      -- ["f3"]          = "toggle-preview-wrap",
      -- ["f4"]          = "toggle-preview",
      -- ["shift-down"]  = "preview-page-down",
      -- ["shift-up"]    = "preview-page-up",
    },
  },
  actions = {
    -- Below are the default actions, setting any value in these tables will override
    -- the defaults, to inherit from the defaults change [1] from `false` to `true`
    files = {
      true,
      ['ctrl-x']      = actions.file_split,
      -- true,        -- uncomment to inherit all the below in your custom config
      -- Pickers inheriting these actions:
      --   files, git_files, git_status, grep, lsp, oldfiles, quickfix, loclist,
      --   tags, btags, args, buffers, tabs, lines, blines
      -- `file_edit_or_qf` opens a single selection or sends multiple selection to quickfix
      -- replace `enter` with `file_edit` to open all files/bufs whether single or multiple
      -- replace `enter` with `file_switch_or_edit` to attempt a switch in current tab first
      -- ['enter']       = actions.file_edit_or_qf,
      -- ['ctrl-s']      = actions.file_split,
      -- ['ctrl-v']      = actions.file_vsplit,
      -- ['ctrl-t']      = actions.file_tabedit,
      -- ['alt-q']       = actions.file_sel_to_qf,
      -- ['alt-Q']       = actions.file_sel_to_ll,
      -- ['alt-i']       = actions.toggle_ignore,
      -- ['alt-h']       = actions.toggle_hidden,
      -- ['alt-f']       = actions.toggle_follow,
    },
  }
})

local defaults = fzflua.defaults
local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set

keymap('n', '<leader>ff', fzflua.files, opts)
keymap('n', '<leader>fi', fzflua.git_files, opts)
keymap('n', '<leader>fg', fzflua.live_grep, opts)
keymap('n', '<leader>fb', fzflua.buffers, opts)
keymap('n', '<leader>ft', fzflua.tagstack, opts)

-- LSP related keymaps
keymap('n', '<leader>fd', fzflua.lsp_definitions, opts)
keymap('n', '<leader>fy', fzflua.lsp_typedefs, opts)
keymap('n', '<leader>fr', fzflua.lsp_references, opts)
keymap('n', '<leader>fm', fzflua.lsp_implementations, opts)
keymap('n', '<leader>fs', fzflua.lsp_document_symbols, opts)
keymap('n', '<leader>fS', fzflua.lsp_workspace_symbols, opts)
keymap('n', '<leader>fci', fzflua.lsp_incoming_calls, opts)
keymap('n', '<leader>fco', fzflua.lsp_outgoing_calls, opts)
keymap('n', '<leader>fe', fzflua.diagnostics_document, opts)
keymap('n', '<leader>fE', fzflua.diagnostics_workspace, opts)

-- Custom functions
keymap('n', '<leader>fh', function()
  fzflua.files({
    rg_opts = '--hidden --no-ignore-vcs --follow --color=never '
    -- --hidden: Includes hidden files and directories in the search.
    -- --no-ignore-vcs: Disables the use of VCS ignore files (e.g., .gitignore, .hgignore). 
    --   This ensures files typically ignored by version control are included in the search.
    -- --follow: Follows symbolic links.
    -- --color=never: Disables color output, which can sometimes interfere with fzf.
  })
end, opts)

keymap('v', '<leader>fw', function()
	local text = vim.getVisualSelection()
  fzflua.live_grep({
    search = text,
    rg_opts = '-F ' .. defaults.grep.rg_opts -- Use -F for fixed string search
  })
end, opts)

