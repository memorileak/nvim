-- Set up nvim-cmp.
local cmp = require("cmp")

local function cmp_mapping_minuet()
  return cmp.mapping.complete({
    config = {
      sources = cmp.config.sources({
        { name = "minuet" },
      }),
    },
  })
end

cmp.setup({
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-l>"] = cmp_mapping_minuet(),
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    -- Hit Enter to accept currently selected item.
    -- select = false means hitting Enter will only insert a suggestion
    -- if you have manually navigated to it and highlighted it.
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
  }),
  sources = cmp.config.sources({
    -- High priority sources
    { name = "minuet" },
    { name = "path" },
    { name = "buffer" },
    {
      name = "tags",
      option = {
        current_buffer_only = false,
        keyword_length = 3,
        max_items = 15,
      },
    },
  }, {
    -- Low priority sources
  }),
  formatting = {
    format = function(entry, vim_item)
      local menu_labels = {
        path = "[Path]",
        tags = "[Tag]",
        buffer = "[Buf]",
        cmdline = "[Cmd]",
        minuet = "[AI]",
      }
      vim_item.menu = menu_labels[entry.source.name] or entry.source.name
      return vim_item
    end,
  },
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won"t work anymore).
cmp.setup.cmdline({ "/", "?" }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" },
  },
})

-- Use cmdline & path source for ":" (if you enabled `native_menu`, this won"t work anymore).
cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path" },
  }, {
    { name = "cmdline" },
  }),
  matching = { disallow_symbol_nonprefix_matching = false },
  enabled = function()
    -- Set of commands where cmp will be disabled
    local disabled = {
      w = true,
      wq = true,
      q = true,
      qa = true,
    }
    -- Get first word of cmdline
    local cmd = vim.fn.getcmdline():match("%S+")
    -- Return true if cmd isn't disabled
    -- else call/return cmp.close(), which returns false
    return not disabled[cmd] or cmp.close()
  end,
})
