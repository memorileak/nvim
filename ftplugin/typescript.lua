vim.cmd("compiler tsc")

local formatter = vim.fn.stdpath("config") .. "/utils/eslint-formatter.js"
local get_files_script = vim.fn.stdpath("config") .. "/utils/get_eslint_files.sh"

-- Run both regardless of first command exit status
vim.opt_local.makeprg = "sh -c 'npx --no-install tsc --noEmit --pretty false; files=$("
  .. vim.fn.shellescape(get_files_script)
  .. " "
  .. vim.fn.expand("%:p")
  .. "); npx --no-install eslint -f "
  .. vim.fn.shellescape(formatter)
  .. " $files'"
  .. [[ \| rg -v '^\s*$']] -- Filter out empty lines from the output

vim.opt_local.errorformat = [[%f(%l\,%c): %t%*[^ ] %m,%f(%l\,%c): %t : %m]]
