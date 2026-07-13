vim.cmd("compiler eslint")

local config_dir = vim.fn.stdpath("config")
local formatter_path = config_dir .. "/utils/eslint-formatter.js"

vim.opt_local.makeprg = "npx --no-install eslint -f " .. formatter_path .. " ."
vim.opt_local.errorformat = [[%f(%l\,%c): %t : %m]]
