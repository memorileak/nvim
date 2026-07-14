vim.cmd("compiler eslint")

local config_dir = vim.fn.stdpath("config")
local formatter_path = config_dir .. "/utils/eslint-formatter.js"
local get_files_script = config_dir .. "/utils/get_eslint_files.sh"

vim.opt_local.makeprg = "sh -c 'files=$("
  .. vim.fn.shellescape(get_files_script)
  .. " "
  .. vim.fn.expand("%:p")
  .. "); npx --no-install eslint -f "
  .. vim.fn.shellescape(formatter_path)
  .. " $files'"
vim.opt_local.errorformat = [[%f(%l\,%c): %t : %m]]
