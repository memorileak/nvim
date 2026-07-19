local function get_visual_selection()
  -- 1. Exit visual mode to lock in the current selection to the '< and '> marks
  vim.cmd("normal! \27")

  -- 2. Get the start and end positions of that locked selection
  local pos1 = vim.fn.getpos("'<")
  local pos2 = vim.fn.getpos("'>")

  -- 3. Get the type of the selection (character 'v', line 'V', or block '^V')
  local mode = vim.fn.visualmode()

  -- 4. Extract the raw strings directly from the buffer
  local lines = vim.fn.getregion(pos1, pos2, { type = mode })

  -- 5. Rejoin the table of lines into a single string
  return table.concat(lines, "\n")
end

-- Module table
local M = {}

M.get_visual_selection = get_visual_selection

return M
