vim.loader.enable()
-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = { 'git', 'clone', '--filter=blob:none', 'https://github.com/echasnovski/mini.nvim', mini_path }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps' (customize to your liking)
require('mini.deps').setup({ path = { package = path_package } })

-- Use 'mini.deps'. `now()` and `later()` are helpers for a safe two-stage
-- startup and are optional.
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- [[ General Options ]]
now(function ()
	vim.o.cursorline = false
	vim.o.signcolumn = "no"
	require('mini.basics').setup()
end)

-- [[ UI ]]
now(function ()
	vim.cmd('colorscheme vim')
end)

later(function ()
	add("folke/which-key.nvim")
	require('which-key').setup()
end)
-- [[ Editing ]]
later(function ()
	require('mini.pairs').setup()
	require('mini.comment').setup()
end)

-- [[ Navigation ]]
later(function ()
	require('mini.bracketed').setup()
end)

-- [[ Misc ]]
later(function ()
	add('dstein64/vim-startuptime')
	vim.g.startuptime_tries = 10
end)
