vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus"
vim.opt.updatetime = 250
vim.g.mapleader = " "
vim.cmd("highlight Normal guibg=$base guifg=$text")
vim.cmd("highlight NormalFloat guibg=$surface0 guifg=$text")
vim.cmd("highlight FloatBorder guibg=$surface0 guifg=$overlay0")
vim.cmd("highlight CursorLine guibg=$surface1")
vim.cmd("highlight Visual guibg=$overlay1")
vim.cmd("highlight Directory guifg=$accent")
