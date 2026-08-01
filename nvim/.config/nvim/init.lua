-- =============================================================================
-- 外观
-- =============================================================================

-- 启用 24-bit 真彩色支持（终端需支持）
vim.opt.termguicolors = true

-- 透明背景：去掉编辑区/侧栏/浮窗等实心底色，露出终端（或 picom）背景。
-- 换 colorscheme 后会经 ColorScheme 自动重跑；保留各高亮组的 fg/样式。
local function apply_transparent_bg()
	local groups = {
		"Normal",
		"NormalNC",
		"NormalFloat",
		"FloatBorder",
		"FloatTitle",
		"SignColumn",
		"EndOfBuffer",
		"LineNr",
		"CursorLineNr",
		"Folded",
		"FoldColumn",
		"WinSeparator",
		"VertSplit",
		"StatusLine",
		"StatusLineNC",
		"TabLine",
		"TabLineFill",
		"TabLineSel",
		"Pmenu",
		"PmenuSbar",
		"NvimTreeNormal",
		"NvimTreeNormalNC",
		"NvimTreeEndOfBuffer",
		"NvimTreeSignColumn",
		"NvimTreeWinSeparator",
		"TelescopeNormal",
		"TelescopeBorder",
		"TelescopePromptNormal",
	}

	for _, group in ipairs(groups) do
		local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
		if not ok then
			hl = {}
		end
		vim.api.nvim_set_hl(0, group, {
			fg = hl.fg,
			bg = "NONE",
			sp = hl.sp,
			bold = hl.bold,
			italic = hl.italic,
			underline = hl.underline,
			undercurl = hl.undercurl,
			strikethrough = hl.strikethrough,
			reverse = hl.reverse,
			ctermfg = hl.ctermfg,
			ctermbg = "NONE",
		})
	end

	-- 分隔线仅保留前景，避免实心条
	vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { fg = "#2a2a2a", bg = "NONE" })
	vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#2a2a2a", bg = "NONE" })
end

-- 设置配色方案（onedark.vim，装在 site/pack/themes）
vim.cmd.colorscheme("onedark")
apply_transparent_bg()

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("TransparentBG", { clear = true }),
	callback = apply_transparent_bg,
})

-- leader 键设置为空格，需要在所有 keymap 之前设置
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- =============================================================================
-- 选项
-- =============================================================================

-- 行号
vim.opt.number = true -- 显示绝对行号
vim.opt.relativenumber = true -- 显示相对行号（配合 number 显示当前行绝对行号）
vim.opt.cursorline = true -- 高亮当前行

-- 滚动
vim.opt.scrolloff = 10 -- 光标上下保留至少 10 行可视区域
vim.opt.sidescrolloff = 10 -- 光标左右保留至少 10 列可视区域
vim.opt.wrap = false -- 不自动折行（长行向右延伸）

-- 缩进（使用 4 空格）
vim.opt.expandtab = true -- Tab 键插入空格而非 \t
vim.opt.shiftwidth = 4 -- 自动缩进宽度（>>、<<、智能缩进）
vim.opt.tabstop = 4 -- \t 字符显示宽度
vim.opt.softtabstop = 4 -- Tab/Backspace 操作的空格数，与 tabstop 一致避免混乱
vim.opt.smartindent = true -- 插入新行时根据语法自动缩进
vim.opt.autoindent = true -- 新行继承上一行的缩进

-- 搜索
vim.opt.ignorecase = true -- 搜索忽略大小写
vim.opt.smartcase = true -- 搜索词含大写字母时自动区分大小写
vim.opt.hlsearch = true -- 高亮所有匹配项
vim.opt.incsearch = true -- 输入时即时显示匹配（Neovim 默认开启，显式声明更清晰）

-- 视觉辅助
vim.opt.signcolumn = "yes" -- 始终显示 sign 列（避免 LSP/git 图标出现时布局跳动）
vim.opt.colorcolumn = "100" -- 在第 100 列显示参考线
vim.opt.showmatch = true -- 输入括号时短暂跳转到匹配括号
vim.opt.showmode = false -- 不在命令行显示模式（statusline 已有模式显示）
vim.opt.pumheight = 10 -- 补全弹出菜单最多显示 10 项
vim.opt.fillchars = { eob = " " } -- 用空格替代缓冲区末尾的 "~" 符号

-- 分屏
vim.opt.splitbelow = true -- 水平分屏新窗口在下方
vim.opt.splitright = true -- 垂直分屏新窗口在右侧

-- 剪贴板与鼠标
vim.opt.clipboard = "unnamedplus" -- 使用系统剪贴板（需要 xclip/xsel/wl-clipboard）
vim.opt.mouse = "a" -- 所有模式下启用鼠标支持

-- 持久化撤销（重启 Neovim 后仍可撤销；默认写入 stdpath("state")/undo）
vim.opt.undofile = true
vim.opt.swapfile = false -- 不创建交换文件
vim.opt.backup = false -- 不创建备份文件
vim.opt.writebackup = false -- 写入时不创建临时备份

-- 性能
vim.opt.updatetime = 300 -- 触发 CursorHold 事件的等待时间（影响 LSP 诊断延迟）
vim.opt.timeoutlen = 500 -- 等待按键序列完成的时间（ms），影响 which-key 类插件

-- 折叠（交给 treesitter 的 autocmd 按 FileType 激活，全局先关闭）
vim.opt.foldlevel = 99 -- 默认展开所有折叠

-- 其他
vim.opt.hidden = true -- 允许切换缓冲区时保留未保存的修改
vim.opt.backspace = "indent,eol,start" -- 允许 Backspace 跨越缩进、行尾、插入点
vim.opt.iskeyword:append("-") -- 将 - 视为单词字符（如 CSS 类名 flex-col 视为整体）
vim.opt.cmdheight = 1 -- 命令行高度

-- 禁用 netrw（使用 nvim-tree 替代，需在 nvim-tree 加载前设置）
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- =============================================================================
-- STATUSLINE
-- =============================================================================

-- Git 分支名缓存（避免每次渲染 statusline 都调用 shell 命令）
local cached_branch = ""
local last_check = 0
local function git_branch()
	local now = vim.uv.now()
	-- 每 5 秒刷新一次，平衡实时性与性能
	if now - last_check > 5000 then
		cached_branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
		last_check = now
	end
	if cached_branch ~= "" then
		return " \u{e725} " .. cached_branch .. " " -- nf-dev-git_branch 图标
	end
	return ""
end

