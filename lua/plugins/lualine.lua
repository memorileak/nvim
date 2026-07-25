local minuet_lualine = require("minuet.lualine")

require("lualine").setup({
  options = {
    theme = "auto",
  },
  sections = {
    lualine_x = {
      {
        minuet_lualine,
        display_name = "both",
        provider_model_separator = ":",
        display_on_idle = false,
      },
      "encoding",
      "fileformat",
      "filetype",
    },
  },
})
