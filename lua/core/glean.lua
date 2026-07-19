-- Only collect certain types of nodes
local GLEANABLE_NODE_TYPES = {
  -- Rust
  struct_item = true,
  enum_item = true,
  impl_item = true,
  function_item = true,

  -- JavaScript
  -- TypeScript
  -- Python
  function_declaration = true,
  function_definition = true,
  method_declaration = true,
  class_declaration = true,
  class_definition = true,
}

-- Determine the path for the glean file based on the OS
local function get_glean_file_path()
  local is_win = vim.fn.has("win32") == 1
  local tmp_dir = is_win and os.getenv("TEMP") or "/tmp"
  return vim.fs.joinpath(tmp_dir, "nvim_glean.md")
end

-- Append payload (string) to the glean file
local function append_to_glean_file(payload)
  local out_file = get_glean_file_path()
  local f, err = io.open(out_file, "a")

  if not f then
    vim.notify(
      "Failed to open " .. out_file .. ": " .. (err or "Unknown error"),
      vim.log.levels.ERROR
    )
    return
  end

  f:write(payload)
  f:close()
end

-- Glean the current treesitter node
local function glean_node()
  local bufnr = vim.api.nvim_get_current_buf()
  local node = vim.treesitter.get_node({ bufnr = bufnr })

  if not node then
    vim.notify("No treesitter node found at cursor.", vim.log.levels.WARN)
    return nil
  end

  local target_node = node
  while target_node do
    if GLEANABLE_NODE_TYPES[target_node:type()] then
      break
    end
    target_node = target_node:parent()
  end
  target_node = target_node or node

  -- Extract necessary data
  local text = vim.treesitter.get_node_text(target_node, bufnr)

  -- Get absolute file path
  local file_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")

  -- Get filetype for markdown syntax highlighting
  local ft = vim.bo[bufnr].filetype

  -- Get node range. Note: TS ranges are 0-indexed.
  -- We add 1 to make them 1-indexed (standard editor line/col numbers).
  local start_row, start_col, end_row, end_col = target_node:range()
  local range_str =
    string.format("L%d:C%d - L%d:C%d", start_row + 1, start_col + 1, end_row + 1, end_col + 1)

  -- Construct the AI-friendly Markdown payload
  local payload = string.format(
    "### File: `%s`\n**Range:** `%s`\n```%s\n%s\n```\n\n---\n\n",
    file_path,
    range_str,
    ft,
    text
  )

  -- Append to the glean file
  append_to_glean_file(payload)

  vim.notify("Collected node: " .. target_node:type(), vim.log.levels.INFO)
end

-- Glean the current visual selection
local function glean_selection()
  -- Grab the start and end positions using getpos
  -- getpos returns { bufnum, lnum (1-indexed), col (1-indexed), off }
  local pos1 = vim.fn.getpos("'<")
  local pos2 = vim.fn.getpos("'>")

  if pos1[2] == 0 or pos2[2] == 0 then
    vim.notify("No visual selection found.", vim.log.levels.WARN)
    return
  end

  -- Use Neovim's native getregion to safely extract exactly what is highlighted
  -- We pass the current visual mode type so it handles V and <C-v> correctly
  local lines = vim.fn.getregion(pos1, pos2, { type = vim.fn.visualmode() })
  local text = table.concat(lines, "\n")

  -- Gather metadata
  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
  local ft = vim.bo[bufnr].filetype
  local range_str = string.format("L%d:C%d - L%d:C%d", pos1[2], pos1[3], pos2[2], pos2[3])

  -- Construct the AI-friendly Markdown payload
  -- Because getpos returns 1-indexed values natively, we don't need to add + 1
  local payload = string.format(
    "### File: `%s`\n**Range:** `%s`\n```%s\n%s\n```\n\n---\n\n",
    file_path,
    range_str,
    ft,
    text
  )

  -- Append to the glean file
  append_to_glean_file(payload)

  vim.notify("Collected visual selection.", vim.log.levels.INFO)
end

-- Trigger esc to exit visual mode and then glean the selection
local function exit_visual_mode_and_glean_selection()
  -- Force Neovim to exit visual mode synchronously to update the '< and '> marks
  local esc = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "x", false)
  -- Now glean the selection after exiting visual mode
  glean_selection()
end

-- Open the glean file
local function open_glean_file()
  local out_file = get_glean_file_path()
  vim.cmd("edit " .. vim.fn.fnameescape(out_file))
end

-- Empty the glean file
local function clear_glean_file()
  local out_file = get_glean_file_path()
  local f, err = io.open(out_file, "w")
  if not f then
    vim.notify(
      "Failed to open " .. out_file .. ": " .. (err or "Unknown error"),
      vim.log.levels.ERROR
    )
    return
  end
  f:close()
  vim.notify("Cleared glean file: " .. out_file, vim.log.levels.INFO)
end

-- Command and keymap setup
local help_message = [[Glean: use 'open' to open the glean file or 'clear' to empty it]]

local actions = {
  open = open_glean_file,
  clear = clear_glean_file,
}

vim.api.nvim_create_user_command("Glean", function(opts)
  local action = opts.fargs[1]

  if not action then
    print(help_message)
    return
  end

  action = action:lower()

  if not actions[action] then
    print(help_message)
    return
  end

  actions[action]()
end, {
  nargs = "?",
  complete = function(arglead, _, _)
    local options = { "clear", "open" }
    return vim.tbl_filter(function(opt)
      return vim.startswith(opt, arglead)
    end, options)
  end,
  desc = help_message,
})

vim.keymap.set("n", "gl", glean_node, {
  desc = "Collect treesitter node to the glean file",
  noremap = true,
  silent = true,
})

vim.keymap.set("v", "gl", exit_visual_mode_and_glean_selection, {
  desc = "Collect selected text to the glean file",
  noremap = true,
  silent = true,
})

vim.keymap.set("n", "<leader>glc", clear_glean_file, {
  desc = "Clear the glean file",
  noremap = true,
  silent = true,
})

vim.keymap.set("n", "<leader>glo", "<cmd>vsplit | Glean open<CR>", {
  desc = "Open the glean file in vertical split",
  noremap = true,
  silent = true,
})

vim.keymap.set("n", "<leader>glO", "<cmd>split | Glean open<CR>", {
  desc = "Open the glean file in horizontal split",
  noremap = true,
  silent = true,
})