-- 文件类型显示（带 Nerd Font 图标）
local function file_type()
	local ft = vim.bo.filetype
	local icons = {
		lua = "\u{e620} ", -- nf-dev-lua
		python = "\u{e73c} ", -- nf-dev-python
		javascript = "\u{e74e} ", -- nf-dev-javascript
		typescript = "\u{e628} ", -- nf-dev-typescript
		javascriptreact = "\u{e7ba} ",
		typescriptreact = "\u{e7ba} ",
		html = "\u{e736} ", -- nf-dev-html5
		css = "\u{e749} ", -- nf-dev-css3
		scss = "\u{e749} ",
		json = "\u{e60b} ", -- nf-dev-json
		markdown = "\u{e73e} ", -- nf-dev-markdown
		vim = "\u{e62b} ", -- nf-dev-vim
		sh = "\u{f489} ", -- nf-oct-terminal
		bash = "\u{f489} ",
		zsh = "\u{f489} ",
		rust = "\u{e7a8} ", -- nf-dev-rust
		go = "\u{e724} ", -- nf-dev-go
		c = "\u{e61e} ", -- nf-dev-c
		cpp = "\u{e61d} ", -- nf-dev-cplusplus
		java = "\u{e738} ", -- nf-dev-java
		php = "\u{e73d} ", -- nf-dev-php
		ruby = "\u{e739} ", -- nf-dev-ruby
		swift = "\u{e755} ", -- nf-dev-swift
		kotlin = "\u{e634} ",
		dart = "\u{e798} ",
		elixir = "\u{e62d} ",
		haskell = "\u{e777} ",
		sql = "\u{e706} ",
		yaml = "\u{f481} ",
		toml = "\u{e615} ",
		xml = "\u{f05c} ",
		dockerfile = "\u{f308} ", -- nf-linux-docker
		gitcommit = "\u{f418} ", -- nf-oct-git_commit
		gitconfig = "\u{f1d3} ", -- nf-fa-git
		vue = "\u{fd42} ", -- nf-md-vuejs
		svelte = "\u{e697} ",
		astro = "\u{e628} ",
	}
	if ft == "" then
		return " \u{f15b} " -- nf-fa-file_o（无文件类型时的占位图标）
	end
	return (icons[ft] or " \u{f15b} ") .. ft
end

-- 文件大小显示
local function file_size()
	local size = vim.fn.getfsize(vim.fn.expand("%"))
	if size < 0 then
		return "" -- 文件不存在或无法获取大小
	end
	local size_str
	if size < 1024 then
		size_str = size .. "B"
	elseif size < 1024 * 1024 then
		size_str = string.format("%.1fK", size / 1024)
	else
		size_str = string.format("%.1fM", size / 1024 / 1024)
	end
	return " \u{f016} " .. size_str .. " " -- nf-fa-file_o
end

-- 当前模式显示（带 Nerd Font 图标）
local function mode_icon()
	local mode = vim.fn.mode()
	local modes = {
		n = " \u{f121}  NORMAL", -- nf-fa-code
		i = " \u{f11c}  INSERT", -- nf-fa-keyboard_o
		v = " \u{f0168} VISUAL", -- nf-md-select_all
		V = " \u{f0168} V-LINE",
		["\22"] = " \u{f0168} V-BLOCK", -- Ctrl-V 的原始字节
		c = " \u{f120} COMMAND", -- nf-fa-terminal
		s = " \u{f0c5} SELECT",
		S = " \u{f0c5} S-LINE",
		["\19"] = " \u{f0c5} S-BLOCK", -- Ctrl-S 的原始字节
		R = " \u{f044} REPLACE",
		r = " \u{f044} REPLACE",
		["!"] = " \u{f489} SHELL",
		t = " \u{f120} TERMINAL",
	}
	return modes[mode] or (" \u{f059} " .. mode)
end

-- 暴露到全局供 statusline 的 vimscript 表达式调用
-- statusline 字符串中 %{v:lua.xxx()} 只能访问全局函数
_G.mode_icon = mode_icon
_G.git_branch = git_branch
_G.file_type = file_type
_G.file_size = file_size

-- 定义加粗高亮组，用于 statusline 中的模式区域
vim.api.nvim_set_hl(0, "StatusLineBold", { bold = true })

-- 根据窗口焦点切换 statusline 样式
local function setup_dynamic_statusline()
	-- 当前窗口：显示完整信息
	vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
		callback = function()
			vim.opt_local.statusline = table.concat({
				"  ",
				"%#StatusLineBold#",
				"%{v:lua.mode_icon()}", -- 当前模式
				"%#StatusLine#",
				" \u{e0b1} %f %h%m%r", -- 文件名 + 修改/只读标志，nf-pl-left_soft_divider
				"%{v:lua.git_branch()}", -- git 分支
				"\u{e0b1} ",
				"%{v:lua.file_type()}", -- 文件类型 + 图标
				"\u{e0b1} ",
				"%{v:lua.file_size()}", -- 文件大小
				"%=", -- 右对齐分隔符
				" \u{f017} %l:%c  %P ", -- 行:列 + 百分比位置，nf-fa-clock_o
			})
		end,
	})
	-- 非焦点窗口：精简显示
	vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
		callback = function()
			vim.opt_local.statusline = "  %f %h%m%r \u{e0b1} %{v:lua.file_type()} %=  %l:%c   %P "
		end,
	})
end

setup_dynamic_statusline()

-- =============================================================================
-- 快捷键
-- =============================================================================

-- 保存与退出
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
vim.keymap.set("n", "<leader>wq", "<cmd>quit<cr>", { desc = "Close window" })

-- 清除搜索高亮
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- 搜索结果居中显示（避免结果出现在屏幕边缘）
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })

-- 半页滚动居中（与搜索居中保持一致的体验）
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- j/k 在有折行时按视觉行移动，有计数时按实际行移动（支持 5j 之类的操作）
vim.keymap.set("n", "j", function()
	return vim.v.count == 0 and "gj" or "j"
end, { expr = true, silent = true, desc = "Down (wrap-aware)" })
vim.keymap.set("n", "k", function()
	return vim.v.count == 0 and "gk" or "k"
end, { expr = true, silent = true, desc = "Up (wrap-aware)" })

-- 粘贴不覆盖寄存器（先删除到黑洞寄存器，再粘贴）
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
-- 删除不覆盖寄存器
vim.keymap.set({ "n", "v" }, "<leader>x", '"_d', { desc = "Delete without yanking" })

