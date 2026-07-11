vim.cmd("compiler eslint")

vim.opt_local.makeprg = "npx --no-install eslint --format=unix ."
