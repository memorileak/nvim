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
  { "williamboman/mason.nvim", name = "mason" },
  { "williamboman/mason-lspconfig.nvim", name = "mason-lspconfig" },
  { "neovim/nvim-lspconfig", name = "nvim-lspconfig" },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
  { "rebelot/kanagawa.nvim", name = "kanagawa", priority = 1000 },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 }
})

