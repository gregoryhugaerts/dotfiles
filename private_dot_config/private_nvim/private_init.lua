vim.loader.enable()

-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath("data") .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.nvim"
if not vim.loop.fs_stat(mini_path) then
	vim.cmd('echo "Installing `mini.nvim`" | redraw')
	local clone_cmd = { "git", "clone", "--filter=blob:none", "https://github.com/echasnovski/mini.nvim", mini_path }
	vim.fn.system(clone_cmd)
	vim.cmd("packadd mini.nvim | helptags ALL")
	vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps' (customize to your liking)
require("mini.deps").setup({ path = { package = path_package } })

-- Use 'mini.deps'. `now()` and `later()` are helpers for a safe two-stage startup
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- [[ Options ]]
now(function()
	vim.o.autoindent = true
	vim.o.shiftwidth = 4
	vim.o.tabstop = 4
	vim.o.expandtab = true
	vim.o.cursorline = false
	vim.o.signcolumn = "no"
	vim.o.relativenumber = true
	require("mini.basics").setup()
end)

-- [[ UI ]]
now(function()
	add("folke/tokyonight.nvim")
	vim.cmd("colorscheme tokyonight-night")
end)

later(function()
	local hipatterns = require("mini.hipatterns")
	local _m = require("mini.map")
	require("mini.statusline").setup()
	require("mini.indentscope").setup()
	local miniclue = require("mini.clue")
	miniclue.setup({
		triggers = {
			-- Leader triggers
			{ mode = "n", keys = "<Leader>" },
			{ mode = "x", keys = "<Leader>" },

			-- Built-in completion
			{ mode = "i", keys = "<C-x>" },

			-- toggles
			{ mode = "n", keys = "\\" },

			-- surround
			{ mode = "n", keys = "s" },
			{ mode = "x", keys = "s" },

			-- brackets
			{ mode = "n", keys = "[" },
			{ mode = "n", keys = "]" },

			-- `g` key
			{ mode = "n", keys = "g" },
			{ mode = "x", keys = "g" },

			-- Marks
			{ mode = "n", keys = "'" },
			{ mode = "n", keys = "`" },
			{ mode = "x", keys = "'" },
			{ mode = "x", keys = "`" },

			-- Registers
			{ mode = "n", keys = '"' },
			{ mode = "x", keys = '"' },
			{ mode = "i", keys = "<C-r>" },
			{ mode = "c", keys = "<C-r>" },

			-- Window commands
			{ mode = "n", keys = "<C-w>" },

			-- `z` key
			{ mode = "n", keys = "z" },
			{ mode = "x", keys = "z" },
		},

		clues = {
			{ mode = "n", keys = "<Leader>l", desc = "LSP" },
			{ mode = "n", keys = "<Leader>b", desc = "Buffer" },
			{ mode = "n", keys = "<Leader>q", desc = "NVim" },
			{ mode = "n", keys = "<leader>m", desc = "Mini" },
			{ mode = "n", keys = "<leader>f", desc = "Find" },
			miniclue.gen_clues.builtin_completion(),
			miniclue.gen_clues.g(),
			miniclue.gen_clues.marks(),
			miniclue.gen_clues.registers(),
			miniclue.gen_clues.windows(),
			miniclue.gen_clues.z(),
		},
	})
	hipatterns.setup({
		highlighters = {
			-- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
			fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
			hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
			todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
			note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },

			-- Highlight hex color strings (`#rrggbb`) using that color
			hex_color = hipatterns.gen_highlighter.hex_color(),
		},
	})
	require("mini.map").setup({
		integrations = {
			_m.gen_integration.builtin_search(),
			_m.gen_integration.diagnostic(),
		},
		symbols = {
			encode = _m.gen_encode_symbols.dot("4x2"),
			scroll_line = "",
			scroll_view = "",
		},

		window = {
			focusable = true,

			width = 20,
			winblend = 75,
		},
	})
	require("mini.pick").setup({
		options = {
			use_cache = true,
		},
	})
	require("mini.starter")
	vim.ui.select = MiniPick.ui_select
end)

