local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup {}
    end,
  },
  {
    "nvim-telescope/telescope.nvim", tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  { "lewis6991/gitsigns.nvim", name = "gitsigns" },
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  { "williamboman/mason.nvim", name = "mason" },
  { "williamboman/mason-lspconfig.nvim", name = "mason-lspconfig" },
  { "neovim/nvim-lspconfig", name = "nvim-lspconfig" },

  -- Autocomplete
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },
  { "hrsh7th/nvim-cmp" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },

  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
  { "rcarriga/nvim-notify" },
  { "rebelot/kanagawa.nvim", name = "kanagawa", priority = 1000 },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 }
})

