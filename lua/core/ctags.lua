local config_dir = vim.fn.stdpath("config")
local genctags_script = vim.fn.shellescape(config_dir .. "/utils/generate_ctags.sh", true)

local function generate_ctags()
  local extensions = vim.g.ctags_extensions or ""
  local args = ""
  if extensions ~= "" then
    for ext in extensions:gmatch("%S+") do
      args = args .. " " .. vim.fn.shellescape(ext, true)
    end
  end
  vim.cmd("!" .. genctags_script .. args)
end

-- To configure the extensions, put this code in .nvim.lua file:
-- vim.g.ctags_extensions = "rs js ts py lua"

vim.keymap.set("n", "<leader>ct", generate_ctags, {
  desc = "Generate ctags for the current project",
  noremap = true,
})
