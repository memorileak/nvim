local qf_group = vim.api.nvim_create_augroup("QFHighlight", { clear = true })

local qf_ns_id = vim.api.nvim_create_namespace("qf_buffer_highlights")
local ll_ns_id = vim.api.nvim_create_namespace("ll_buffer_highlights")

-- HashMap to store our parsed quickfix items: qf_cache[bufnr][lnum] = { items... }
local qf_cache = {}
local last_qf_id = -1

-- Track the currently running make job to allow cancellation
local active_make_job = nil

-- Function to determine the highlight group based on the quickfix type (severity)
local function get_hl_group(qf_type)
  local t = string.upper(qf_type or "")
  if t == "E" then
    return "DiagnosticUnderlineError"
  end
  if t == "W" then
    return "DiagnosticUnderlineWarn"
  end
  if t == "I" then
    return "DiagnosticUnderlineInfo"
  end
  if t == "H" then
    return "DiagnosticUnderlineHint"
  end
  return "DiagnosticUnderlineHighlight" -- Default fallback
end

-- Compute highlight range from a quickfix/location-list item.
-- Returns 0-based, end-exclusive columns for nvim_buf_add_highlight.
local function compute_item_range(bufnr, item)
  -- Quickfix/location-list columns are 1-based; highlights use 0-based columns.
  local start_col = math.max(0, (tonumber(item.col) or 1) - 1)

  if item.end_col and item.end_col > 0 then
    -- Prefer explicit ranges from the producer when available.
    local explicit_end = item.end_col - 1
    return start_col, math.max(start_col + 1, explicit_end)
  end

  -- No explicit end column: derive a fallback span from the source line.
  local lnum = tonumber(item.lnum) or 1
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  local line_len = #line

  if line_len == 0 then
    -- Empty lines still need a non-zero width range to keep downstream logic safe.
    return 0, 1
  end

  -- Clamp scan position to the line so out-of-range cols don't error.
  local scan_col = math.min(start_col, line_len - 1)
  local ch = line:sub(scan_col + 1, scan_col + 1)

  -- Use Vim keyword semantics so fallback matches <cword> behavior.
  if vim.fn.match(ch, [[\k]]) == 0 then
    local match = vim.fn.matchstrpos(line, [[\k\+]], scan_col)
    local mstart = tonumber(match[2]) or -1
    local mend = tonumber(match[3]) or -1
    if mstart == scan_col and mend > mstart then
      -- matchstrpos returns byte indexes; mend is already end-exclusive.
      return mstart, mend
    end
  end

  -- If point is not on a keyword char, highlight exactly one character.
  return scan_col, scan_col + 1
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

      local start_col, end_col = compute_item_range(item.bufnr, item)

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

-- Get the location list items of the window that is displaying a specific buffer.
local function get_buf_win_ll_items(bufnr)
  local win_id = vim.fn.bufwinid(bufnr)
  if win_id == -1 then
    return nil -- Buffer is not displayed in any window
  end

  local items = {}
  local loc_list_items = vim.fn.getloclist(win_id, { items = 0 })

  for _, item in ipairs(loc_list_items.items) do
    if item.valid == 1 then
      local start_col, end_col = compute_item_range(bufnr, item)

      table.insert(items, {
        start_col = start_col,
        end_col = end_col,
        text = item.text:gsub("^%s*", ""),
        lnum = item.lnum,
        col = item.col,
        type = item.type,
      })
    end
  end

  return items
end

-- Apply highlights from the qf cache to the given buffer
local function apply_qf_highlights(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, qf_ns_id, 0, -1)

  if not qf_cache[bufnr] then
    return
  end

  for lnum, items in pairs(qf_cache[bufnr]) do
    for _, item in ipairs(items) do
      if lnum > 0 then
        vim.api.nvim_buf_add_highlight(
          bufnr,
          qf_ns_id,
          get_hl_group(item.type),
          lnum - 1,
          item.start_col,
          item.end_col
        )
      end
    end
  end
end

-- Apply highlights from the location list items to the given buffer
local function apply_ll_highlights(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ll_ns_id, 0, -1)

  local ll_items = get_buf_win_ll_items(bufnr)
  if not ll_items then
    return
  end

  for _, item in ipairs(ll_items or {}) do
    if item.lnum > 0 then
      vim.api.nvim_buf_add_highlight(
        bufnr,
        ll_ns_id,
        "DiagnosticHighlight",
        item.lnum - 1,
        item.start_col,
        item.end_col
      )
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

local function trigger_make()
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

local function collect_buf_qf_items(bufnr)
  local qf_list = vim.fn.getqflist()
  local loc_list = {}

  -- Filter items that only belong to the specified buffer
  for _, item in ipairs(qf_list) do
    if item.bufnr == bufnr then
      table.insert(loc_list, item)
    end
  end

  return loc_list
end

