-- Only collect certain types of nodes
local GLEANABLE_NODE_TYPES = {}

-- Rust
GLEANABLE_NODE_TYPES.rust = {
  const_item = true,
  static_item = true,
  type_item = true,
  mod_item = true,
  macro_definition = true,
  function_item = true,
  struct_item = true,
  field_declaration = true,
  enum_item = true,
  enum_variant = true,
  trait_item = true,
  associated_type = true,
  function_signature_item = true,
  impl_item = true,
}

-- JavaScript
GLEANABLE_NODE_TYPES.javascript = {
  lexical_declaration = true,
  variable_declaration = true,
  function_declaration = true,
  function_expression = true,
  arrow_function = true,
  generator_function_declaration = true,
  generator_function = true,
  ["class"] = true,
  class_declaration = true,
  field_definition = true,
  method_definition = true,
}

-- JavaScript React (JSX)
GLEANABLE_NODE_TYPES.javascriptreact = vim.tbl_extend("force", GLEANABLE_NODE_TYPES.javascript, {
  jsx_element = true,
})

-- TypeScript
GLEANABLE_NODE_TYPES.typescript = vim.tbl_extend("force", GLEANABLE_NODE_TYPES.javascript, {
  public_field_definition = true,
  abstract_class_declaration = true,
  abstract_method_signature = true,
  interface_declaration = true,
  property_signature = true,
  method_signature = true,
  type_alias_declaration = true,
  enum_declaration = true,
  module = true,
  internal_module = true,
  ambient_declaration = true,
})

-- TypeScript React (TSX)
GLEANABLE_NODE_TYPES.typescriptreact = vim.tbl_extend("force", GLEANABLE_NODE_TYPES.typescript, {
  jsx_element = true,
})

-- Python
GLEANABLE_NODE_TYPES.python = {
  expression_statement = true,
  type_alias_statement = true,
  function_definition = true,
  decorated_definition = true,
  class_definition = true,
  assignment = true,
}

