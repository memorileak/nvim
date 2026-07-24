local chat_input_template = table.concat({
  "{{{language}}}",
  "{{{tab}}}",
  "{{{external_context}}}",
  "<contextBeforeCursor>",
  "{{{context_before_cursor}}}<cursorPosition>",
  "<contextAfterCursor>",
  "{{{context_after_cursor}}}",
}, "\n")

local function external_context(context_before_cursor, context_after_cursor, opts)
  -- local filepath = "/tmp/minuet_context.txt"
  -- local file = io.open(filepath, "r")
  --
  -- if not file then
  --   return ""
  -- end
  --
  -- local content = file:read("*a")
  -- file:close()
  --
  -- if content and content:match("%S") then
  --   -- Inject glean file wrapped in XML tags before the cursor context
  --   return "<externalContext>\n" .. content .. "\n</externalContext>\n"
  -- end

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
        -- Force Prefix-First system prompt & few-shots examples
        system = mc.default_system_prefix_first,
        few_shots = mc.default_few_shots_prefix_first,
        chat_input = {
          template = chat_input_template,
          external_context = external_context,
        },
      },
      openai = {
        model = "gpt-5.4-mini",
        api_key = "OPENAI_API_KEY",
        -- Force Prefix-First system prompt & few-shots examples
        system = mc.default_system_prefix_first,
        few_shots = mc.default_few_shots_prefix_first,
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
