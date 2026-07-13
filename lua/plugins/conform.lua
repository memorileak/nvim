return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "gb",
      function()
        require("conform").format({ async = true })
      end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      sh = { "shfmt" },
      lua = { "stylua" },
      rust = { "rustfmt" },
      -- Using stop_after_first: if prettierd is there then prettier won't be used
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      svelte = { "prettierd", "prettier", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
      yaml = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
    },
    default_format_opts = {
      lsp_format = "never",
    },
    -- Comment out to disable format on save
    -- format_on_save = {
    --   timeout_ms = 500,
    -- },
  },
  init = function()
    -- Aligned: Allows you to highlight code and press 'gq' to format
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