-- Angular html
GLEANABLE_NODE_TYPES.htmlangular = {
  element = true,
  let_statement = true,
  switch_statement = true,
  case_statement = true,
  default_statement = true,
  if_statement = true,
  else_if_statement = true,
  else_statement = true,
  for_statement = true,
  empty_statement = true,
  defer_statement = true,
  placeholder_statement = true,
  error_statement = true,
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

-- Find the nearest gleanable parent node based on the filetype
local function get_nearest_gleanable_parent(filetype, node)
  local target_node = node
  while target_node do
    if GLEANABLE_NODE_TYPES[filetype] and GLEANABLE_NODE_TYPES[filetype][target_node:type()] then
      return target_node
    end
    target_node = target_node:parent()
  end
  return nil
end

-- Glean the current treesitter node
local function glean_node()
  local bufnr = vim.api.nvim_get_current_buf()
  local node = vim.treesitter.get_node({ bufnr = bufnr })

  if not node then
    vim.notify("No treesitter node found at cursor", vim.log.levels.WARN)
    return nil
  end

  -- Get filetype of the current buffer
  local ft = vim.bo[bufnr].filetype

  -- Find the nearest gleanable parent node, or use the current node if none found
  local target_node = get_nearest_gleanable_parent(ft, node) or node

  -- Extract necessary data
  local text = vim.treesitter.get_node_text(target_node, bufnr)

  -- Get absolute file path
  local file_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")

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

  vim.notify(
    "Collected node: " .. target_node:type() .. " (" .. range_str .. ")",
    vim.log.levels.INFO
  )
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

  vim.notify("Collected visual selection (" .. range_str .. ")", vim.log.levels.INFO)
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

-- Visually select the nearest gleanable node under the cursor
local function select_nearest_gleanable_node()
  local bufnr = vim.api.nvim_get_current_buf()
  local node = vim.treesitter.get_node({ bufnr = bufnr })

  if not node then
    vim.notify("No treesitter node found at cursor", vim.log.levels.WARN)
    return
  end

  local ft = vim.bo[bufnr].filetype
  local target_node = get_nearest_gleanable_parent(ft, node) or node
  local start_row, start_col, end_row, end_col = target_node:range()

  -- Adjust end position (Tree-sitter's end_col is exclusive)
  if end_col == 0 then
    -- If the node ends exactly at the start of a new line,
    -- the actual last character is at the end of the previous line.
    end_row = end_row - 1
    local prev_line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1]
    end_col = prev_line and #prev_line or 0
  else
    -- Otherwise, just step one character back to make it inclusive for visual mode
    end_col = end_col - 1
  end

  -- Handle modes properly
  -- We ONLY send <Esc> to clear the selection if we are already in visual mode ('x' map).
  -- If we are in operator-pending mode ('o' map, like typing 'dan'), sending <Esc>
  -- would abort the operator!
  local mode = vim.api.nvim_get_mode().mode
  if mode:match("^[vV\22]") then
    vim.cmd("normal! \27") -- \27 is the keycode for <Esc>
  end

  -- Execute the selection
  -- nvim_win_set_cursor expects { 1-indexed row, 0-indexed column }
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
end

-- Glean inspection mode: highlights the nearest gleanable node under the cursor
local inspect_enabled = false
local debounce_timer = nil
local glean_inspection_nsid = vim.api.nvim_create_namespace("glean_inspect_highlight")
local glean_inspection_augroup = vim.api.nvim_create_augroup("GleanInspection", { clear = true })

local function clear_inspection_highlight(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, glean_inspection_nsid, 0, -1)
end

local function apply_inspection_highlight(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Clear any existing highlights first
  clear_inspection_highlight(bufnr)

  local node = vim.treesitter.get_node({ bufnr = bufnr })
  if not node then
    return
  end

  local filetype = vim.bo[bufnr].filetype
  local target_node = get_nearest_gleanable_parent(filetype, node) or node
  local start_row, start_col, end_row, end_col = target_node:range()

  vim.hl.range(bufnr, glean_inspection_nsid, "QuickFixLine", {
    start_row,
    start_col,
  }, {
    end_row,
    end_col,
  })
end

local function toggle_glean_inspection()
  inspect_enabled = not inspect_enabled
  local bufnr = vim.api.nvim_get_current_buf()
  if inspect_enabled then
    apply_inspection_highlight(bufnr)
    vim.notify("Glean inspection enabled", vim.log.levels.INFO)
  else
    clear_inspection_highlight(bufnr)
    vim.notify("Glean inspection disabled", vim.log.levels.INFO)
  end
end

local function stop_and_clear_debounce_timer()
  if debounce_timer then
    debounce_timer:stop()
    debounce_timer:close()
    debounce_timer = nil
  end
end

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  group = glean_inspection_augroup,
  callback = function()
    if not inspect_enabled then
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()

    stop_and_clear_debounce_timer()
    debounce_timer = vim.defer_fn(function()
      debounce_timer = nil
      if inspect_enabled then
        apply_inspection_highlight(bufnr)
      end
    end, 100)
  end,
})

vim.api.nvim_create_autocmd({ "BufLeave" }, {
  group = glean_inspection_augroup,
  callback = function(args)
    clear_inspection_highlight(args.buf)
  end,
})

-- Command and keymap setup
local help_message =
  [[Glean: use 'open' to open the glean file, 'clear' to empty it, or 'inspect' to toggle inspection mode]]

local actions = {
  open = open_glean_file,
  clear = clear_glean_file,
  inspect = toggle_glean_inspection,
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
    local options = { "clear", "inspect", "open" }
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

vim.keymap.set("x", "gl", exit_visual_mode_and_glean_selection, {
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

vim.keymap.set("n", "<leader>gli", toggle_glean_inspection, {
  desc = "Toggle Glean inspection mode",
  noremap = true,
  silent = true,
})

-- Create the text object mapping for Visual ('x') and Operator-Pending ('o') modes.
vim.keymap.set(
  { "x", "o" },
  "an",
  select_nearest_gleanable_node,
  { desc = "Select around nearest gleanable node" }
)