-- [[ Coding ]]
later(function()
	require("mini.completion").setup({
		mappings = {
			go_in = "<RET>",
		},
		window = {
			info = { border = "solid" },
			signature = { border = "solid" },
		},
	})
	add({
		source = "williamboman/mason-lspconfig.nvim",
		depends = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
	})
	require("mason").setup()
	require("mason-lspconfig").setup()
	require("mason-lspconfig").setup_handlers({
		-- The first entry (without a key) will be the default handler
		-- and will be called for each installed server that doesn't have
		-- a dedicated handler.
		function(server_name) -- default handler (optional)
			require("lspconfig")[server_name].setup({})
		end,
	})
	require("lspconfig").lua_ls.setup({})
	local imap_expr = function(lhs, rhs)
		vim.keymap.set("i", lhs, rhs, { expr = true })
	end
	imap_expr("<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]])
	imap_expr("<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]])
end)

-- [[ Editing ]]
later(function()
	require("mini.pairs").setup()
	require("mini.ai").setup()
	require("mini.jump").setup()
	require("mini.jump2d").setup()
	require("mini.move").setup({
		mappings = {
			-- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
			left = "<M-S-h>",
			right = "<M-S-l>",
			down = "<M-S-j>",
			up = "<M-S-k>",
			-- Move current line in Normal mode
			line_left = "<M-S-h>",
			line_right = "<M-S-l>",
			line_down = "<M-S-j>",
			line_up = "<M-S-k>",
		},
	})
	require("mini.operators")
	require("mini.trailspace").setup()
	require("mini.surround").setup()
	require("mini.bracketed").setup()
end)

-- [[ Utility ]]
later(function()
	add("dstein64/vim-startuptime")
	vim.g.startuptime_tries = 10
	require("mini.bufremove")
	require("mini.extra").setup()
	require("mini.files").setup({
		mappings = {
			close = "<ESC>",
		},
		windows = {
			preview = true,
			border = "solid",
			width_preview = 80,
		},
	})
end)

-- [[ Keybinds ]]
local keymap = vim.keymap.set
keymap(
	"n",
	"<leader>ml",
	"<Cmd>lua MiniJump2d.start(MiniJump2d.builtin_opts.line_start)<CR>",
	{ desc = "Jump to line" }
)
keymap("n", "<leader>qq", "<cmd>wqa<cr>", { desc = "Quit" })
keymap("n", "<leader>mu", function()
	require("mini.deps").update()
end, { desc = "Update Plugins" })
keymap("n", "<leader>mm", function()
	require("mini.map").toggle()
end, { desc = "Toggle Minimap" })
-- Buffer
keymap("n", "<leader>bd", "<cmd>bd<cr>", { desc = "Close Buffer" })
keymap("n", "<leader>bq", "<cmd>%bd|e#<cr>", { desc = "Close other Buffers" })
keymap("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
keymap("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })
keymap("n", "<TAB>", "<C-^>", { desc = "Alternate buffers" })
-- Format Buffer
-- With and without LSP
if vim.tbl_isempty(vim.lsp.buf_get_clients()) then
	keymap("n", "<leader>bf", function()
		vim.lsp.buf.format()
	end, { desc = "Format Buffer" })
else
	keymap("n", "<leader>bf", "gg=G<C-o>", { desc = "Format Buffer" })
end
-- Editing
keymap("n", "YY", "<cmd>%y<cr>", { desc = "Yank Buffer" })
keymap("n", "<Esc>", "<cmd>noh<cr>", { desc = "Clear Search" })
-- LSP
keymap("n", "<leader>ld", function()
	vim.lsp.buf.definition()
end, { desc = "Go To Definition" })
keymap("n", "<leader>ls", "<cmd>Pick lsp scope='document_symbol'<cr>", { desc = "Show all Symbols" })
keymap("n", "<leader>lr", function()
	vim.lsp.buf.rename()
end, { desc = "Rename This" })
keymap("n", "<leader>la", function()
	vim.lsp.buf.code_action()
end, { desc = "Code Actions" })
keymap("n", "<leader>le", function()
	require("mini.extra").pickers.diagnostic({ scope = "current" })
end, { desc = "LSP Errors in Buffer" })
keymap("n", "<leader>lf", function()
	vim.diagnostic.setqflist({ open = true })
end, { desc = "LSP Quickfix" })
-- Find
keymap("n", "<leader>fs", function()
	require("mini.pick").builtin.files()
end, { desc = "Find File" })
keymap("n", "<leader>fa", function()
	require("mini.pick").builtin.resume()
end, { desc = "Find File" })
keymap("n", "<leader>e", function()
	local buffer_name = vim.api.nvim_buf_get_name(0)
	if buffer_name == "" or string.match(buffer_name, "Starter") then
		require("mini.files").open(vim.loop.cwd())
	else
		require("mini.files").open(vim.api.nvim_buf_get_name(0))
	end
end, { desc = "Find Manualy" })
keymap("n", "<leader><space>", function()
	require("mini.pick").builtin.buffers()
end, { desc = "Find Buffer" })
keymap("n", "<leader>fg", function()
	require("mini.pick").builtin.grep_live()
end, { desc = "Find String" })
keymap("n", "<leader>fG", function()
	local wrd = vim.fn.expand("<cword>")
	require("mini.pick").builtin.grep({ pattern = wrd })
end, { desc = "Find String Cursor" })
keymap("n", "<leader>fh", function()
	require("mini.pick").builtin.help()
end, { desc = "Find Help" })
keymap("n", "<leader>fl", function()
	require("mini.extra").pickers.hl_groups()
end, { desc = "Find HL Groups" })
keymap("n", ",", function()
	require("mini.extra").pickers.buf_lines({ scope = "current" })
end, { nowait = true, desc = "Search Lines" })
