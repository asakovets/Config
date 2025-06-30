local cmd = vim.cmd
local o = vim.o
local opt = vim.opt

vim.g.mapleader = " "

o.nu = true
o.relativenumber = true

o.tabstop = 4
o.softtabstop = 4
o.shiftwidth = 4
o.expandtab = true

o.smartindent = true
o.wrap = false

o.swapfile = false
o.backup = false

o.hlsearch = true
o.incsearch = true
o.ignorecase = true
o.smartcase = true
opt.wildignorecase = true

o.termguicolors = true
o.scrolloff = 8

o.signcolumn = "yes"

vim.g.cmptoggle = true
-- vim.opt.formatoptions:remove "o"

if vim.g.neovide then
    vim.g.neovide_opacity = 0.95
    vim.g.neovide_background_color = "#eeeeee"
    vim.g.neovide_theme = 'light'
    vim.g.neovide_position_animation_length = 0
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_trail_size = 0
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_scroll_animation_far_lines = 0
    vim.g.neovide_scroll_animation_length = 0
end


o.list = true
vim.opt.listchars = {
    space = '·',
    tab = '» ',
    trail = '·',
    lead = '·',
    nbsp = '␣',
}

local lazypath = vim.fn.stdpath ('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat (lazypath) then
    vim.fn.system ({'git', 'clone', '--filter=blob:none', 'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath})
end
vim.opt.rtp:prepend(lazypath)

require ("lazy").setup {

    spec = {
        -- {
        --     'willothy/moveline.nvim',
        --     build = "make"
        -- },
        {
            'nvim-telescope/telescope.nvim',
            dependencies = {
                'nvim-lua/plenary.nvim'
            }
        },
        {
            'nvim-treesitter/nvim-treesitter',
            build = ":TSUpdate"
        },
        'nvim-treesitter/nvim-treesitter-textobjects',
        'nvim-treesitter/playground',
        'neovim/nvim-lspconfig',
        {
            'lewis6991/gitsigns.nvim',
            -- dir = "~/plugins/gitsigns.nvim/",
            -- dev = false,
        },
        'stevearc/oil.nvim',
        'ggandor/leap.nvim',
        'ggandor/flit.nvim',
        {
            'hrsh7th/nvim-cmp',
            dependencies = {
                'hrsh7th/cmp-buffer',
                'hrsh7th/cmp-nvim-lsp',
                "hrsh7th/cmp-path",
            }
        },

        {
            "ThePrimeagen/harpoon",
            branch = "harpoon2",
            dependencies = { "nvim-lua/plenary.nvim" }
        },

        {'echasnovski/mini.ai', config = true},
        {'echasnovski/mini.pairs', config = true},
        {'echasnovski/mini.surround' },
        { "Issafalcon/lsp-overloads.nvim" },
        "tpope/vim-fugitive",
    }
}

-- Mappings
function map(mode, lhs, rhs, opts)
    local options = { }
    if opts then
        if type (opts) == "string" then
            opts = { desc = opts }
        end
        options = vim.tbl_extend('force', options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
end

function nmap(lhs, rhs, opts)
    map('n', lhs, rhs, opts)
end

function tmap(lhs, rhs, opts)
    map('t', lhs, rhs, opts)
end

function vmap(lhs, rhs, opts)
    map('v', lhs, rhs, opts)
end

local function grep (opts)
    require ("multigrep").live_multigrep (opts)
end

nmap('n', 'nzz')
nmap('N', 'Nzz')
nmap('<Tab>', '%')
vmap('<Tab>', '%')


nmap('<esc>', ':noh<cr><esc>')
-- <leader>
nmap('<leader><space>', require('telescope.builtin').buffers, '[ ] Find existing buffers')
nmap('<leader>`', '<cmd>b#<cr>', 'Switch to alternate buffer')
nmap('<leader>c', function () vim.api.nvim_feedkeys ('gcc', 'v', false) end, 'Toggle comment line')
vmap('<leader>c', function () vim.api.nvim_feedkeys ('gc', 'v', false) end, 'Toggle comment line')

-- <leader>b (buffer)
nmap('<leader>bn', '<cmd>bn<cr>', 'Next buffer')
nmap('<leader>bp', '<cmd>bp<cr>', 'Previous buffer')
nmap('<leader>bN', '<cmd>new<cr>', 'New empty buffer')
nmap('<leader>bk', ':bd<cr>', 'Kill buffer')

-- <leader>f (find & file)
nmap('<leader>f\'', '<cmd>Telescope marks<cr>')
nmap('<leader>f<cr>', '<cmd>Telescope resume<cr>')
nmap('<leader>fc', '<cmd>e $MYVIMRC<cr>')
nmap('<leader>ff', function () grep ({cwd = myproject ()}) end )
nmap('<leader>fg', '<cmd>Telescope git_files<cr>')
nmap('<leader>fs', '<cmd>:w<cr>', 'Save file' )
nmap('<leader>fm', '<cmd>lua require("util").openfm()<cr>', 'Open file manager')

nmap('<leader>fr', '<cmd>Telescope oldfiles<cr>')
--

nmap('<leader>o', 'o<esc>')
nmap('<leader>O', 'O<esc>')

-- <leader>p (project)
nmap('<leader>pf', function ()
    local myproj = myproject ()
    if myproj then
        require ("telescope.builtin").find_files ({
            cwd = myproj,
            hidden = true,
            find_command = { "rg", "--files", "--hidden", "--color", "never", "--glob", "!**/.git/*" },
        })
    end
end, {silent=true, desc='Find file in project'})

-- <leader>q (quit)
nmap('<leader>qq', '<cmd>quit<cr>')

nmap('<leader>gd', function () grep ({cwd=require ("util").bufdir(0)}) end, 'Search directory')
nmap('<leader>gs', ":tab Git <cr>")

nmap('<leader>pr', function () require ("util").openfm_at (myproject ()) end )

-- <leader>s (search)
-- nmap('<leader>sh', '<cmd>Telescope help_tags<cr>')
nmap('<leader>si', '<cmd>Telescope lsp_document_symbols<cr>')
nmap('<leader>sk', '<cmd>Telescope keymaps<cr>')
nmap('<leader>ss', '<cmd>Telescope current_buffer_fuzzy_find<cr>', 'Search buffer')

-- <leader>t (toggle & terminal & tab)
nmap('<leader>tn', '<cmd>set number!<cr>')
nmap('<leader>ts', '<cmd>set spell!<cr>')
nmap('<leader>tw', '<cmd>set wrap!<cr>')
nmap('<leader>tk', ':tabclose<cr>', "Kill tab")

-- u (inspect)
nmap('<leader>ui', '<cmd>Inspect<cr>')
nmap('<leader>uI', '<cmd>InspectTree<cr>')

nmap('<leader>pp', '"+p')
vmap('<leader>yy', '"+y')


-- w (window)
nmap('<leader>wo', '<C-w>o')
nmap('<leader>ws', '<C-w>s')
nmap('<leader>wv', '<C-w>v')
nmap('<leader>wh', '<C-w>h')
nmap('<leader>wl', '<C-w>l')
nmap('<leader>wj', '<C-w>j')
nmap('<leader>wk', '<C-w>k')
nmap('<leader>wc', '<C-w>c')
nmap('<leader>ww', '<C-w>w')
nmap('<leader>wt', '<C-w>T')
nmap('<leader>w=', '<C-w>=')


--

vim.diagnostic.config {
    signs = false,
}

function myproject()
    local u = require "util"
    return u.get_root() or u.bufdir (0)
end

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local yankgrp = augroup ("yankgrp", {})

autocmd('TextYankPost', {
    group = yankgrp,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 100,
        })
    end,
})

vim.api.nvim_create_user_command("DeleteTrailingWhitespace",
    function ()
        local view = vim.fn.winsaveview ()
        -- Remove trailing whitespace
        vim.cmd([[%s/\s\+$//e]])

        -- Remove trailing newlines
        vim.cmd([[%s/\n\+\%$//e]])
        vim.fn.winrestview (view)
    end , {})

require ("plugins")
local _, _ = pcall (require, "local_custom")
