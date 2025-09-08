require('mason').setup({
  PATH = 'append',
})

require('mason-lspconfig').setup({
  ensure_installed = { 
    'rust_analyzer', 
    'ts_ls',
  },
})

-- Set up lspconfig.
-- For autocompletion.
local capabilities = require('cmp_nvim_lsp').default_capabilities()

require('lspconfig').rust_analyzer.setup({
  capabilities = capabilities
})

require('lspconfig').ts_ls.setup({
  capabilities = capabilities,
  on_attach = function(client)
    -- Avoid LSP formatting conflicts
    -- https://github.com/nvimtools/none-ls.nvim/wiki/Avoiding-LSP-formatting-conflicts
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
})

function withargs(f)
  return function (opts) 
    local fargs = opts.fargs or {} 
    return f(unpack(fargs)) 
  end
end

local usercmd = vim.api.nvim_create_user_command
local lspbuf = vim.lsp.buf
local diag = vim.diagnostic

diag.config({
  severity_sort = true,
})

usercmd('LShov', withargs(lspbuf.hover), { 
  nargs = 0,
  desc = 'vim.lsp.buf.hover'
})

usercmd('LSfmt', withargs(lspbuf.format), { 
  nargs = 0,
  desc = 'vim.lsp.buf.format'
})

usercmd('LSren', withargs(lspbuf.rename), {
  nargs = 1,
  desc = 'vim.lsp.buf.rename'
})

usercmd('LScmp', withargs(lspbuf.completion), {
  nargs = 0,
  desc = 'vim.lsp.buf.completion'
})

usercmd('LSdef', withargs(lspbuf.definition), {
  nargs = 0,
  desc = 'vim.lsp.buf.definition'
})

usercmd('LSref', withargs(lspbuf.references), {
  nargs = 0,
  desc = 'vim.lsp.buf.references'
})

usercmd('LSact', withargs(lspbuf.code_action), {
  nargs = 0,
  desc = 'vim.lsp.buf.code_action'
})

usercmd('LSdec', withargs(lspbuf.declaration), {
  nargs = 0,
  desc = 'vim.lsp.buf.declaration'
})

usercmd('LShie', withargs(lspbuf.typehierarchy), {
  nargs = "?",
  desc = 'vim.lsp.buf.typehierarchy'
}) -- subtypes, supertypes

usercmd('LSimp', withargs(lspbuf.implementation), {
  nargs = 0,
  desc = 'vim.lsp.buf.implementation'
})

usercmd('LSinc', withargs(lspbuf.incoming_calls), {
  nargs = 0,
  desc = 'vim.lsp.buf.incoming_calls'
})

usercmd('LSouc', withargs(lspbuf.outgoing_calls), {
  nargs = 0,
  desc = 'vim.lsp.buf.outgoing_calls'
})

usercmd('LSsig', withargs(lspbuf.signature_help), {
  nargs = 0,
  desc = 'vim.lsp.buf.signature_help'
})

usercmd('LSsym', withargs(lspbuf.document_symbol), {
  nargs = 0,
  desc = 'vim.lsp.buf.document_symbol'
})

usercmd('LSexe', withargs(lspbuf.execute_command), {
  nargs = "*",
  desc = 'vim.lsp.buf.execute_command'
})

usercmd('LStyp', withargs(lspbuf.type_definition), {
  nargs = 0,
  desc = 'vim.lsp.buf.type_definition'
})

usercmd('LSclr', withargs(lspbuf.clear_references), {
  nargs = 0,
  desc = 'vim.lsp.buf.clear_references'
})

usercmd('LSgym', withargs(lspbuf.workspace_symbol), { -- [g]lobal s[ym]bol 
  nargs = 1,
  desc = 'vim.lsp.buf.workspace_symbol'
})

usercmd('LSdhl', withargs(lspbuf.document_highlight), {
  nargs = 0,
  desc = 'vim.lsp.buf.document_highlight'
})

usercmd('LSawf', withargs(lspbuf.add_workspace_folder), {
  nargs = 1,
  desc = 'vim.lsp.buf.add_workspace_folder'
})

usercmd('LSlwf', withargs(lspbuf.list_workspace_folders), {
  nargs = 0,
  desc = 'vim.lsp.buf.list_workspace_folders'
})

usercmd('LSrwf', withargs(lspbuf.remove_workspace_folder), {
  nargs = 1,
  desc = 'vim.lsp.buf.remove_workspace_folder'
})

local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set

keymap('n', 'gb', lspbuf.format, opts) -- [g]o [b]eauty (and it's easy to press)
keymap('n', '<leader>vh', lspbuf.document_highlight, opts) -- [v]iew [h]ighlights
keymap('n', '<leader>vd', diag.open_float, opts) -- [v]iew [d]iagnostic

-- Global Default Keymaps
-- grn: (Normal mode) Calls vim.lsp.buf.rename(). Used to rename the symbol under the cursor.
-- gra: (Normal and Visual mode) Calls vim.lsp.buf.code_action(). Opens a menu of available code actions at the cursor or for the selected range.
-- grr: (Normal mode) Calls vim.lsp.buf.references(). Lists all references to the symbol under the cursor in the quickfix window.
-- gri: (Normal mode) Calls vim.lsp.buf.implementation(). Lists all implementations for the symbol under the cursor in the quickfix window.
-- grt: (Normal mode) Calls vim.lsp.buf.type_definition(). Jumps to the type definition of the symbol under the cursor.
-- gO: (Normal mode) Calls vim.lsp.buf.document_symbol(). Lists all symbols (functions, variables, etc.) in the current buffer.
-- <C-S> (Ctrl-S): (Insert mode) Calls vim.lsp.buf.signature_help(). Displays signature help for the function/method being called.
-- an and in: (Visual mode) These are for incremental selections, using vim.lsp.buf.selection_range(). an selects the "a" (around) current node, in selects the "i" (inside) current node. This is often used with plugins like nvim-treesitter-textobjects for more powerful text selection.
--
-- Buffer-Local Default Behaviors/Options
-- K: (Normal mode) Calls vim.lsp.buf.hover(). Displays hover information/documentation for the symbol under the cursor in a floating window. (Note: This overrides K's traditional behavior of keywordprg if that's not explicitly set).
-- gd: (Normal mode) When tagfunc is set to vim.lsp.tagfunc(), which it is by default when LSP attaches, gd (go to definition) will use the LSP server.
-- <C-]>: (Normal mode) Jumps to the definition of the symbol under the cursor, also utilizing the LSP's tagfunc.
-- <C-W>] and <C-W>}: These are related to jumping to tags in new windows, also using tagfunc.
-- [d: (Normal mode) Calls vim.diagnostic.goto_prev(). Jumps to the previous diagnostic in the current file.
-- ]d: (Normal mode) Calls vim.diagnostic.goto_next(). Jumps to the next diagnostic in the current file.
-- omnifunc: This option is set to vim.lsp.omnifunc(), allowing you to trigger completion with <C-X><C-O> in insert mode.
-- formatexpr: This option is set to vim.lsp.formatexpr(), which means you can format lines or visual selections using the built-in gq operator.


