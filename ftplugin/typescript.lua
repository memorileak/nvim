vim.cmd("compiler tsc")

local formatter = vim.fn.stdpath("config") .. "/utils/eslint-formatter.js"

-- Run both regardless of first command exit status
vim.opt_local.makeprg = "sh -c 'npx --no-install tsc --noEmit --pretty false; npx --no-install eslint -f "
  .. vim.fn.shellescape(formatter)
  .. " .'"

vim.opt_local.errorformat = [[%f(%l\,%c): %t%*[^ ] %m,%f(%l\,%c): %t : %m]]
