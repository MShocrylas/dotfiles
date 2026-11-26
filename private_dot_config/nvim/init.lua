vim.g.mapleader = " "
vim.g.maplocalleader = " "

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------
local o = vim.o
o.number = true
o.relativenumber = true
o.mouse = "a"
o.showmode = false
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.signcolumn = "yes"
o.updatetime = 250
o.splitright = true
o.splitbelow = true
o.scrolloff = 8
o.cursorline = true
o.termguicolors = true
o.expandtab = true
o.shiftwidth = 2
o.softtabstop = -1
o.tabstop = 2
o.breakindent = true
o.completeopt = "menu,menuone,noselect,popup"
o.timeoutlen = 500
o.inccommand = "split"
o.confirm = true
o.winborder = "rounded"
o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
-- Over SSH there is no usable X display (xclip fails), so copy via OSC 52 instead.
-- Paste reads the unnamed register, since terminals/tmux often don't answer OSC 52 paste queries.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste_from_register()
    return vim.split(vim.fn.getreg('"'), "\n")
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste_from_register, ["*"] = paste_from_register },
  }
end
-- Deferred: clipboard provider lookup is slow at startup
vim.schedule(function()
  o.clipboard = "unnamedplus"
end)


--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic location list" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
map("n", "0", function()
  local col = vim.fn.col(".")
  vim.cmd("normal! ^")
  if col == vim.fn.col(".") then
    vim.cmd("normal! 0")
  end
end, { silent = true, desc = "Go to first non-blank character of the line, if already there, go to column 0" })
map("n", "<leader>gp", "<cmd>let @+ = expand('%:p')<CR>", { desc = "Copy current file path to clipboard" })

-- Auto closing: <Tab> after an opener inserts its closer, <CR> after "{" opens a block.
-- Mapped on <Tab>/<CR> (no prefix) so timeoutlen doesn't cut them off.
local closers = { ['"'] = '"', ["'"] = "'", ["("] = ")", ["["] = "]", ["{"] = "}" }
map("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<Tab>" end
  -- Overriding <Tab> replaces Neovim's default snippet-jump mapping, so redo it here
  if vim.snippet.active({ direction = 1 }) then
    vim.schedule(function() vim.snippet.jump(1) end)
    return ""
  end
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local prev = vim.api.nvim_get_current_line():sub(col, col)
  local close = closers[prev]
  return close and (close .. "<Left>") or "<Tab>"
end, { expr = true, desc = "Close bracket/quote after opener, else snippet jump / Tab" })

map("i", "<CR>", function()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = vim.api.nvim_get_current_line():sub(1, col)
  if before:sub(-2) == "{;" then return "<BS><CR>};<Esc>O" end
  if before:sub(-1) == "{" then return "<CR>}<Esc>O" end
  return "<CR>"
end, { expr = true, desc = "Close curly brace on a new line" })

-- Previous version: prefix mappings, which only work within timeoutlen. Swap back by
-- deleting the block above and uncommenting these.
-- map("i", '"<tab>', '""<Left>', { desc = "Close double quote" })
-- map("i", "'<tab>", "''<Left>", { desc = "Close single quote" })
-- map("i", "(<tab>", "()<Left>", { desc = "Close parenthesis" })
-- map("i", "[<tab>", "[]<Left>", { desc = "Close square bracket" })
-- map("i", "{<tab>", "{}<Left>", { desc = "Close curly brace" })
-- map("i", "{<CR>", "{<CR>}<ESC>O", { desc = "Close curly brace on a new line" })
-- map("i", "{;<CR>", "{<CR>};<ESC>O", { desc = "Close curly brace on a new line with semicolon after it" })

--------------------------------------------------------------------------------
-- Autocommands
--------------------------------------------------------------------------------
local aug = vim.api.nvim_create_augroup("user", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = aug,
  callback = function()
    vim.hl.on_yank()
  end,
})

--------------------------------------------------------------------------------
-- Plugins
--------------------------------------------------------------------------------
-- Run :TSUpdate after treesitter is installed or updated.
-- Must be defined BEFORE vim.pack.add()
vim.api.nvim_create_autocmd("PackChanged", {
  group = aug,
  callback = function(ev)
    local d = ev.data
    if d.spec.name == "nvim-treesitter" and (d.kind == "install" or d.kind == "update") then
      if not d.active then vim.cmd.packadd("nvim-treesitter") end
      vim.cmd("TSUpdate")
    end
  end,
})

vim.pack.add({
  "https://github.com/rebelot/kanagawa.nvim",
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/neovim/nvim-lspconfig", -- only supplies server configs
  "https://github.com/mason-org/mason.nvim",  -- installs server binaries
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  "https://github.com/nvim-treesitter/nvim-treesitter-context",
})

-- Update plugins with :lua vim.pack.update()


--------------------------------------------------------------------------------
-- Colorscheme
--------------------------------------------------------------------------------
vim.cmd.colorscheme("kanagawa")

--------------------------------------------------------------------------------
-- mini.nvim modules
--------------------------------------------------------------------------------

local miniicons = require("mini.icons")
miniicons.setup()
miniicons.mock_nvim_web_devicons()

