local M = { }

function M.get_root ()
    local clients = vim.lsp.get_clients ({ bufnr = 0 })
    for _, client in pairs (clients) do
        if client.root_dir then
            return client.root_dir
        end
    end
    return vim.fs.root (M.bufdir (0), {
        '.git', 
        '.hg', 
        '.projectile',
        'nvim',
    })
end

function M.bufdir (bufnr)
    local t = {
        oil = require "oil".get_current_dir,
    }

    local ft = vim.bo [bufnr].filetype

    if t [ft] then
        return t [ft] (bufnr)
    end

    return vim.fn.fnamemodify (vim.api.nvim_buf_get_name (bufnr), ":h")

end

function M.find_files (opts)
    if vim.loop.os_uname ().sysname == "Windows_NT" then
        opts.cwd = opts.cwd:gsub ("/", "\\")
    end
    require ("telescope.builtin").find_files (opts)
end

local function oil (dir)
    require ("oil").open (dir, nil, nil)
end

function M.openfm ()
    M.openfm_at (nil)
end

function M.openfm_at (dir)
    oil (dir)
end

return M
