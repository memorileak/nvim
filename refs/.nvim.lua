local project_dir = vim.fn.getcwd()
local nvim_lint_shell = vim.fn.shellescape(project_dir .. "/.nvim/nvim_lint.sh")

vim.opt.makeprg = nvim_lint_shell
vim.opt.errorformat = [[%f(%l\,%c): %t%*[^ ] %m]]

local function get_active_file_path()
  local bufnr = vim.api.nvim_get_current_buf()
  local full_path = vim.api.nvim_buf_get_name(bufnr)
  local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
  if buftype == "" and full_path ~= "" then
    return vim.fn.shellescape(full_path)
  end
  return nil
end

local augroup = vim.api.nvim_create_augroup("DynamicMakeprg", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  pattern = "*",
  group = augroup,
  callback = function()
    local file_path = get_active_file_path()
    if file_path then
      vim.opt.makeprg = nvim_lint_shell .. " " .. file_path
    else
      vim.opt.makeprg = nvim_lint_shell
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = make_on_save_augroup,
  pattern = { "*.js", "*.ts" },
  callback = make_on_save,
})

vim.g.ctags_extensions = "js ts"
