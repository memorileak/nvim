local fzflua = require("fzf-lua")
local actions = fzflua.actions

require("fzf-lua").setup({
  "hide",
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
      ["ctrl-x"] = actions.file_split,
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
  },
  tags = {
    -- This forces fzf to allow multiple selections (--multi)
    fzf_opts = { ["--multi"] = true },
  },
  btags = {
    -- This forces fzf to allow multiple selections (--multi)
    fzf_opts = { ["--multi"] = true },
  },
})

local defaults = fzflua.defaults
local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set

keymap("n", "<leader>ff", fzflua.files, opts)
keymap("n", "<leader>fi", fzflua.git_files, opts)
keymap("n", "<leader>fG", fzflua.live_grep, opts)
keymap("n", "<leader>fb", fzflua.buffers, opts)

-- Find tags for the current word/WORD under the cursor in the current project
keymap("n", "<leader>ft", function()
  fzflua.tags({ query = vim.fn.expand("<cword>") })
end, opts)
keymap("n", "<leader>fT", function()
  fzflua.tags({ query = vim.fn.expand("<cWORD>") })
end, opts)

-- Find tags for the current word/WORD under the cursor in the current buffer
keymap("n", "<leader>bt", function()
  fzflua.btags({ query = vim.fn.expand("<cword>") })
end, opts)
keymap("n", "<leader>bT", function()
  fzflua.btags({ query = vim.fn.expand("<cWORD>") })
end, opts)

-- Grep tags for the current word/WORD under the cursor
keymap("n", "<leader>wt", fzflua.tags_grep_cword, opts)
keymap("n", "<leader>wT", fzflua.tags_grep_cWORD, opts)

-- Grep tags for the visually selected text
keymap("v", "<leader>wt", fzflua.tags_grep_visual, opts)

-- Find files in the current project, including hidden files and files ignored by version control
keymap("n", "<leader>fh", function()
  fzflua.files({
    rg_opts = "--hidden --no-ignore-vcs --follow --color=never ",
    -- --hidden: Includes hidden files and directories in the search.
    -- --no-ignore-vcs: Disables the use of VCS ignore files (e.g., .gitignore, .hgignore).
    --   This ensures files typically ignored by version control are included in the search.
    -- --follow: Follows symbolic links.
    -- --color=never: Disables color output, which can sometimes interfere with fzf.
  })
end, opts)

-- Live grep with fixed string search (no regex interpretation)
keymap("n", "<leader>fg", function()
  fzflua.live_grep({
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)

-- Live grep with fixed string search for the visually selected text in visual mode
keymap("n", "<leader>fw", function()
  fzflua.live_grep({
    search = vim.fn.expand("<cword>"),
    no_esc = true,
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)

keymap("v", "<leader>fW", function()
  fzflua.live_grep({
    search = vim.fn.expand("<cWORD>"),
    no_esc = true,
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)

keymap("v", "<leader>fw", function()
  local text = vim.getVisualSelection()
  fzflua.live_grep({
    search = text,
    no_esc = true,
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)

keymap("n", "<leader>bw", function()
  fzflua.live_grep({
    search = vim.fn.expand("<cword>"),
    search_dirs = { vim.fn.expand("%:p") },
    no_esc = true,
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)

keymap("n", "<leader>bW", function()
  fzflua.live_grep({
    search = vim.fn.expand("<cWORD>"),
    search_dirs = { vim.fn.expand("%:p") },
    no_esc = true,
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)

keymap("v", "<leader>bw", function()
  local text = vim.getVisualSelection()
  fzflua.live_grep({
    search = text,
    search_dirs = { vim.fn.expand("%:p") },
    no_esc = true,
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)