-- 合并行保持光标位置（原生 J 会将光标移到合并点）
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- 缩进后保持选区（原生 < > 会退出 visual 模式）
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- 移动行/选区（Alt+j/k）
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- 缓冲区切换
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
-- mini.bufremove 在插件 setup 之后绑定 <leader>bd（见下方 mini 配置）

-- 窗口分屏
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })

-- 窗口导航（与常见 Vim/tmux 习惯一致）
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Focus window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Focus window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Focus window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Focus window right" })

-- 调整窗口大小
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- 复制当前文件完整路径到系统剪贴板
vim.keymap.set("n", "<leader>pa", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	print("file:", path)
end, { desc = "Copy full file path" })

-- 切换诊断显示（临时关闭可减少视觉干扰）
-- vim.keymap.set("n", "<leader>td", function()
--  	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
-- end, { desc = "Toggle diagnostics" })

-- =============================================================================
-- 格式化策略（方案 C：有项目配置才自动 format + 可 toggle）
-- =============================================================================
-- 前端痛点：无 Prettier、仅 ESLint 的仓库（如公司 Vue 项目）若仍跑 prettierd，
-- 会把分号/引号改成 Prettier 默认，与 .eslintrc / antfu eslint --fix 冲突。
-- 规则：
--   - prettier 配置存在 → 用 efm/prettierd（尊重项目配置）
--   - 仅 eslint 配置 → 用项目本地 eslint --fix-to-stdout（不跑 prettier）
--   - 都没有 → 保存时不格式化
--   - 其它语言：见 marker 表；Java 仍走 jdtls
-- 开关：vim.g.disable_autoformat / vim.b.disable_autoformat
--       <leader>uf 全局 toggle，<leader>uF 当前 buffer toggle，<leader>fm 手动 format

local format_config = {
	prettier_markers = {
		".prettierrc",
		".prettierrc.json",
		".prettierrc.js",
		".prettierrc.cjs",
		".prettierrc.mjs",
		".prettierrc.yml",
		".prettierrc.yaml",
		".prettierrc.toml",
		".prettierrc.json5",
		"prettier.config.js",
		"prettier.config.cjs",
		"prettier.config.mjs",
	},
	eslint_markers = {
		".eslintrc",
		".eslintrc.js",
		".eslintrc.cjs",
		".eslintrc.json",
		".eslintrc.yml",
		".eslintrc.yaml",
		"eslint.config.js",
		"eslint.config.cjs",
		"eslint.config.mjs",
		"eslint.config.ts",
	},
	-- 非前端：存在任一 marker 才允许自动 format（通过 efm/jdtls）
	markers_by_ft = {
		lua = { "stylua.toml", ".stylua.toml" },
		python = { "pyproject.toml", "setup.cfg", "black.toml", ".black" },
		go = { "go.mod", "go.work" },
		c = { ".clang-format" },
		cpp = { ".clang-format" },
		-- sh/bash：无通用项目 marker，默认允许 shfmt（冲突少）
		sh = true,
		bash = true,
		zsh = true,
		java = true, -- jdtls
	},
	frontend_fts = {
		javascript = true,
		javascriptreact = true,
		typescript = true,
		typescriptreact = true,
		vue = true,
		svelte = true,
		css = true,
		scss = true,
		less = true,
		html = true,
		json = true,
		jsonc = true,
		markdown = true,
	},
	-- 可用 eslint --fix 的 filetype（antfu formatters 也会管一部分 css/html/vue）
	eslint_fix_fts = {
		javascript = true,
		javascriptreact = true,
		typescript = true,
		typescriptreact = true,
		vue = true,
		svelte = true,
		css = true,
		scss = true,
		less = true,
		html = true,
		json = true,
		jsonc = true,
		markdown = true,
	},
}

local function format_root_for(path, markers)
	if type(markers) ~= "table" then
		return nil
	end
	return vim.fs.root(path, markers)
end

local function lsp_format(bufnr, client_name)
	local has = false
	for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		if c.name == client_name then
			has = true
			break
		end
	end
	if not has then
		return false, "no " .. client_name .. " client"
	end
	local ok, err = pcall(vim.lsp.buf.format, {
		bufnr = bufnr,
		timeout_ms = 3000,
		filter = function(c)
			return c.name == client_name
		end,
	})
	if not ok then
		return false, err
	end
	return true
end

