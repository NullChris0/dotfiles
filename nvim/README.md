# Neovim 配置笔记

这份配置面向熟悉 Vim、正在把 Neovim 当轻量 IDE 使用的人。配置入口是 `.config/nvim/init.lua`，插件由 Neovim 0.12 内置的 `vim.pack` 管理，leader 和 localleader 都是空格。

界面里的很多图标来自 Nerd Font。终端字体如果不是 Nerd Font，statusline、诊断、Git 标记和补全菜单里的图标可能会显示成方块。

## 基础行为

- 行号、相对行号、当前行高亮、100 列参考线默认开启。
- 搜索忽略大小写，但搜索词包含大写时自动区分大小写。
- 分屏默认向下、向右打开。
- 系统剪贴板使用 `unnamedplus`，需要系统提供 `xclip`、`xsel` 或 `wl-clipboard`。
- 不创建 swap、backup、writebackup 文件。
- Markdown、纯文本和 Git commit 会自动开启折行、整词折行和拼写检查。
- 保存受支持文件时，如果当前 buffer 已附加 `efm`，会用 `efm` 自动格式化。

## 插件总览

| 插件 | 作用 |
| --- | --- |
| `mini.nvim` | 提供文本对象、注释、surround、括号补全、缩进线、尾随空格提示、buffer 删除、通知和图标等小组件。 |
| `nvim-tree.lua` | 文件树，使用 `<leader>e` 开关。 |
| `fzf-lua` | 文件、全文、buffer、帮助、诊断和 LSP 符号搜索。 |
| `which-key.nvim` | 按下 leader 后显示可用快捷键和分组。 |
| `gitsigns.nvim` | Git sign、hunk 导航、stage/reset/preview、blame 和 diff。 |
| `nvim-treesitter` | 语法高亮和基于语法树的折叠。 |
| `mason.nvim` | 安装 LSP、linter、formatter 等外部工具；不负责配置 LSP。 |
| `nvim-lspconfig` | 提供各语言 LSP 的默认配置来源。 |
| `efmls-configs-nvim` | 给 `efm-langserver` 提供常用 linter/formatter 配置。 |
| `blink.cmp` | 补全引擎，来源包括 LSP、路径、buffer 和 snippets。 |
| `LuaSnip` | snippet 展开引擎，供 `blink.cmp` 调用。 |

## LSP 与工具链

启用的 LSP：

| LSP | 语言 |
| --- | --- |
| `lua_ls` | Lua，已配置 `vim` 为合法全局变量。 |
| `pyright` | Python |
| `bashls` | Bash/Shell |
| `ts_ls` | TypeScript/JavaScript |
| `gopls` | Go |
| `clangd` | C/C++ |
| `jdtls` | Java，`JAVA_HOME` 指向 mise 管理的 Temurin 21。 |
| `efm` | 统一承载 linting 和 formatting。 |

`mason.nvim` 只负责安装工具，并把已安装工具加入 Neovim 可见的 `PATH`。真正启用哪些 LSP、formatter、linter 由 `vim.lsp.config`、`vim.lsp.enable` 和 `efm` 配置决定。换句话说，在 `:Mason` 里安装一个工具不会自动让它参与当前项目，仍需要在配置里启用。

`efm` 当前接入的工具：

| 类型 | 工具 |
| --- | --- |
| Linters | `luacheck`、`flake8`、`eslint_d`、`shellcheck`、`cpplint`、`revive` |
| Formatters | `stylua`、`black`、`prettier_d`、`fixjson`、`shfmt`、`clang_format`、`gofumpt` |

自动格式化只在 `efm` 已附加到当前 buffer 时运行，并且格式化请求会过滤到 `efm`，避免 TypeScript 等语言服务器抢占格式化。

## 补全

`blink.cmp` 使用完全自定义按键：

| 快捷键 | 作用 |
| --- | --- |
| `<C-Space>` | 手动打开或关闭补全菜单 |
| `<CR>` | 接受当前补全项 |
| `<C-j>` / `<C-k>` | 选择下一个/上一个补全项 |
| `<Tab>` / `<S-Tab>` | 在 snippet 占位符间前进/后退 |

Markdown 文件不会自动弹出补全菜单，避免写作时过度打扰；仍可用 `<C-Space>` 手动触发。

## IDE 工作流速查

