local qf_group = vim.api.nvim_create_augroup("QFHighlight", { clear = true })
local ns_id = vim.api.nvim_create_namespace("qf_buffer_highlights")

-- HashMap to store our parsed quickfix items: qf_cache[bufnr][lnum] = { items... }
local qf_cache = {}
local last_qf_id = -1

-- Function to determine the highlight group based on the quickfix type (severity)
local function get_hl_group(qf_type)
  local t = string.upper(qf_type or "")
  if t == "W" then
    return "DiagnosticUnderlineWarn"
  end
  if t == "I" then
    return "DiagnosticUnderlineInfo"
  end
  if t == "H" then
    return "DiagnosticUnderlineHint"
  end
  return "DiagnosticUnderlineError" -- Default fallback
end

-- Core optimization: Only parse the Quickfix list if it has changed
local function update_qf_cache()
  -- Fetch just the ID first to check if the list has changed (O(1) operation)
  local qf_info = vim.fn.getqflist({ id = 0, items = 0 })
  if qf_info.id == last_qf_id then
    return
  end -- Cache is still valid

  -- The list changed. Update the ID and rebuild the HashMap.
  last_qf_id = qf_info.id
  qf_cache = {}

  for _, item in ipairs(qf_info.items) do
    if item.valid == 1 and item.bufnr ~= 0 then
      -- Initialize nested tables if they don't exist
      qf_cache[item.bufnr] = qf_cache[item.bufnr] or {}
      qf_cache[item.bufnr][item.lnum] = qf_cache[item.bufnr][item.lnum] or {}

      local start_col = math.max(0, item.col - 1)
      local end_col = start_col + 3
      if item.end_col and item.end_col > 0 then
        end_col = item.end_col - 1
      end

      -- Insert into our O(1) lookup table
      table.insert(qf_cache[item.bufnr][item.lnum], {
        start_col = start_col,
        end_col = end_col,
        text = item.text:gsub("^%s*", ""),
        lnum = item.lnum,
        col = item.col,
        type = item.type,
      })
    end
  end
end

-- Apply highlights from the cache to the given buffer
local function apply_highlights(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  if not qf_cache[bufnr] then
    return
  end

  for lnum, items in pairs(qf_cache[bufnr]) do
    for _, item in ipairs(items) do
      if lnum > 0 then
        vim.api.nvim_buf_add_highlight(
          bufnr,
          ns_id,
          get_hl_group(item.type),
          lnum - 1,
          item.start_col,
          item.end_col
        )
      end
    end
  end
end

-- Show the quickfix message in a pop-up (O(1) lookup)
local function show_qf_popup()
  update_qf_cache() -- Ensure cache is fresh

  local bufnr = vim.api.nvim_get_current_buf()
  if not qf_cache[bufnr] then
    return
  end -- No errors in this buffer

  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor_pos[1]
  local cursor_col = cursor_pos[2]

  -- O(1) direct lookup for items on this specific line
  local items_on_line = qf_cache[bufnr][cursor_line]
  if not items_on_line then
    return
  end

  local messages = {}
  for _, item in ipairs(items_on_line) do
    if cursor_col >= item.start_col and cursor_col < item.end_col then
      table.insert(messages, string.format("[%d:%d] %s", item.lnum, item.col, item.text))
    end
  end

  -- Display the float pop-up only if matching messages exist
  if #messages > 0 then
    local popup_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, messages)

    -- 1. Calculate dynamic width and wrapped height
    local max_width = 80
    local max_msg_width = 0
    for _, msg in ipairs(messages) do
      local w = vim.api.nvim_strwidth(msg)
      if w > max_msg_width then
        max_msg_width = w
      end
    end

    local win_width = math.max(40, math.min(max_width, max_msg_width))

    local total_height = 0
    for _, msg in ipairs(messages) do
      total_height = total_height + math.max(1, math.ceil(vim.api.nvim_strwidth(msg) / win_width))
    end

    local opts = {
      relative = "cursor",
      row = 1,
      col = 0,
      width = win_width,
      height = total_height, -- Use the new dynamic height
      style = "minimal",
      border = "rounded",
    }

    local win = vim.api.nvim_open_win(popup_buf, false, opts)

    -- 2. Explicitly enable text wrapping in the floating window
    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
      buffer = bufnr,
      once = true,
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end,
    })
  end
end

local function silent_make()
  vim.cmd("silent! make!")

  -- Get the quickfix list items count after the make command
  local qf_info = vim.fn.getqflist({ size = 0 })
  local count = qf_info.size or 0

  -- Send notification based on the count
  if count > 0 then
    vim.notify(
      string.format("Make finished, %d items added to quickfix", count),
      vim.log.levels.INFO
    )
  else
    vim.notify("Make finished, no items added to quickfix", vim.log.levels.INFO)
  end
end

-- Send buffer-local quickfix items to a location list
local function buffer_qf_to_loclist()
  local bufnr = vim.api.nvim_get_current_buf()
  local qf_list = vim.fn.getqflist()
  local loc_list = {}

  -- Filter items that only belong to the current buffer
  for _, item in ipairs(qf_list) do
    if item.bufnr == bufnr then
      table.insert(loc_list, item)
    end
  end

  -- Set the location list for the current window (0) and replace ('r') any existing list
  vim.fn.setloclist(0, loc_list, "r")

  -- Open the location list window if there are items
  if #loc_list > 0 then
    vim.cmd("lopen")
    -- vim.api.nvim_echo({
    --   { string.format("Loaded %d items into location list", #loc_list), "Normal" },
    -- }, false, {})
  else
    vim.notify("No quickfix items for the current buffer", vim.log.levels.WARN)
  end
end

-- Automatically update cache and highlight on buffer enter OR after a :make command
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "QuickFixCmdPost" }, {
  group = qf_group,
  callback = function()
    update_qf_cache()
    apply_highlights(vim.api.nvim_get_current_buf())
  end,
})

-- Press mk to run :make silently and update the quickfix list without opening it
vim.keymap.set("n", "mk", silent_make, {
  desc = "Run make silently",
  noremap = true,
})

-- Press ml to load the buffer's quickfix items into the location list
vim.keymap.set("n", "ml", buffer_qf_to_loclist, {
  desc = "Load buffer QF items to LocList",
  noremap = true,
})

-- Navigate through diagnostics in the location list using ]d and [d
vim.keymap.set("n", "]d", "<cmd>lnext<CR>", {
  desc = "Go to next diagnostic in location list",
  noremap = true,
  silent = true,
})

vim.keymap.set("n", "[d", "<cmd>lprev<CR>", {
  desc = "Go to previous diagnostic in location list",
  noremap = true,
  silent = true,
})

-- Press <leader>d to open the diagnostic message in a floating window
vim.keymap.set("n", "<leader>d", show_qf_popup, {
  desc = "Show precise quickfix message in popup",
  noremap = true,
  silent = true,
})
