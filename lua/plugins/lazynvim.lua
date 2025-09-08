local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  {'nvim-treesitter/nvim-treesitter', branch = 'master', lazy = false, build = ':TSUpdate'},
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require('nvim-tree').setup {}
    end,
  },
  { 'nvim-tree/nvim-web-devicons', opts = {} },
  -- {
  --   'nvim-telescope/telescope.nvim', tag = '0.1.8',
  --   dependencies = { 'nvim-lua/plenary.nvim' }
  -- },
  --
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },
  { 'lewis6991/gitsigns.nvim', name = 'gitsigns' },
  {
    'nvim-pack/nvim-spectre',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },

  -- Code outline navigation
  {
    'stevearc/aerial.nvim',
    opts = {
      backends = { 'treesitter', 'lsp' },
    },
    -- Optional dependencies
    dependencies = {
       'nvim-treesitter/nvim-treesitter',
       'nvim-tree/nvim-web-devicons'
    },
  },

  -- LSP setup
  { 'neovim/nvim-lspconfig', name = 'nvim-lspconfig' },
  { 'mason-org/mason.nvim', version = '^2.0.1' },
  {
    'mason-org/mason-lspconfig.nvim',
    version = '^2.1.0',
    dependencies = {
      'mason-org/mason.nvim',
      'neovim/nvim-lspconfig',
    },
  },

  -- Autocomplete
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/cmp-buffer' },
  { 'hrsh7th/cmp-path' },
  { 'hrsh7th/cmp-cmdline' },
  { 'hrsh7th/nvim-cmp' },
  { 'L3MON4D3/LuaSnip' },
  { 'saadparwaiz1/cmp_luasnip' },

  -- Formatting
  {
    'nvimtools/none-ls.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  {
    'jay-babu/mason-null-ls.nvim',
    dependencies = {
      'williamboman/mason.nvim',
      'nvimtools/none-ls.nvim',
    },
    event = { 
      'BufReadPre', 
      'BufNewFile' 
    },
  },

  -- Github Copilot
  { 'github/copilot.vim' },

  { 'lukas-reineke/indent-blankline.nvim', main = 'ibl', opts = {} },
  { 'rcarriga/nvim-notify' },
  { 'rebelot/kanagawa.nvim', name = 'kanagawa', priority = 1000 },
  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 }
})