---用项目本地 eslint --fix（写临时文件）格式化。
---现代 eslint 已无 --fix-to-stdout；stdin+| --fix 也不可用。临时文件放在同目录以吃到正确 overrides。
local function eslint_fix_buffer(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	local root = format_root_for(path, format_config.eslint_markers)
	if not root then
		return false, "no eslint config"
	end

	local local_eslint = vim.fs.joinpath(root, "node_modules", ".bin", "eslint")
	local cmd = nil
	if vim.uv.fs_stat(local_eslint) then
		cmd = local_eslint
	elseif vim.fn.executable("eslint") == 1 then
		cmd = "eslint"
	else
		return false, "project eslint not found (npm/pnpm install?)"
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local ext = path:match("(%.[^./]+)$") or ".js"
	local dir = vim.fs.dirname(path)
	-- 不要用点开头文件名：ESLint 会默认 ignore（File ignored by default）
	local tmp = vim.fs.joinpath(dir, "__nvim_eslint_fmt_" .. tostring(vim.fn.getpid()) .. ext)

	local write_ok = pcall(function()
		vim.fn.writefile(lines, tmp)
	end)
	if not write_ok then
		return false, "cannot write temp file for eslint"
	end

	local result = vim.system({ cmd, "--fix", tmp }, {
		cwd = root,
		text = true,
	}):wait()

	local new_lines = nil
	local read_ok, read_lines = pcall(vim.fn.readfile, tmp)
	pcall(vim.fn.delete, tmp)

	if read_ok then
		new_lines = read_lines
	end

	-- exit 0/1 都可能已写入 fix；>1 为致命错误
	if result.code > 1 then
		local err = (result.stderr ~= "" and result.stderr) or ("eslint exit " .. tostring(result.code))
		return false, err
	end
	if not new_lines then
		return false, "eslint produced no output file"
	end
	if vim.deep_equal(lines, new_lines) then
		return true
	end
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
	return true
end

---解析本 buffer 保存时应如何 format；force=true 时忽略「无配置则跳过」但仍尊重 disable 开关
---@return "skip"|"efm"|"jdtls"|"eslint" kind
---@return string|nil reason
local function resolve_format_kind(bufnr, force)
	if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
		return "skip", "autoformat disabled"
	end
	if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
		return "skip", "special buffer"
	end
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then
		return "skip", "unnamed"
	end

	local ft = vim.bo[bufnr].filetype

	if ft == "java" then
		return "jdtls"
	end

	if format_config.frontend_fts[ft] then
		if format_root_for(path, format_config.prettier_markers) then
			return "efm", "prettier"
		end
		if format_config.eslint_fix_fts[ft] and format_root_for(path, format_config.eslint_markers) then
			return "eslint", "eslint-only project"
		end
		if force then
			-- 手动 format：无配置时仍尝试 efm（可能 prettier 默认）
			return "efm", "force"
		end
		return "skip", "no prettier/eslint project config"
	end

	local markers = format_config.markers_by_ft[ft]
	if markers == true then
		return "efm"
	end
	if type(markers) == "table" then
		if format_root_for(path, markers) or force then
			return "efm"
		end
		return "skip", "no project formatter config for " .. ft
	end

	-- 未列出的 filetype：不自动 format
	if force then
		return "efm"
	end
	return "skip", "filetype not configured for autoformat"
end

local function run_format(bufnr, opts)
	opts = opts or {}
	local kind, reason = resolve_format_kind(bufnr, opts.force)
	if kind == "skip" then
		if opts.notify then
			vim.notify("format skip: " .. (reason or ""), vim.log.levels.INFO)
		end
		return false
	end
	if kind == "eslint" then
		local ok, err = eslint_fix_buffer(bufnr)
		if not ok and opts.notify then
			vim.notify("eslint fix failed: " .. tostring(err), vim.log.levels.WARN)
		end
		return ok
	end
	if kind == "jdtls" then
		local ok, err = lsp_format(bufnr, "jdtls")
		if not ok and opts.notify then
			vim.notify("jdtls format: " .. tostring(err), vim.log.levels.WARN)
		end
		return ok
	end
	-- efm
	local ok, err = lsp_format(bufnr, "efm")
	if not ok and opts.notify then
		vim.notify("efm format: " .. tostring(err), vim.log.levels.WARN)
	end
	return ok
end

vim.keymap.set("n", "<leader>uf", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	vim.notify(
		"format-on-save (global): " .. (vim.g.disable_autoformat and "OFF" or "ON"),
		vim.log.levels.INFO
	)
end, { desc = "Toggle format-on-save (global)" })

vim.keymap.set("n", "<leader>uF", function()
	vim.b.disable_autoformat = not vim.b.disable_autoformat
	vim.notify(
		"format-on-save (buffer): " .. (vim.b.disable_autoformat and "OFF" or "ON"),
		vim.log.levels.INFO
	)
end, { desc = "Toggle format-on-save (buffer)" })

vim.keymap.set("n", "<leader>fm", function()
	run_format(vim.api.nvim_get_current_buf(), { force = true, notify = true })
end, { desc = "Format buffer (manual, best-effort)" })

-- =============================================================================
-- AUTOCMDS
-- =============================================================================

-- 所有用户 autocmd 放在同一个 augroup 中，便于管理和避免重复注册
local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- 保存时按项目配置选择 formatter（见上方 format 策略）
vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup,
	pattern = {
		"*.lua",
		"*.py",
		"*.go",
		"*.js",
		"*.jsx",
		"*.ts",
		"*.tsx",
		"*.vue",
		"*.svelte",
		"*.json",
		"*.jsonc",
		"*.css",
		"*.scss",
		"*.html",
		"*.sh",
		"*.bash",
		"*.zsh",
		"*.c",
		"*.cpp",
		"*.h",
		"*.hpp",
		"*.java",
		"*.md",
	},
	callback = function(args)
		run_format(args.buf, { force = false, notify = false })
	end,
})

-- 复制后短暂高亮被复制的区域
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.hl.on_yank()
	end,
})

-- 重新打开文件时恢复上次光标位置
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup,
	desc = "Restore last cursor position",
	callback = function()
		-- diff 模式下不恢复（会干扰对比视图）
		if vim.o.diff then
			return
		end

		local last_pos = vim.api.nvim_buf_get_mark(0, '"') -- 返回 {line, col}
		local last_line = vim.api.nvim_buf_line_count(0)
		local row = last_pos[1]

		-- 行号有效才恢复（防止标记在文件被截断后越界）
		if row < 1 or row > last_line then
			return
		end

		pcall(vim.api.nvim_win_set_cursor, 0, last_pos)
	end,
})

-- Markdown/文本/Git commit 开启折行、整词折行和拼写检查
-- spelllang 加 cjk：不把中日韩文字标成错词（默认 en 会把中文整段标红下划线）
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "markdown", "text", "gitcommit" },
	callback = function()
		vim.opt_local.wrap = true -- 开启折行
		vim.opt_local.linebreak = true -- 在单词边界折行，而非字符中间
		vim.opt_local.spell = true
		vim.opt_local.spelllang = { "en", "cjk" }
	end,
})

-- =============================================================================
-- 插件安装 (vim.pack — Neovim 0.12 内置包管理器)
-- =============================================================================

-- rest.nvim 的 luarocks 依赖（xml2lua / mimetypes）装在 ~/.luarocks；
-- 必须在 vim.pack.add 加载 rest 的 plugin/ 检查之前加入 package.path。
do
	local home = vim.fn.expand("~")
	local lr_share = home .. "/.luarocks/share/lua/5.1"
	local lr_lib = home .. "/.luarocks/lib/lua/5.1"
	package.path = table.concat({
		lr_share .. "/?.lua",
		lr_share .. "/?/init.lua",
		package.path,
	}, ";")
	package.cpath = table.concat({
		lr_lib .. "/?.so",
		package.cpath,
	}, ";")
end

