local config_dir = vim.fn.stdpath("config")

local function resolve_script()
  local custom = vim.g.ctags_shell
  if custom and custom ~= "" then
    local path = vim.fs.normalize(vim.fn.getcwd() .. "/" .. custom)
    if vim.fn.filereadable(path) == 1 then
      return vim.fn.shellescape(path, true)
    end
  end
  return vim.fn.shellescape(config_dir .. "/utils/generate_ctags.sh", true)
end

local function generate_ctags()
  local extensions = vim.g.ctags_extensions or ""
  local args = ""
  if extensions ~= "" then
    for ext in extensions:gmatch("%S+") do
      args = args .. " " .. vim.fn.shellescape(ext, true)
    end
  end
  vim.cmd("!" .. resolve_script() .. args)
end

-- To configure the extensions and a custom script, put this code in .nvim.lua file:
-- vim.g.ctags_extensions = "rs js ts py lua"
-- vim.g.ctags_shell = ".nvim/generate_ctags.sh"

vim.keymap.set("n", "<leader>ct", generate_ctags, {
  desc = "Generate ctags for the current project",
  noremap = true,
})
