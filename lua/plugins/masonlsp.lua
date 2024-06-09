require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = { 
    "rust_analyzer", 
    "tsserver"
  },
})

require("lspconfig").rust_analyzer.setup {}
require("lspconfig").tsserver.setup {}
