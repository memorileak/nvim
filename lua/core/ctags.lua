local config_dir = vim.fn.stdpath("config")
local genctags_script = config_dir .. "/utils/generate_ctags.sh"

vim.keymap.set("n", "<leader>ct", "<cmd>!" .. genctags_script .. "<CR>", {
  desc = "Generate ctags for the current project",
  noremap = true,
})
