
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