local minifiles = require("mini.files")
minifiles.setup({
  windows = {
    preview = true,
    width_preview = 50,
  },
})
map("n", "\\", function()
  -- Toggle: inside the explorer the buffer name isn't a real path, so close instead
  if not minifiles.close() then
    -- Non-file buffers (term://, help, unnamed) have no valid path; fall back to cwd
    local path = vim.api.nvim_buf_get_name(0)
    minifiles.open(vim.uv.fs_stat(path) and path or nil, false)
  end
end, { desc = "File explorer" })

require("mini.ai").setup() -- TODO: read up on the functionality of this more, then delete this comment
-- For mini.surround
map({ "n", "x" }, "s", "<Nop>")
require("mini.surround").setup() -- TODO: read up on the functionality of this more, then delete this comment
require("mini.git").setup()      -- TODO: read up on the functionality of this more, then delete this comment
require("mini.statusline").setup()

-- mini.clue: shows available keys after a prefix (which-key equivalent)
local miniclue = require("mini.clue")
miniclue.setup({
  triggers = {
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },
    { mode = "n", keys = "s" },
    { mode = "x", keys = "s" },
    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },
    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
    { mode = "n", keys = "<C-w>" },
    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "n", keys = "\"" },
    { mode = "x", keys = "\"" },
    { mode = "i", keys = "<C-r>" },
    { mode = "c", keys = "<C-r>" },
    { mode = "i", keys = "<C-x>" },
  },
  clues = {
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
    { mode = "n", keys = "<Leader>s", desc = "+Search" },
    { mode = "n", keys = "<Leader>h", desc = "+Git hunks" },
    { mode = "n", keys = "<Leader>c", desc = "+Code" },
    { mode = "n", keys = "<Leader>g", desc = "+Misc" },
  },
  window = {
    delay = 300,
    config = { width = "auto" },
  },
})
--------------------------------------------------------------------------------
-- fzf-lua
--------------------------------------------------------------------------------
local fzf = require("fzf-lua")
fzf.setup({
  defaults = { formatter = "path.filename_first" }, -- show "file  dir/" so truncation hits the directory
  winopts = {
    width = 0.95,
    preview = {
      layout = "flex",
      flip_columns = 120,
    }
  }
})
fzf.register_ui_select()

map("n", "<leader>sf", fzf.files, { desc = "Find files" })
map("n", "<leader>sg", fzf.live_grep, { desc = "Live grep" })
map("n", "<leader><leader>", fzf.buffers, { desc = "Buffers" })
map("n", "<leader>sr", fzf.resume, { desc = "Resume last picker" })
-- TODO: Review if these are useful, and if there are other available pickers that would be useful
map("n", "<leader>sh", fzf.helptags, { desc = "Help" })
map("n", "<leader>sd", fzf.diagnostics_document, { desc = "Diagnostics" })

--------------------------------------------------------------------------------
-- Git (gitsigns, inline blame, hunks)
--------------------------------------------------------------------------------
local gs = require("gitsigns")
gs.setup({
  current_line_blame = true,
  current_line_blame_opts = { delay = 500 },
})

map("n", "]h", function() gs.nav_hunk("next") end, { desc = "Next hunk" })
map("n", "[h", function() gs.nav_hunk("prev") end, { desc = "Prev hunk" })
map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Stage hunk" })
map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
map("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Reset hunk" })
map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })

--------------------------------------------------------------------------------
-- Treesitter (main branch: needs the tree-sitter CLI and a C compiler)
--------------------------------------------------------------------------------
require("nvim-treesitter").install({
  "c", "cpp", "cmake", "python", "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml", "markdown", "go"
})
vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  callback = function(ev) pcall(vim.treesitter.start, ev.buf) end,
})

-- Pins the enclosing function/class signature at the top of the window when it scrolls off screen
local ts = require("treesitter-context")
ts.setup({
  trim_scope = "inner", -- when context is too long, drop the outermost scopes first
  mode = "topline",     -- compute context from the top visible line, not the cursor line
})
-- Underline the last context row (text and line number) to separate it from the code below
vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = "Grey" })
vim.api.nvim_set_hl(0, "TreesitterContextLineNumberBottom", { underline = true, sp = "Grey" })

map("n", "[c", function() ts.go_to_context(vim.v.count1) end, { desc = "Jump to context" })

--------------------------------------------------------------------------------
-- LSP (native). Mason only installs binaries; it configures nothing.
-- Add a language:  :MasonInstall <mason-package>, then add its lspconfig name below
-- (names can differ, e.g. package "lua-language-server" -> server "lua_ls")
--------------------------------------------------------------------------------
require("mason").setup() -- must run before vim.lsp.enable

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
    },
  },
})
vim.lsp.enable({ "clangd", "basedpyright", "lua_ls", "sqruff", "gopls" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = aug,
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    local function lmap(lhs, rhs, desc)
      map("n", lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    -- Built-in defaults: K hover, grn rename, gra code action, grr references,
    -- gri implementation, gO symbols, <C-S> signature help (insert).
    lmap("gd", vim.lsp.buf.definition, "Go to definition")
    lmap("<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format")

    -- jump between header and source
    -- clangd extension, not in Neovim's list of standard LSP methods
    ---@diagnostic disable-next-line: param-type-mismatch
    if client:supports_method("textDocument/switchSourceHeader") then
      lmap("<leader>gh", function()
        local params = vim.lsp.util.make_text_document_params(ev.buf)
        ---@diagnostic disable-next-line: param-type-mismatch
        client:request("textDocument/switchSourceHeader", params, function(err, result)
          if err or not result then
            vim.notify("No corresponding header/source found")
            return
          end
          vim.cmd.edit(vim.uri_to_fname(result))
        end, ev.buf)
      end, "Switch header/source")
    end

    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
      map("i", "<C-Space>", function() vim.lsp.completion.get() end, { buffer = ev.buf })
    end

    if not client:supports_method("textDocument/willSaveWaitUntil") and client:supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = aug,
        buffer = ev.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = ev.buf, id = client.id, timeout_ms = 1500 })
        end,
      })
    end
  end,
})

vim.diagnostic.config({ severity_sort = true, virtual_lines = { current_line = true }, virtual_text = { current_line = false } })
