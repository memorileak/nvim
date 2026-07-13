vim.cmd("compiler eslint")

local pipe_head = [[ \| head -n -1]] -- Remove the last line.
local pipe_rg = [[ \| rg -v '^\s*$']] -- Remove empty lines.

vim.opt_local.makeprg = "npx --no-install eslint -f $(npm root -g)/eslint-formatter-compact/index.js ."
  .. pipe_head
  .. pipe_rg
vim.opt_local.errorformat = "%f: line %l\\, col %c\\, %t%*\\a - %m"
