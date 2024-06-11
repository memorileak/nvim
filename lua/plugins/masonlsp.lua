require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = { 
    "rust_analyzer", 
    "tsserver"
  },
})

-- Set up lspconfig.
-- For autocompletion.
local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("lspconfig").rust_analyzer.setup {
  capabilities = capabilities
}

require("lspconfig").tsserver.setup {
  capabilities = capabilities
}

function withargs(f)
  return function (opts) 
    local fargs = opts.fargs or {} 
    return f(unpack(fargs)) 
  end
end

local usercmd = vim.api.nvim_create_user_command
local lspbuf = vim.lsp.buf

usercmd('LShov', withargs(lspbuf.hover), { nargs = 0, desc = 'vim.lsp.buf.hover' })
usercmd('LSfmt', withargs(lspbuf.format), { nargs = 0, desc = 'vim.lsp.buf.format' })
usercmd('LSren', withargs(lspbuf.rename), { nargs = 1, desc = 'vim.lsp.buf.rename' })
usercmd('LScmp', withargs(lspbuf.completion), { nargs = 0, desc = 'vim.lsp.buf.completion' })
usercmd('LSdef', withargs(lspbuf.definition), { nargs = 0, desc = 'vim.lsp.buf.definition' })
usercmd('LSref', withargs(lspbuf.references), { nargs = 0, desc = 'vim.lsp.buf.references' })
usercmd('LSact', withargs(lspbuf.code_action), { nargs = 0, desc = 'vim.lsp.buf.code_action' })
usercmd('LSdec', withargs(lspbuf.declaration), { nargs = 0, desc = 'vim.lsp.buf.declaration' })
usercmd('LStph', withargs(lspbuf.typehierarchy), { nargs = "?", desc = 'vim.lsp.buf.typehierarchy' }) -- subtypes, supertypes
usercmd('LSimp', withargs(lspbuf.implementation), { nargs = 0, desc = 'vim.lsp.buf.implementation' })
usercmd('LSinc', withargs(lspbuf.incoming_calls), { nargs = 0, desc = 'vim.lsp.buf.incoming_calls' })
usercmd('LSouc', withargs(lspbuf.outgoing_calls), { nargs = 0, desc = 'vim.lsp.buf.outgoing_calls' })
usercmd('LSsig', withargs(lspbuf.signature_help), { nargs = 0, desc = 'vim.lsp.buf.signature_help' })
usercmd('LSdsy', withargs(lspbuf.document_symbol), { nargs = 0, desc = 'vim.lsp.buf.document_symbol' })
usercmd('LSexe', withargs(lspbuf.execute_command), { nargs = "*", desc = 'vim.lsp.buf.execute_command' })
usercmd('LStpd', withargs(lspbuf.type_definition), { nargs = 0, desc = 'vim.lsp.buf.type_definition' })
usercmd('LScrf', withargs(lspbuf.clear_references), { nargs = 0, desc = 'vim.lsp.buf.clear_references' })
usercmd('LSwsy', withargs(lspbuf.workspace_symbol), { nargs = 1, desc = 'vim.lsp.buf.workspace_symbol' })
usercmd('LSdhl', withargs(lspbuf.document_highlight), { nargs = 0, desc = 'vim.lsp.buf.document_highlight' })
usercmd('LSawf', withargs(lspbuf.add_workspace_folder), { nargs = 1, desc = 'vim.lsp.buf.add_workspace_folder' })
usercmd('LSlwf', withargs(lspbuf.list_workspace_folders), { nargs = 0, desc = 'vim.lsp.buf.list_workspace_folders' })
usercmd('LSrwf', withargs(lspbuf.remove_workspace_folder), { nargs = 1, desc = 'vim.lsp.buf.remove_workspace_folder' })

local opts = { noremap = true, silent = true }
local setkeymap = vim.keymap.set

setkeymap('n', 'gd', lspbuf.definition, opts)
setkeymap('n', 'gr', lspbuf.references, opts)
setkeymap('n', 'gD', lspbuf.declaration, opts)
setkeymap('n', 'gI', lspbuf.implementation, opts)
setkeymap('n', 'gy', lspbuf.type_definition, opts)
setkeymap('n', 'K', lspbuf.hover, opts)
setkeymap('n', 'gK', lspbuf.signature_help, opts)
setkeymap('i', '<c-k>', lspbuf.signature_help, opts)
setkeymap('n', 'mm', lspbuf.format, opts)

