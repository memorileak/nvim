local glean = require("core/glean")
local extract_gleanable_node_at_cursor = glean.extract_gleanable_node_at_cursor
local extract_visual_selection = glean.extract_visual_selection

-- Helper function to find or create the unnamed context buffer
local function get_and_open_unnamed_context_buf(create_if_missing)
  local target_buf = nil

  -- 1. Find the first buffer that has no name and an empty buftype
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    if name == "" and buftype == "" and vim.api.nvim_buf_is_loaded(bufnr) then
      target_buf = bufnr
      break
    end
  end

  -- 2. If the buffer already exists, ensure it is visible
  if target_buf then
    -- Check if the buffer is displayed in any window across all tabs
    local win_ids = vim.fn.win_findbuf(target_buf)
    if #win_ids == 0 then
      -- It is hidden. Open it in a new tab at the end, then switch back.
      local current_tab = vim.api.nvim_get_current_tabpage()
      -- '$tab sb <bufnr>' opens the specific buffer in a new tab at the far right
      vim.cmd("$tab sb " .. target_buf)
      -- Return focus to the original tab (the picking window)
      vim.api.nvim_set_current_tabpage(current_tab)
    end
    return target_buf
  end

  -- 3. If none exists and we requested creation, create a new tab at the end
  if create_if_missing then
    -- Save the current tabpage so we can jump back immediately
    local current_tab = vim.api.nvim_get_current_tabpage()
    -- Command `$tabnew` creates a new tab at the far right with a new unnamed buffer
    vim.cmd("$tabnew")
    local new_buf = vim.api.nvim_get_current_buf()
    -- Switch focus back to the original tab so your cursor never leaves your active file
    vim.api.nvim_set_current_tabpage(current_tab)
    return new_buf
  end

  return nil
end

-- Collect extracted (node or selection) lines and append them to the unnamed context buffer
local function collect_to_context_buf(extracted)
  local lines = vim.split(extracted.text, "\n", { plain = true })
  local header = string.format(
    "// Source: %s (Lines: %d-%d)",
    extracted.rel_file_path,
    extracted.line_start,
    extracted.line_end
  )

  -- Prepend the header
  table.insert(lines, 1, header)

  -- Get or create the unnamed buffer (using the function from the previous step)
  local ctx_buf = get_and_open_unnamed_context_buf(true)

  -- Append the formatted lines safely to the bottom of the buffer
  local line_count = vim.api.nvim_buf_line_count(ctx_buf)
  local last_line = vim.api.nvim_buf_get_lines(ctx_buf, line_count - 1, line_count, false)[1]

  local insert_idx = line_count
  if line_count == 1 and last_line == "" then
    insert_idx = 0
  else
    -- Append a blank line for separation
    table.insert(lines, "")
  end

  vim.api.nvim_buf_set_lines(ctx_buf, insert_idx, insert_idx, false, lines)
end

-- Collect the gleanable node at the cursor and append it to the unnamed context buffer
local function collect_node_at_cursor()
  local extracted = extract_gleanable_node_at_cursor()
  local type = extracted.type
  local line_start = extracted.line_start
  local line_end = extracted.line_end
  local col_start = extracted.col_start
  local col_end = extracted.col_end
  local range_str = string.format("L%d:C%d - L%d:C%d", line_start, col_start, line_end, col_end)
  collect_to_context_buf(extracted)
  vim.notify("Collected node: " .. type .. " (" .. range_str .. ") to buffer", vim.log.levels.INFO)
end

-- Trigger esc to exit visual mode and then glean the selection
local function exit_visual_mode_and_collect_selection()
  local esc = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "x", false)
  local extracted = extract_visual_selection()
  local line_start = extracted.line_start
  local line_end = extracted.line_end
  local col_start = extracted.col_start
  local col_end = extracted.col_end
  local range_str = string.format("L%d:C%d - L%d:C%d", line_start, col_start, line_end, col_end)
  collect_to_context_buf(extract_visual_selection())
  vim.notify("Collected visual selection (" .. range_str .. ") to buffer", vim.log.levels.INFO)
end

-- Keymap setup
vim.keymap.set("n", "gL", collect_node_at_cursor, {
  desc = "Collect treesitter node to the context buffer",
  noremap = true,
  silent = true,
})

vim.keymap.set("x", "gL", exit_visual_mode_and_collect_selection, {
  desc = "Collect selected text to the context buffer",
  noremap = true,
  silent = true,
})

