vim.cmd("compiler tsc")

vim.opt_local.makeprg = "npx --no-install tsc --noEmit --pretty false"
