require ("telescope").setup {
    defaults = {
        mappings = {
            i = {
                ['<M-n>'] = require("telescope.actions").insert_original_cword,
                ['<M-N>'] = require("telescope.actions").insert_original_cWORD,
            }
        },

        path_display = {
            "filename_first"
        },
    },

    pickers = {
        find_files = {
            hidden = true,
        }
    }
}

vim.keymap.set ("n", "<leader>ep", function ()
    -- require ("telescope.builtin").find_files {
    --     cwd = vim.fs.joinpath (vim.fn.stdpath ("data"), "lazy")
    -- }
    require ("util").find_files ({
        cwd = vim.fs.joinpath (vim.fn.stdpath ("data"), "lazy")
    })
end)

require("nvim-treesitter.configs").setup({
    -- A list of parser names, or "all"
    ensure_installed = {
        "c", "lua", "cpp", "groovy", "java", "kotlin", "python"
    },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don"t have `tree-sitter` CLI installed locally
    auto_install = false,

    indent = {
        enable = true,
        disable = { "cpp", "c" },
    },

    highlight = {
        -- `false` will disable the whole extension
        enable = true,
        disable = 
            function(lang, buf)
                if lang == "html" then
                    print("disabled")
                    return true
                end

                local max_filesize = 100 * 1024 -- 100 KB
                local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                if ok and stats and stats.size > max_filesize then
                    vim.notify(
                        "File larger than 100KB treesitter disabled for performance",
                        vim.log.levels.WARN,
                        {title = "Treesitter"}
                    )
                    return true
                end
            end,
    },

    textobjects = {
        lsp_interop = {
            enable = true,
            border = 'none',
            floating_preview_opts = {},
            peek_definition_code = {
                ["<leader>df"] = "@function.outer",
                ["<leader>dF"] = "@class.outer",
            },
        },
    }

})

-- local moveline = require ('moveline')
-- vim.keymap.set('n', '<M-k>', moveline.up)
-- vim.keymap.set('n', '<M-j>', moveline.down)
-- vim.keymap.set('v', '<M-j>', moveline.block_down)
-- vim.keymap.set('v', '<M-k>', moveline.block_up)

local cmp = require "cmp"
cmp.setup {
    sources = {
        { name = "nvim_lsp", },
        { name = "path", },
    },

    completion = {
        -- autocomplete = false,
    },

    mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item (),
        ['<C-n>'] = cmp.mapping.select_next_item (),
        ['<C-d>'] = cmp.mapping.scroll_docs (-4),
        ['<C-f>'] = cmp.mapping.scroll_docs (4),
        ['<C-Space>'] = cmp.mapping.complete (),
        ['<C-e>'] = cmp.mapping.abort (),
        ['<Tab>'] = cmp.mapping.confirm ({
            behavior = cmp.ConfirmBehavior.Insert,
            select = true
        }),
    }
}


local servers = {
    'clangd',
    -- 'pyright',
}

vim.lsp.config ("*", {
    capabilities = require('cmp_nvim_lsp').default_capabilities()
});

vim.lsp.config ("clangd", {
    cmd = { "clangd", "--function-arg-placeholders=0" }
});

for _, lsp in ipairs (servers) do
    vim.lsp.enable (lsp)
end

vim.api.nvim_create_autocmd ('LspAttach', {
    callback = function(e)
        local opts = { buffer = e.buf }

        vim.bo [e.buf].formatexpr = nil
        vim.bo [e.buf].omnifunc = nil

        local client = vim.lsp.get_client_by_id(e.data.client_id)
        if client.server_capabilities.signatureHelpProvider then
            -- require('lsp-overloads').setup(client, { })
        end

        vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<cr>", opts)
        vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end, opts)
        vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
        vim.keymap.set("n", "<leader>lc", function() vim.lsp.buf.code_action() end, opts)
        vim.keymap.set("n", "<leader>lrr", "<cmd>Telescope lsp_references<cr>", opts)
        vim.keymap.set("n", "<leader>ls", "<cmd>LspClangdSwitchSourceHeader<cr>", opts)
        vim.keymap.set("n", "<leader>li", "<cmd>Telescope lsp_implementations<cr>", opts)
        vim.keymap.set("n", "<leader>lrn", function() vim.lsp.buf.rename() end, opts)
        vim.keymap.set("n", "<leader>=", function() vim.lsp.buf.format() end, opts)
        vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostic.goto_next() end, opts)
        vim.keymap.set("n", "[d", function() vim.diagnostic.goto_prev() end, opts)
        -- vim.keymap.set("n", '<space>e', function () vim.lsp.diagnostic.show_line_diagnostics () end, opts) 
    end
})