-- Setup for minuet chat input template with external context injection
local prompt = [[
You are an AI code completion engine. Provide contextually appropriate completions:
- Code completions in code context
- Comment/documentation text in comments
- String content in string literals
- Prose in markdown/documentation files

Input markers:
- <externalContext>: Read-only reference code gleaned from other project files (classes, methods, type definitions)
- <contextBeforeCursor>: Context before cursor
- <cursorPosition>: Current cursor location
- <contextAfterCursor>: Context after cursor
]]

local guidelines = [[
Guidelines:
1. Offer completions after the <cursorPosition> marker.
2. Use <externalContext> strictly as reference material to infer available methods, class structures, function arguments, and types.
3. NEVER generate code inside <externalContext> or repeat/copy large blocks from it unless directly calling those methods/types.
4. Make sure you have maintained the user's existing whitespace and indentation at <cursorPosition>. This is REALLY IMPORTANT!
5. Provide multiple completion options when possible.
6. Return completions separated by the marker <endCompletion>.
7. The returned message will be further parsed and processed. DO NOT include additional comments or markdown code block fences. Return the result directly.
8. Keep each completion option concise, limiting it to a single line or a few lines.
9. Create entirely new code completion that DO NOT REPEAT OR COPY any user's existing code around <cursorPosition>.
]]

local few_shots_prefix_first_with_external = {
  {
    role = "user",
    content = [[
# language: javascript
<externalContext>
// Source: src/utils/string_formatter.js (Lines: 1-4)
class StringFormatter {
    static formatUpper(str) { return str.toUpperCase(); }
    static removeWhitespace(str) { return str.replace(/\s+/g, ''); }
}
</externalContext>
<contextBeforeCursor>
function transformData(data, options) {
    const result = [];
    for (let item of data) {
        // Transform each item based on options using StringFormatter
        <cursorPosition>
<contextAfterCursor>
    return result;
}

const processedData = transformData(rawData, {
    uppercase: true,
    removeSpaces: false
});]],
  },
  {
    role = "assistant",
    content = [[
let processed = item;
        if (options.uppercase) {
            processed = StringFormatter.formatUpper(processed);
        }
        if (options.removeSpaces) {
            processed = StringFormatter.removeWhitespace(processed);
        }
        result.push(processed);
    }
<endCompletion>
if (typeof item === 'string') {
            let processed = item;
            if (options.uppercase) {
                processed = StringFormatter.formatUpper(processed);
            }
            if (options.removeSpaces) {
                processed = StringFormatter.removeWhitespace(processed);
            }
            result.push(processed);
        } else {
            result.push(item);
        }
    }
<endCompletion>
]],
  },
}

local chat_input_template = table.concat({
  "{{{language}}}",
  "{{{tab}}}",
  "<externalContext>",
  "{{{external_context}}}",
  "</externalContext>",
  "<contextBeforeCursor>",
  "{{{context_before_cursor}}}<cursorPosition>",
  "<contextAfterCursor>",
  "{{{context_after_cursor}}}",
}, "\n")

local function external_context(context_before_cursor, context_after_cursor, opts)
  local ctx_buf = get_and_open_unnamed_context_buf(false)
  if not ctx_buf then
    return ""
  end

  -- Read all lines from the buffer
  local lines = vim.api.nvim_buf_get_lines(ctx_buf, 0, -1, false)
  local content = table.concat(lines, "\n")

  -- If the buffer has text, wrap it in XML tags for the AI
  if content and content:match("%S") then
    return content
  end

  return ""
end

local function setup_minuet()
  local minuet = require("minuet")
  local mc = require("minuet.config")

  minuet.setup({
    cmp = {
      enable_auto_complete = false,
    },
    provider = "claude",
    provider_options = {
      claude = {
        model = "claude-haiku-4-5",
        api_key = "ANTHROPIC_API_KEY",
        system = {
          template = mc.default_system_prefix_first.template,
          prompt = prompt,
          guidelines = guidelines,
        },
        few_shots = few_shots_prefix_first_with_external,
        chat_input = {
          template = chat_input_template,
          external_context = external_context,
        },
      },
      openai = {
        model = "gpt-5.4-mini",
        api_key = "OPENAI_API_KEY",
        system = {
          template = mc.default_system_prefix_first.template,
          prompt = prompt,
          guidelines = guidelines,
        },
        few_shots = few_shots_prefix_first_with_external,
        chat_input = {
          template = chat_input_template,
          external_context = external_context,
        },
      },
    },
  })
end

local M = {}

M.setup_minuet = setup_minuet

return M