vim.pack.add({
	-- 工具集合（mini.ai/comment/surround 等，按需 setup）
	"https://github.com/echasnovski/mini.nvim",
	-- Git 集成（signs、blame、hunk 操作）
	"https://github.com/lewis6991/gitsigns.nvim",
	-- 文件树
	"https://github.com/nvim-tree/nvim-tree.lua",
	-- 模糊查找
	"https://github.com/ibhagwan/fzf-lua",
	-- 快捷键提示
	"https://github.com/folke/which-key.nvim",
	-- 语法高亮与结构感知
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate", -- 安装/更新后自动编译 parser
	},
	-- Markdown 内联渲染增强
	"https://github.com/MeanderingProgrammer/render-markdown.nvim",
	-- rest.nvim 进度提示（rockspec 依赖；vim.pack 不自动装 luarocks）
	"https://github.com/j-hui/fidget.nvim",
	-- HTTP 请求执行与响应查看
	"https://github.com/rest-nvim/rest.nvim",
	-- LSP 配置
	"https://github.com/neovim/nvim-lspconfig",
	-- LSP/格式化工具安装管理器
	"https://github.com/mason-org/mason.nvim",
	-- efm-langserver 的预置 linter/formatter 配置
	"https://github.com/creativenull/efmls-configs-nvim",
	-- Debug Adapter Protocol 客户端与 UI
	"https://github.com/mfussenegger/nvim-dap",
	"https://github.com/rcarriga/nvim-dap-ui",
	"https://github.com/nvim-neotest/nvim-nio",
	-- Java LSP 扩展，提供 JDT LS debug/test 集成
	"https://github.com/mfussenegger/nvim-jdtls",
	-- 补全引擎（需要 Rust toolchain 构建，或使用预编译二进制）
	{
		src = "https://github.com/saghen/blink.cmp",
		version = vim.version.range("1.*"),
	},
	-- snippet 引擎（blink.cmp 的 snippets 扩展依赖）
	"https://github.com/L3MON4D3/LuaSnip",
})

-- =============================================================================
-- 插件配置
-- =============================================================================

-- ----------------------------------------------------------------------------
-- which-key.nvim（快捷键提示）
-- ----------------------------------------------------------------------------
local wk = require("which-key")
wk.setup({
	preset = "classic",
	delay = 300,
	win = {
		border = "rounded",
	},
})

wk.add({
	{
		"<leader>?",
		function()
			wk.show({ global = false })
		end,
		desc = "Show buffer-local keymaps",
	},
	-- <leader>w / <leader>d 是立刻生效的具体键（保存 / 诊断浮窗），不注册为空 group，
	-- 以免 which-key 提示与真实行为冲突；相关二级键靠各自 desc 展示。
	{ "<leader>b", group = "buffer" },
	{ "<leader>c", group = "code" },
	{ "<leader>e", desc = "Toggle file explorer" },
	{ "<leader>f", group = "find" },
	{ "<leader>g", group = "goto" },
	{ "<leader>h", group = "git hunk" },
	{ "<leader>m", group = "markdown" },
	{ "<leader>o", group = "organize" },
	{ "<leader>p", group = "path/paste" },
	{ "<leader>q", desc = "Open diagnostic list" },
	{ "<leader>r", group = "rename/refactor" },
	{ "<leader>R", group = "rest" },
	{ "<leader>s", group = "split" },
	{ "<leader>t", desc = "Toggle floating terminal" },
	{ "<leader>u", group = "toggle ui" },
	{ "<leader>v", group = "debug" },
	{ "<leader>x", desc = "Delete without yanking" },
	{ "<leader>fm", desc = "Format buffer (manual)" },
})

-- ----------------------------------------------------------------------------
-- nvim-dap / nvim-dap-ui（Debug Adapter Protocol）
-- ----------------------------------------------------------------------------
local dap = require("dap")
local dapui = require("dapui")

dapui.setup({})

dap.listeners.before.attach.dapui_config = function()
	dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
	dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
	dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
	dapui.close()
end

