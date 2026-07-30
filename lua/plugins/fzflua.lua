local core_functions = require("core.functions")
local fzflua = require("fzf-lua")

local get_visual_selection = core_functions.get_visual_selection
local actions = fzflua.actions
local path = fzflua.path
local utils = fzflua.utils

local function sel_append_to_qf(selected, opts, is_loclist)
  local qf_list = {}
  for i = 1, #selected do
    local file = path.entry_to_file(selected[i], opts)
    local text = assert(file.stripped):match(":%d+:%d?%d?%d?%d?:?(.*)$")
    qf_list[#qf_list + 1] = {
      bufnr = file.bufnr,
      filename = file.bufname or file.path or file.uri,
      lnum = file.line or 0,
      valid = 1,
      col = file.col,
      text = text,
    }
  end
  table.sort(qf_list, function(a, b)
    if a.filename ~= b.filename then
      return a.filename < b.filename
    end
    if a.lnum ~= b.lnum then
      return a.lnum < b.lnum
    end
    return a.col < b.col
  end)

  local cmd = utils.get_info().cmd
  local title =
    string.format("[FzfLua] %s%s", cmd and cmd .. ": " or "", utils.resume_get("query", opts) or "")
  if is_loclist then
    vim.fn.setloclist(0, {}, "a", { nr = "$", items = qf_list, title = title })
  else
    vim.fn.setqflist({}, "a", { nr = "$", items = qf_list, title = title })
  end
  local opener = opts[is_loclist and "lopen" or "copen"]
  if type(opener) == "function" then
    opener(selected, opts)
  elseif opener ~= false then
    vim.cmd(opener or (is_loclist and "botright lopen" or "botright copen"))
  end
end

local function file_sel_append_to_qf(selected, opts)
  sel_append_to_qf(selected, opts)
end

local function file_sel_append_to_ll(selected, opts)
  sel_append_to_qf(selected, opts, true)
end

fzflua.setup({
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
      ["alt-q"] = actions.file_sel_to_qf,
      ["alt-Q"] = file_sel_append_to_qf,
      ["alt-l"] = actions.file_sel_to_ll,
      ["alt-L"] = file_sel_append_to_ll,
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
  buffers = {
    actions = {
      ["ctrl-x"] = actions.file_split,
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
    -- Use -U: multiline, -F: fixed string
    rg_opts = "-U -F " .. defaults.grep.rg_opts,
  })
end, opts)

-- Find treesitter symbols in the current buffer
keymap("n", "<leader>bs", fzflua.treesitter, opts)

-- Find tags for the current word under the cursor in the current project
keymap("n", "gd", function()
  fzflua.tags({ query = vim.fn.expand("<cword>") })
end, opts)

keymap("x", "gd", function()
  local text = get_visual_selection()
  fzflua.tags({ query = text })
end, opts)

-- Find tags for the current word under the cursor in the current buffer
keymap("n", "gD", function()
  fzflua.btags({ query = vim.fn.expand("<cword>") })
end, opts)

keymap("x", "gD", function()
  local text = get_visual_selection()
  fzflua.btags({ query = text })
end, opts)

-- Grep tags for the current word under the cursor
keymap("n", "gw", fzflua.tags_grep_cword, opts)
keymap("x", "gw", fzflua.tags_grep_visual, opts)

-- Live grep for the current word under the cursor in the current project
keymap("n", "gs", function()
  fzflua.live_grep({
    search = vim.fn.expand("<cword>"),
    no_esc = true,
    -- Use -U: multiline, -F: fixed string
    rg_opts = "-U -F " .. defaults.grep.rg_opts,
  })
end, opts)

keymap("x", "gs", function()
  local text = get_visual_selection()
  fzflua.live_grep({
    search = text,
    no_esc = true,
    -- Use -U: multiline, -F: fixed string
    rg_opts = "-U -F " .. defaults.grep.rg_opts,
  })
end, opts)

-- Live grep for the current word under the cursor in the current file
keymap("n", "gS", function()
  fzflua.live_grep({
    search = vim.fn.expand("<cword>"),
    search_paths = { vim.fn.expand("%:p") },
    no_esc = true,
    -- Use -U: multiline, -F: fixed string
    rg_opts = "-U -F " .. defaults.grep.rg_opts,
  })
end, opts)

keymap("x", "gS", function()
  local text = get_visual_selection()
  fzflua.live_grep({
    search = text,
    search_paths = { vim.fn.expand("%:p") },
    no_esc = true,
    -- Use -U: multiline, -F: fixed string
    rg_opts = "-U -F " .. defaults.grep.rg_opts,
  })
end, opts)