require('gitsigns').setup {
    sign_priority = 1,
    current_line_blame_formatter = '<author>, <author_time:%R> - <summary> (<abbrev_sha>)',

    on_attach = function(bufnr)
        local gitsigns = require('gitsigns')

        local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
            if vim.wo.diff then
                vim.cmd.normal({']c', bang = true})
            else
                gitsigns.nav_hunk('next')
            end
        end)

        map('n', '[c', function()
            if vim.wo.diff then
                vim.cmd.normal({'[c', bang = true})
            else
                gitsigns.nav_hunk('prev')
            end
        end)

        -- Actions
        map('n', '<leader>hs', gitsigns.stage_hunk)
        map('n', '<leader>hu', gitsigns.undo_stage_hunk)
        map('n', '<leader>hr', gitsigns.reset_hunk)
        map('v', '<leader>hs', function() gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end)
        map('v', '<leader>hr', function() gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end)
        map('n', '<leader>hS', gitsigns.stage_buffer)
        map('n', '<leader>hR', gitsigns.reset_buffer)
        map('n', '<leader>hp', gitsigns.preview_hunk)
        map('n', '<leader>hi', gitsigns.preview_hunk_inline)
        map('n', '<leader>hb', function() gitsigns.blame_line({ full = true }) end)
        map('n', '<leader>hd', gitsigns.diffthis)
        map('n', '<leader>hD', function() gitsigns.diffthis('~') end)
        map('n', '<leader>hQ', function() gitsigns.setqflist('all') end)
        map('n', '<leader>hq', gitsigns.setqflist)
        -- Toggles
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame)
        -- map('n', '<leader>tw', gitsigns.toggle_word_diff)
        -- Text object
        map({'o', 'x'}, 'ih', gitsigns.select_hunk)
    end
}

require ("oil").setup {
    default_file_explorer = true,
    columns = { "size" },
    delete_to_trash = true,
    view_options = {
        show_hidden = true,
    }
}

require ("flit").setup {}
require ("leap").set_default_mappings ()

local harpoon = require ("harpoon")
harpoon:setup ()
-- <leader>h (harpoon)
nmap("<leader>ha", function() harpoon:list ():add() end)
nmap("<leader>he", function () harpoon.ui:toggle_quick_menu(harpoon:list()) end )
nmap("<leader>1", function() harpoon:list ():select (1) end, 'Harpoon 1')
nmap("<leader>2", function() harpoon:list ():select (2) end, 'Harpoon 2')
nmap("<leader>3", function() harpoon:list ():select (3) end, 'Harpoon 3')
nmap("<leader>4", function() harpoon:list ():select (4) end, 'Harpoon 4')
nmap("<leader>5", function() harpoon:list ():select (5) end, 'Harpoon 5')
nmap("<leader>6", function() harpoon:list ():select (6) end, 'Harpoon 6')

require ('mini.surround').setup ({
    mappings = {
        add = "<leader>sa", -- Add surrounding in Normal and Visual modes
        delete = "<leader>sd", -- Delete surrounding
        find = "<leader>sf", -- Find surrounding (to the right)
        find_left = "<leader>sF", -- Find surrounding (to the left)
        highlight = "<leader>sh", -- Highlight surrounding
        replace = "<leader>sr", -- Replace surrounding
        update_n_lines = "<leader>sn", -- Update `n_lines`
    },
})