-- Send buffer-local quickfix items to a location list
local function buffer_qf_to_loclist()
  local bufnr = vim.api.nvim_get_current_buf()
  local loc_list = collect_buf_qf_items(bufnr)

  -- Set the location list for the current window (0) and replace ('r') any existing list
  vim.fn.setloclist(0, loc_list, "r")

  -- Open the location list window if there are items
  if #loc_list > 0 then
    vim.cmd("lopen | wincmd p") -- Open location list and return to previous window
    -- vim.api.nvim_echo({
    --   { string.format("Loaded %d items into location list", #loc_list), "Normal" },
    -- }, false, {})
  else
    vim.notify("No quickfix items for the current buffer", vim.log.levels.WARN)
  end
end

-- Asynchronously run the make command and populate quickfix/location lists
local function async_auto_make()
  -- Capture the current buffer number immediately to prevent race conditions.
  -- If the user switches buffers during compilation, we still highlight the correct buffer.
  local bufnr = vim.api.nvim_get_current_buf()
  local buf_type = vim.api.nvim_buf_get_option(bufnr, "buftype")

  -- Only run make for actual file buffers (not special buffers like quickfix, help, etc.)
  if buf_type ~= "" then
    return
  end

  -- Cancel any previously running make job to avoid redundant compilation.
  -- This prevents overlapping jobs when files are saved rapidly.
  if active_make_job then
    vim.fn.jobstop(active_make_job)
    active_make_job = nil
  end

  -- Expand makeprg to resolve placeholders like % (current file)
  local makeprg = vim.fn.expandcmd(vim.o.makeprg)

  -- Determine if we need shell wrapping for the command.
  -- Shell wrapping is required when makeprg contains shell metacharacters like:
  -- pipes (|), redirections (>, >>), command chaining (&&, ||, ;), etc.
  local needs_shell = makeprg:match("[|><;&]")

  -- Simple and robust: always use shell
  local cmd = { vim.o.shell, vim.o.shellcmdflag, makeprg }

  -- Accumulate all output lines from stdout and stderr
  local output = {}

  -- Start the asynchronous job
  active_make_job = vim.fn.jobstart(cmd, {
    -- Buffer stdout: wait for all output before calling on_stdout.
    -- This is essential because we need the complete compiler output to parse
    -- with errorformat and populate the quickfix list correctly.
    stdout_buffered = true,

    -- Buffer stderr: most compilers write errors to stderr, so capture it too.
    stderr_buffered = true,

    -- Collect stdout data (called once when job completes due to buffering)
    on_stdout = function(_, data)
      vim.list_extend(output, data)
    end,

    -- Collect stderr data (called once when job completes due to buffering)
    on_stderr = function(_, data)
      vim.list_extend(output, data)
    end,

    -- Process the results when the job completes
    on_exit = function(_, exit_code)
      -- vim.schedule() is REQUIRED: all Neovim API calls must happen on the main thread.
      -- Job callbacks run on a separate thread, so we must schedule API work.
      vim.schedule(function()
        -- Clear the active job tracker since this job has completed
        active_make_job = nil

        -- Check if the original buffer is still valid.
        -- The user might have closed the buffer during compilation.
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end

        -- Filter out empty strings that vim.fn.jobstart callbacks may include
        output = vim.tbl_filter(function(line)
          return line ~= ""
        end, output)

        -- Populate the quickfix list by parsing the output using errorformat.
        -- The 'efm' option tells Vim how to parse compiler errors into structured items.
        vim.fn.setqflist({}, " ", {
          title = "make",
          lines = output,
          efm = vim.o.errorformat,
        })

        -- Update the quickfix cache to reflect the new items
        update_qf_cache()

        -- Check how many items were added to the quickfix list
        local qf_info = vim.fn.getqflist({ size = 0 })
        local count = qf_info.size or 0

        if count > 0 then
          -- Filter quickfix items to only those belonging to the current buffer
          local loc_list = collect_buf_qf_items(bufnr)

          -- Update the location list for this window with buffer-specific errors
          vim.fn.setloclist(0, loc_list, "r")

          -- Apply visual highlights to the buffer for both quickfix and location list items
          apply_qf_highlights(bufnr)
          apply_ll_highlights(bufnr)
        end
      end)
    end,
  })

  -- If jobstart failed (returns -1 or 0), clear the tracker and notify the user
  if active_make_job <= 0 then
    active_make_job = nil
    vim.notify("Failed to start make command: " .. makeprg, vim.log.levels.ERROR)
  end
end

-- Automatically update cache and highlight on buffer enter OR after a :make command
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "QuickFixCmdPost" }, {
  group = qf_group,
  callback = function()
    update_qf_cache()
    local bufnr = vim.api.nvim_get_current_buf()
    -- If current buffer is a file buffer, apply highlights
    local buf_type = vim.api.nvim_buf_get_option(bufnr, "buftype")
    if buf_type == "" then
      apply_qf_highlights(bufnr)
      apply_ll_highlights(bufnr)
    end
  end,
})

make_on_save_augroup = vim.api.nvim_create_augroup("MakeOnSave", { clear = true })

local debounce_timer = nil

function make_on_save()
  -- If a timer is already running, stop it
  if debounce_timer then
    debounce_timer:stop()
    debounce_timer:close()
    debounce_timer = nil
  end
  -- Start a new timer (300 milliseconds delay)
  debounce_timer = vim.defer_fn(function()
    debounce_timer = nil
    async_auto_make()
  end, 300)
end

-- To use make on save, put this code to .nvim.lua:
-- vim.api.nvim_create_autocmd("BufWritePost", {
--   group = make_on_save_augroup,
--   pattern = "*" or { "*.c", "*.cpp", "*.rs" }, -- Add your desired file patterns here
--   callback = make_on_save,
-- })

-- Press mk to run :make silently and update the quickfix list without opening it
vim.keymap.set("n", "mk", trigger_make, {
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