vim.keymap.set("n", "<leader>vc", dap.continue, { desc = "Debug continue" })
vim.keymap.set("n", "<leader>vo", dap.step_over, { desc = "Debug step over" })
vim.keymap.set("n", "<leader>vi", dap.step_into, { desc = "Debug step into" })
vim.keymap.set("n", "<leader>vO", dap.step_out, { desc = "Debug step out" })
vim.keymap.set("n", "<leader>vq", dap.terminate, { desc = "Debug terminate" })
vim.keymap.set("n", "<leader>vb", dap.toggle_breakpoint, { desc = "Debug toggle breakpoint" })
vim.keymap.set("n", "<leader>vB", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug conditional breakpoint" })
vim.keymap.set("n", "<leader>vl", function()
	dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
end, { desc = "Debug log point" })
vim.keymap.set("n", "<leader>vr", dap.repl.open, { desc = "Debug REPL" })
vim.keymap.set("n", "<leader>vu", dapui.toggle, { desc = "Debug UI toggle" })
vim.keymap.set({ "n", "v" }, "<leader>ve", dapui.eval, { desc = "Debug eval" })

-- ----------------------------------------------------------------------------
-- nvim-tree（文件树）
-- ----------------------------------------------------------------------------
require("nvim-tree").setup({
	view = { width = 35 },
	filters = { dotfiles = false }, -- 显示隐藏文件（.env、.gitignore 等）
	renderer = { group_empty = true }, -- 将连续的空目录合并显示（如 src/components/）
})

vim.keymap.set("n", "<leader>e", function()
	require("nvim-tree.api").tree.toggle()
end, { desc = "Toggle NvimTree" })

-- nvim-tree 高亮组在 setup 后可能被重置；再套一层透明（与顶部 apply_transparent_bg 一致）
apply_transparent_bg()

-- ----------------------------------------------------------------------------
-- fzf-lua（模糊查找）
-- ----------------------------------------------------------------------------
do
	local ok, fzf_lua = pcall(require, "fzf-lua")
	if ok then
		fzf_lua.setup({})
	else
		vim.schedule(function()
			vim.notify("fzf-lua unavailable: " .. tostring(fzf_lua), vim.log.levels.WARN)
		end)
	end
end

vim.keymap.set("n", "<leader>ff", function()
	require("fzf-lua").files()
end, { desc = "FZF Files" })
vim.keymap.set("n", "<leader>fg", function()
	require("fzf-lua").live_grep()
end, { desc = "FZF Live Grep" })
vim.keymap.set("n", "<leader>fb", function()
	require("fzf-lua").buffers()
end, { desc = "FZF Buffers" })
vim.keymap.set("n", "<leader>fh", function()
	require("fzf-lua").help_tags()
end, { desc = "FZF Help Tags" })
vim.keymap.set("n", "<leader>fx", function()
	require("fzf-lua").diagnostics_document()
end, { desc = "FZF Diagnostics (buffer)" })
vim.keymap.set("n", "<leader>fX", function()
	require("fzf-lua").diagnostics_workspace()
end, { desc = "FZF Diagnostics (workspace)" })

-- ----------------------------------------------------------------------------
-- mini.nvim（各组件独立 setup，只启用实际需要的）
-- ----------------------------------------------------------------------------
require("mini.ai").setup({}) -- 增强文本对象（va(、di" 等）
require("mini.comment").setup({}) -- gcc 注释当前行，gc + motion 注释区域
-- 不用 mini.move：Terminator 占用 A-l（layout manager）；行上下移动用手写 A-j/A-k
require("mini.surround").setup({}) -- sa/sd/sr 添加/删除/替换包裹符号
require("mini.cursorword").setup({}) -- 自动高亮光标所在单词的所有出现
require("mini.indentscope").setup({}) -- 动态缩进参考线（当前代码块）
require("mini.pairs").setup({}) -- 括号/引号自动补全另一半
require("mini.trailspace").setup({}) -- 高亮行尾多余空格
require("mini.bufremove").setup({}) -- 关闭缓冲区而不关闭窗口（:bd 替代）
require("mini.notify").setup({}) -- 浮窗通知替代 vim.notify
require("mini.icons").setup({}) -- 图标支持（供 fzf-lua、nvim-tree 等使用）

-- 关闭当前 buffer，尽量不拆窗口；有未保存修改时拒绝关闭（force=false）
vim.keymap.set("n", "<leader>bd", function()
	require("mini.bufremove").delete(0, false)
end, { desc = "Delete buffer (keep window)" })

-- ----------------------------------------------------------------------------
-- render-markdown.nvim（Markdown 内联渲染）
-- ----------------------------------------------------------------------------
require("render-markdown").setup({
	completions = { lsp = { enabled = true } },
})

vim.keymap.set("n", "<leader>mr", function()
	require("render-markdown").toggle()
end, { desc = "Toggle Markdown rendering" })

-- ----------------------------------------------------------------------------
-- rest.nvim（HTTP 请求；命令为 :Rest，非旧版 <Plug>RestNvim）
-- 可选 Lua 依赖：fidget.nvim（vim.pack）、xml2lua/mimetypes（~/.luarocks）
-- ----------------------------------------------------------------------------
require("rest-nvim").setup({
	request = {
		skip_ssl_verification = false,
	},
})

vim.keymap.set("n", "<leader>Rr", "<cmd>Rest run<cr>", { desc = "Run HTTP request under cursor" })
vim.keymap.set("n", "<leader>Ro", "<cmd>Rest open<cr>", { desc = "Open rest.nvim result pane" })
vim.keymap.set("n", "<leader>Rl", "<cmd>Rest last<cr>", { desc = "Re-run last HTTP request" })

-- ----------------------------------------------------------------------------
-- gitsigns.nvim（Git 集成）
-- ----------------------------------------------------------------------------
require("gitsigns").setup({
	signs = {
		add = { text = "\u{2590}" }, -- ▐
		change = { text = "\u{2590}" },
		delete = { text = "\u{2590}" },
		topdelete = { text = "\u{25e6}" }, -- ◦
		changedelete = { text = "\u{25cf}" }, -- ●
		untracked = { text = "\u{25cb}" }, -- ○
	},
	signcolumn = true,
	current_line_blame = false, -- 行内 blame 默认关闭，<leader>hB 手动切换

	on_attach = function(bufnr)
		local gs = require("gitsigns")

		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		-- hunk 导航
		map("n", "]h", function()
			gs.nav_hunk("next")
		end, "Next git hunk")
		map("n", "[h", function()
			gs.nav_hunk("prev")
		end, "Previous git hunk")

		-- hunk 操作
		map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
		map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
		map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")

		-- blame
		map("n", "<leader>hb", function()
			gs.blame_line({ full = true })
		end, "Blame line")
		map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle inline blame")

		-- diff
		map("n", "<leader>hd", gs.diffthis, "Diff this")
	end,
})

-- ----------------------------------------------------------------------------
-- nvim-treesitter（语法高亮与结构感知）
-- ----------------------------------------------------------------------------
local function setup_treesitter()
	local treesitter = require("nvim-treesitter")
	local config = require("nvim-treesitter.config")

	treesitter.setup({})

	-- 需要安装的 parser 列表
	local ensure_installed = {
		"vim",
		"vimdoc",
		"lua",
		"bash",
		"json",
		"html",
		"css",
		"javascript",
		"typescript",
		"vue",
		"svelte",
		"markdown",
		"markdown_inline",
		"python",
		"java",
		"rust",
		"go",
		"c",
		"cpp",
		"http", -- rest.nvim 解析 .http 文件
	}

	-- 只安装尚未安装的 parser，避免重复触发编译
	local already_installed = config.get_installed()
	local parsers_to_install = {}

	for _, parser in ipairs(ensure_installed) do
		if not vim.tbl_contains(already_installed, parser) then
			table.insert(parsers_to_install, parser)
		end
	end

	if #parsers_to_install > 0 then
		treesitter.install(parsers_to_install)
	end

	-- 按 FileType 激活 treesitter 高亮和折叠
	-- 不在全局设置 foldmethod=expr，因为没有 parser 的文件类型会报错
	local group = vim.api.nvim_create_augroup("TreeSitterConfig", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		callback = function(args)
			local lang = vim.treesitter.language.get_lang(args.match)

			-- 仅在该语言的 parser 已安装时才启用，避免报错
			if lang and vim.list_contains(config.get_installed(), lang) then
				vim.treesitter.start(args.buf, lang)

				-- 折叠交给 treesitter 表达式，foldlevel=99 保持默认全部展开
				vim.wo.foldmethod = "expr"
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.wo.foldlevel = 99
			end
		end,
	})
end

setup_treesitter()

-- ----------------------------------------------------------------------------
-- mason.nvim（LSP/linter/formatter 安装管理器）
-- ----------------------------------------------------------------------------
-- mason 只负责安装二进制工具，不自动配置 LSP
-- 安装好的工具路径会自动加入 PATH，供 lspconfig 和 efm 使用
require("mason").setup({})

-- =============================================================================
-- LSP、Linting、Formatting、补全
-- =============================================================================

-- 诊断图标与显示样式
vim.diagnostic.config({
	virtual_text = { prefix = "●", spacing = 4 },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "\u{f057} ", -- nf-fa-times_circle
			[vim.diagnostic.severity.WARN] = "\u{f071} ", -- nf-fa-exclamation_triangle
			[vim.diagnostic.severity.INFO] = "\u{f05a}", -- nf-fa-info_circle
			[vim.diagnostic.severity.HINT] = "\u{ea61}", -- nf-cod-lightbulb
		},
	},
	underline = true,
	update_in_insert = false, -- 插入模式下不更新诊断（减少干扰）
	severity_sort = true, -- 按严重程度排序（Error 在最前）
	float = {
		border = "rounded",
		source = true, -- 显示诊断来源（如 "eslint"、"pyright"）
		header = "",
		prefix = "",
		focusable = false,
		style = "minimal",
	},
})

