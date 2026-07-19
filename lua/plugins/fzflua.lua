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
    fzf_opts = {
      ["--multi"] = true,
      ["--exact"] = true,
    },
  },
  btags = {
    fzf_opts = {
      ["--multi"] = true,
      ["--exact"] = true,
    },
  },
})

local defaults = fzflua.defaults
local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set

keymap("n", "<leader>ff", fzflua.files, opts)
keymap("n", "<leader>fi", fzflua.git_files, opts)
keymap("n", "<leader>fG", fzflua.live_grep, opts)
keymap("n", "<leader>fb", fzflua.buffers, opts)

-- Find files in the current project, including hidden files and files ignored by version control
keymap("n", "<leader>fh", function()
  fzflua.files({
    fd_opts = "--type f --hidden --no-ignore --follow --color=never ",
  })
end, opts)

-- Live grep with fixed string search (no regex interpretation)
keymap("n", "<leader>fg", function()
  fzflua.live_grep({
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)

-- Find treesitter symbols in the current buffer
keymap("n", "<leader>bs", fzflua.treesitter, opts)

-- Find tags for the current word under the cursor in the current project
keymap("n", "gd", function()
  fzflua.tags({ query = vim.fn.expand("<cword>") })
end, opts)

keymap("v", "gd", function()
  local text = vim.getVisualSelection()
  fzflua.tags({ query = text })
end, opts)

-- Find tags for the current word under the cursor in the current buffer
keymap("n", "gD", function()
  fzflua.btags({ query = vim.fn.expand("<cword>") })
end, opts)

keymap("v", "gD", function()
  local text = vim.getVisualSelection()
  fzflua.btags({ query = text })
end, opts)

-- Grep tags for the current word under the cursor
keymap("n", "gw", fzflua.tags_grep_cword, opts)
keymap("v", "gw", fzflua.tags_grep_visual, opts)

-- Live grep for the current word under the cursor in the current project
keymap("n", "gs", function()
  fzflua.live_grep({
    search = vim.fn.expand("<cword>"),
    no_esc = true,
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)

keymap("v", "gs", function()
  local text = vim.getVisualSelection()
  fzflua.live_grep({
    search = text,
    no_esc = true,
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)

-- Live grep for the current word under the cursor in the current file
keymap("n", "gS", function()
  fzflua.live_grep({
    search = vim.fn.expand("<cword>"),
    search_paths = { vim.fn.expand("%:p") },
    no_esc = true,
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)

keymap("v", "gS", function()
  local text = vim.getVisualSelection()
  fzflua.live_grep({
    search = text,
    search_paths = { vim.fn.expand("%:p") },
    no_esc = true,
    rg_opts = "-F " .. defaults.grep.rg_opts, -- Use -F for fixed string search
  })
end, opts)