| 场景 | 快捷键 |
| --- | --- |
| 打开文件树 | `<leader>e` |
| 找文件 | `<leader>ff` |
| 全文搜索 | `<leader>fg` |
| 切换 buffer | `<leader>fb` 或 `<leader>bn` / `<leader>bp` |
| 跳转定义 | `<leader>gd` |
| 在垂直分屏中看定义 | `<leader>gS` |
| 找引用 | `<leader>fr` |
| 找文档符号 | `<leader>fs` |
| 找工作区符号 | `<leader>fw` |
| 查看当前诊断 | `<leader>d` 或 `<leader>D` |
| 打开当前 buffer 诊断列表 | `<leader>q` |
| code action | `<leader>ca` |
| rename | `<leader>rn` |
| organize imports | `<leader>oi` |
| 保存 | `<leader>w` |
| Git hunk 预览 | `<leader>hp` |
| 打开浮动终端 | `<leader>t` |

## 快捷键速查

### Buffer

| 快捷键 | 作用 |
| --- | --- |
| `<leader>bn` | 下一个 buffer |
| `<leader>bp` | 上一个 buffer |
| `<leader>fb` | 用 fzf-lua 列出 buffers |

### Find

| 快捷键 | 作用 |
| --- | --- |
| `<leader>ff` | 查找文件 |
| `<leader>fg` | 全文搜索 |
| `<leader>fh` | 查找帮助标签 |
| `<leader>fx` | 当前 buffer 诊断 |
| `<leader>fX` | 工作区诊断 |
| `<leader>fr` | LSP 引用 |
| `<leader>ft` | LSP 类型定义 |
| `<leader>fs` | LSP 文档符号 |
| `<leader>fw` | LSP 工作区符号 |
| `<leader>fi` | LSP 实现 |

### Goto

| 快捷键 | 作用 |
| --- | --- |
| `<leader>gd` | 跳转定义，优先使用 fzf-lua |
| `<leader>gD` | 原生 LSP 跳转定义 |
| `<leader>gS` | 垂直分屏后跳转定义 |
| `K` | Hover 文档 |

### Diagnostics

| 快捷键 | 作用 |
| --- | --- |
| `<leader>d` | 光标所在诊断浮窗 |
| `<leader>D` | 当前行诊断浮窗 |
| `<leader>dl` | 诊断浮窗 |
| `<leader>nd` | 下一个诊断 |
| `<leader>pd` | 上一个诊断 |
| `<leader>q` | 打开 loclist 诊断列表 |

### Code

| 快捷键 | 作用 |
| --- | --- |
| `<leader>ca` | Code action |
| `<leader>rn` | LSP rename |
| `<leader>oi` | Organize imports，然后延迟格式化 |

### Git Hunk

| 快捷键 | 作用 |
| --- | --- |
| `]h` | 下一个 hunk |
| `[h` | 上一个 hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | 当前行 blame |
| `<leader>hB` | 切换行内 blame |
| `<leader>hd` | Diff this |

### Path / Paste

| 快捷键 | 作用 |
| --- | --- |
| `<leader>pa` | 复制当前文件完整路径 |
| `<leader>p` | Visual 模式粘贴但不覆盖寄存器 |
| `<leader>x` | 删除但不覆盖寄存器 |

### Split / Window

| 快捷键 | 作用 |
| --- | --- |
| `<leader>sv` | 垂直分屏 |
| `<leader>sh` | 水平分屏 |
| `<C-Up>` / `<C-Down>` | 增加/减少窗口高度 |
| `<C-Left>` / `<C-Right>` | 减少/增加窗口宽度 |
| `<leader>w` | 保存当前文件 |
| `<leader>wq` | 关闭当前窗口 |

### Terminal

| 快捷键 | 作用 |
| --- | --- |
| `<leader>t` | 开关浮动终端 |
| 终端模式 `<Esc>` | 回到 terminal-normal 模式 |
| 终端模式 `<C-q>` | 关闭浮动终端窗口 |

### Editing Quality-of-Life

| 快捷键 | 作用 |
| --- | --- |
| `<Esc>` | 清除搜索高亮 |
| `n` / `N` | 下一个/上一个搜索结果并居中 |
| `<C-d>` / `<C-u>` | 半页下/上并居中 |
| `j` / `k` | 无计数时按视觉行移动，有计数时按真实行移动 |
| `J` | 合并行并保持光标位置 |
| Visual `<` / `>` | 缩进后保持选区 |
| `<A-j>` / `<A-k>` | 移动当前行或选区 |