-- 为所有 LSP 浮窗（hover、signature help 等）统一添加圆角边框
-- 通过覆写 open_floating_preview 实现，比逐一配置每个 LSP 更简洁
do
	local orig = vim.lsp.util.open_floating_preview
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig(contents, syntax, opts, ...)
	end
end

-- LSP 附加回调：每当 LSP 连接到缓冲区时执行，绑定 LSP 相关快捷键
local function lsp_on_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)
	if not client then
		return
	end

	local bufnr = ev.buf
	local opts = { noremap = true, silent = true, buffer = bufnr }
	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
	end

	-- 跳转定义（fzf-lua 版本支持多结果预览，单结果直接跳转）
	map("<leader>gd", function()
		require("fzf-lua").lsp_definitions({ jump_to_single_result = true })
	end, "Go to definition")

	-- 原生跳转定义（备用，不经过 fzf）
	map("<leader>gD", vim.lsp.buf.definition, "Go to definition (native)")

	-- 在垂直分屏中打开定义（保留当前文件不跳走）
	map("<leader>gS", function()
		vim.cmd("vsplit")
		vim.lsp.buf.definition()
	end, "Go to definition in vertical split")

	-- Code action（快速修复、自动导入等）
	map("<leader>ca", vim.lsp.buf.code_action, "Code action")

	-- 重命名符号（LSP 级别，跨文件）
	map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")

	-- 诊断浮窗（line: 当前行所有诊断；cursor: 光标所在诊断）
	map("<leader>D", function()
		vim.diagnostic.open_float({ scope = "line" })
	end, "Show line diagnostics")
	map("<leader>d", function()
		vim.diagnostic.open_float({ scope = "cursor" })
	end, "Show cursor diagnostics")

	-- 跳转到下一个/上一个诊断
	map("<leader>nd", function()
		vim.diagnostic.jump({ count = 1 })
	end, "Next diagnostic")
	map("<leader>pd", function()
		vim.diagnostic.jump({ count = -1 })
	end, "Previous diagnostic")

	-- hover 文档（再次按 K 可以进入浮窗）
	map("K", vim.lsp.buf.hover, "Hover documentation")

	-- fzf-lua LSP 查找系列
	map("<leader>fr", function()
		require("fzf-lua").lsp_references()
	end, "Find references")
	map("<leader>ft", function()
		require("fzf-lua").lsp_typedefs()
	end, "Find type definitions")
	map("<leader>fs", function()
		require("fzf-lua").lsp_document_symbols()
	end, "Find document symbols")
	map("<leader>fw", function()
		require("fzf-lua").lsp_workspace_symbols()
	end, "Find workspace symbols")
	map("<leader>fi", function()
		require("fzf-lua").lsp_implementations()
	end, "Find implementations")

	-- 整理导入（如 Go 的 goimports、TS 的 organize imports）
	-- 仅在 LSP 支持 codeAction 时注册
	if client:supports_method("textDocument/codeAction", bufnr) then
		map("<leader>oi", function()
			vim.lsp.buf.code_action({
				context = { only = { "source.organizeImports" }, diagnostics = {} },
				apply = true,
				bufnr = bufnr,
			})
			-- 整理导入后延迟执行格式化，确保导入顺序稳定后再格式化
			vim.defer_fn(function()
				vim.lsp.buf.format({ bufnr = bufnr })
			end, 50)
		end, "Organize imports")
	end
end

-- 注册 LspAttach autocmd（所有 LSP 共用同一套回调）
vim.api.nvim_create_autocmd("LspAttach", { group = augroup, callback = lsp_on_attach })

-- 诊断列表快捷键（在 loclist 中查看当前缓冲区所有诊断）
vim.keymap.set("n", "<leader>q", function()
	vim.diagnostic.setloclist({ open = true })
end, { desc = "Open diagnostic list" })
vim.keymap.set("n", "<leader>dl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

-- ----------------------------------------------------------------------------
-- blink.cmp（补全引擎）
-- ----------------------------------------------------------------------------
require("blink.cmp").setup({
	keymap = {
		preset = "none", -- 不使用任何预设，完全自定义
		["<C-Space>"] = { "show", "hide" }, -- 手动触发/关闭补全菜单
		["<CR>"] = { "accept", "fallback" }, -- 确认选中项
		["<C-j>"] = { "select_next", "fallback" },
		["<C-k>"] = { "select_prev", "fallback" },
		["<Tab>"] = { "snippet_forward", "fallback" }, -- snippet 内跳到下一个占位符
		["<S-Tab>"] = { "snippet_backward", "fallback" }, -- snippet 内跳到上一个占位符
	},
	appearance = { nerd_font_variant = "mono" }, -- 使用等宽 Nerd Font 图标
	completion = {
		menu = {
			-- markdown 文件不自动弹出补全（写作时干扰较大）
			auto_show = function()
				return vim.bo.filetype ~= "markdown"
			end,
		},
	},
	sources = { default = { "lsp", "path", "buffer", "snippets" } },
	snippets = {
		-- 使用 LuaSnip 展开 snippet（blink.cmp 传入 snippet body，LuaSnip 负责渲染占位符）
		expand = function(snippet)
			require("luasnip").lsp_expand(snippet)
		end,
	},
	fuzzy = {
		implementation = "prefer_rust", -- 优先使用 Rust 实现的模糊匹配（更快）
		prebuilt_binaries = { download = true }, -- 自动下载预编译二进制
	},
})

-- ----------------------------------------------------------------------------
-- LSP 服务器配置（Neovim 0.12 新 API：vim.lsp.config + vim.lsp.enable）
-- ----------------------------------------------------------------------------

-- 为所有 LSP 注入 blink.cmp 的补全能力
-- 放在具体 LSP 配置之前，具体配置可以覆盖这里的默认值
vim.lsp.config["*"] = {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
}

-- lua_ls：Neovim 配置开发必备，告知 lua_ls `vim` 是合法全局变量
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			telemetry = { enable = false },
		},
	},
})

-- 其他 LSP 使用默认配置（能力由上面的 "*" 注入）
vim.lsp.config("pyright", {}) -- Python
vim.lsp.config("bashls", {}) -- Bash/Shell
vim.lsp.config("ts_ls", {}) -- TypeScript/JavaScript
vim.lsp.config("gopls", {}) -- Go
vim.lsp.config("clangd", {}) -- C/C++

