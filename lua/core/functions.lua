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

-- The symbol to remove key in merge_tables
local none = vim.NIL

local islist = vim.islist or vim.tbl_islist

-- Merge two tables recursively.
-- Keep values from tbl1 when there is a conflict.
local function merge_tables(tbl1, tbl2)
  local is_dict1 = type(tbl1) == "table" and (not islist(tbl1) or vim.tbl_isempty(tbl1))
  local is_dict2 = type(tbl2) == "table" and (not islist(tbl2) or vim.tbl_isempty(tbl2))
  if is_dict1 and is_dict2 then
    local new_tbl = {}
    for k, v in pairs(tbl2) do
      if tbl1[k] ~= none then
        new_tbl[k] = merge_tables(tbl1[k], v)
      end
    end
    for k, v in pairs(tbl1) do
      if tbl2[k] == nil then
        if v ~= none then
          new_tbl[k] = merge_tables(v, {})
        else
          new_tbl[k] = nil
        end
      end
    end
    return new_tbl
  end

  if tbl1 == none then
    return nil
  elseif tbl1 == nil then
    return merge_tables(tbl2, {})
  else
    return tbl1
  end
end

-- Module table
local M = {}

M.get_visual_selection = get_visual_selection
M.none = none
M.merge_tables = merge_tables

return M
