vim.opt.background = "dark"
vim.cmd.colorscheme("kanagawa-wave")

-- local groups = {
--   "DiagnosticUnderlineError",
--   "DiagnosticUnderlineWarn",
--   "DiagnosticUnderlineInfo",
--   "DiagnosticUnderlineHint",
-- }

-- -- Disable undercurl and enable underline for diagnostic highlight groups
-- for _, group in ipairs(groups) do
--   local hl = vim.api.nvim_get_hl(0, { name = group })
--   hl.undercurl = false
--   hl.underline = true
--   vim.api.nvim_set_hl(0, group, hl)
-- end

-- Define a new highlight group for general quickfix messages with a yellow underline
vim.api.nvim_set_hl(0, "DiagnosticUnderlineHighlight", { underline = true, sp = "#d7cd3f" })

-- Define a new highlight group for location list items: clone a base style, change to yellow text, no bold
local base_hl = vim.api.nvim_get_hl(0, { name = "LspReferenceText" })
vim.api.nvim_set_hl(
  0,
  "DiagnosticHighlight",
  vim.tbl_extend("force", base_hl, { fg = "#d7cd3f", bold = false })
)