-- ----------------------------------------------------------------------------
-- efm-langserver（统一的 linting 和 formatting 服务）
-- ----------------------------------------------------------------------------
-- efm 作为一个 LSP 服务器运行，将各种 CLI 工具（eslint_d、black 等）
-- 包装成 LSP 协议，实现统一的 format/lint 接口
do
	-- linters
	local luacheck = require("efmls-configs.linters.luacheck")
	local flake8 = require("efmls-configs.linters.flake8")
	local eslint_d = require("efmls-configs.linters.eslint_d")
	local shellcheck = require("efmls-configs.linters.shellcheck")
	local cpplint = require("efmls-configs.linters.cpplint")
	local go_revive = require("efmls-configs.linters.go_revive")

	-- formatters
	local stylua = require("efmls-configs.formatters.stylua")
	local black = require("efmls-configs.formatters.black")
	local prettier_d = require("efmls-configs.formatters.prettier_d")
	local fixjson = require("efmls-configs.formatters.fixjson")
	local shfmt = require("efmls-configs.formatters.shfmt")
	local clangfmt = require("efmls-configs.formatters.clang_format")
	local gofumpt = require("efmls-configs.formatters.gofumpt")

	vim.lsp.config("efm", {
		-- efm 需要明确声明处理哪些文件类型
		filetypes = {
			"c",
			"cpp",
			"css",
			"html",
			"go",
			"javascript",
			"javascriptreact",
			"json",
			"jsonc",
			"lua",
			"markdown",
			"python",
			"sh",
			"typescript",
			"typescriptreact",
			"vue",
			"svelte",
		},
		-- 告知 efm 支持文档格式化（否则 vim.lsp.buf.format 不会调用它）
		init_options = { documentFormatting = true },
		settings = {
			languages = {
				c = { clangfmt, cpplint },
				cpp = { clangfmt, cpplint },
				css = { prettier_d },
				go = { gofumpt, go_revive },
				html = { prettier_d },
				javascript = { eslint_d, prettier_d },
				javascriptreact = { eslint_d, prettier_d },
				json = { eslint_d, fixjson },
				jsonc = { eslint_d, fixjson },
				lua = { luacheck, stylua },
				markdown = { prettier_d },
				python = { flake8, black },
				sh = { shellcheck, shfmt },
				typescript = { eslint_d, prettier_d },
				typescriptreact = { eslint_d, prettier_d },
				vue = { eslint_d, prettier_d },
				svelte = { eslint_d, prettier_d },
			},
		},
	})
end

-- 启用所有配置好的 LSP（vim.lsp.enable 是 0.12 的新 API，替代 lspconfig 的 setup 调用）
vim.lsp.enable({
	"lua_ls",
	"pyright",
	"bashls",
	"ts_ls",
	"gopls",
	"clangd",
	"efm",
})

-- =============================================================================
-- 浮动终端
-- =============================================================================

-- 终端缓冲区专属设置
vim.api.nvim_create_autocmd("TermOpen", {
	group = augroup,
	callback = function()
		vim.opt_local.number = false -- 终端不需要行号
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no" -- 终端不需要 sign 列
	end,
})

-- 终端进程正常退出后自动关闭缓冲区（避免留下 [Process exited 0] 的残留 buffer）
vim.api.nvim_create_autocmd("TermClose", {
	group = augroup,
	callback = function()
		if vim.v.event.status == 0 then
			vim.api.nvim_buf_delete(0, {})
		end
	end,
})

-- 浮动终端状态（跨调用持久化，实现 toggle 效果）
local terminal_state = { buf = nil, win = nil, is_open = false }

local function FloatingTerminal()
	-- 如果终端窗口已打开，关闭它（toggle 行为）
	if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
		vim.api.nvim_win_close(terminal_state.win, false)
		terminal_state.is_open = false
		return
	end

	-- 复用已有的终端缓冲区（保留终端会话，不重新启动 shell）
	if not terminal_state.buf or not vim.api.nvim_buf_is_valid(terminal_state.buf) then
		terminal_state.buf = vim.api.nvim_create_buf(false, true)
		-- bufhidden=hide：窗口关闭时隐藏缓冲区而非删除，保留终端状态
		vim.bo[terminal_state.buf].bufhidden = "hide"
	end

	-- 居中浮窗，宽高各占编辑器的 80%
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	terminal_state.win = vim.api.nvim_open_win(terminal_state.buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	-- 浮窗透明背景
	vim.wo[terminal_state.win].winblend = 0
	vim.wo[terminal_state.win].winhighlight = "Normal:FloatingTermNormal,FloatBorder:FloatingTermBorder"
	vim.api.nvim_set_hl(0, "FloatingTermNormal", { bg = "none" })
	vim.api.nvim_set_hl(0, "FloatingTermBorder", { bg = "none" })

	-- 仅在缓冲区还没有终端时启动 shell（复用时跳过）
	if vim.bo[terminal_state.buf].buftype ~= "terminal" then
		vim.fn.termopen(os.getenv("SHELL"))
	end

	terminal_state.is_open = true
	vim.cmd("startinsert")

	-- 离开终端缓冲区时自动关闭浮窗（once=true 避免重复触发）
	local term_augroup = vim.api.nvim_create_augroup("FloatingTermLeave_" .. terminal_state.win, { clear = true })
	vim.api.nvim_create_autocmd("BufLeave", {
		group = term_augroup,
		buffer = terminal_state.buf,
		once = true,
		callback = function()
			if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
				vim.api.nvim_win_close(terminal_state.win, false)
				terminal_state.is_open = false
			end
		end,
	})
end

-- 浮动终端快捷键
vim.keymap.set("n", "<leader>t", FloatingTerminal, { noremap = true, silent = true, desc = "Toggle floating terminal" })

-- 终端模式下 Esc 退出到 normal 模式（而非发送 Esc 给终端进程）
-- vim.keymap.set("t", "<Esc>", "<C-\\><C-n>",
-- { noremap = true, silent = true, desc = "Terminal: exit to normal mode" })

-- 终端模式下 Ctrl+q 直接关闭浮窗
vim.keymap.set("t", "<C-q>", function()
	if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
		vim.api.nvim_win_close(terminal_state.win, false)
		terminal_state.is_open = false
	end
end, { noremap = true, silent = true, desc = "Terminal: close floating window" })
