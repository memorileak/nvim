-- 1. Explicitly install parsers (Replaces `ensure_installed = {...}`)
require("nvim-treesitter").install({
  -- Essential Neovim system parsers
  "lua",
  "vim",
  "vimdoc",
  "query",
  "markdown",
  "markdown_inline",
  -- Default development languages
  "rust",
  "javascript",
  "typescript",
  "python",
  "html",
  "css",
  "json",
  "yaml",
  "toml",
  "bash",
  "dockerfile",
})

-- 2. Enable native syntax highlighting (Replaces `highlight = { enable = true }`)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(args)
    -- Get the filetype of the buffer that triggered the event
    local file_type = vim.bo[args.buf].filetype
    if not file_type or file_type == "" then
      return
    end
    -- Normalize the filetype to a valid Tree-sitter language name
    local lang = vim.treesitter.language.get_lang(file_type) or file_type
    -- Safely start highlighting for this specific buffer and language
    pcall(vim.treesitter.start, args.buf, lang)
  end,
})
