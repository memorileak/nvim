-- To configure Neovim to use :make as your linting command,
-- you must leverage Neovim’s built-in makeprg and errorformat options.
-- This approach redirects the :make command from standard system compilers
-- to your preferred linter and formats the output directly into the Quickfix list.

-- Instead of writing complex custom errorformat regex strings from scratch,
-- you should leverage Neovim’s built-in compilers.
-- Neovim ships with native compiler scripts for cargo, eslint, and tsc.
-- When you invoke them via :compiler <name>, Neovim automatically
-- sets up the perfect, highly resilient errorformat for you.

vim.cmd("compiler cargo")

vim.opt_local.makeprg = "cargo clippy --workspace --message-format=short"
