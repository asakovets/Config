local Mono = { }

local function theme_apply (colors)

    if colors.default then
        vim.api.nvim_set_hl (0, "@variable", colors.default)
        vim.api.nvim_set_hl (0, "Special", colors.default)
        vim.api.nvim_set_hl (0, "Function", colors.default)
        vim.api.nvim_set_hl (0, "Statement", colors.default)
        vim.api.nvim_set_hl (0, "Identifier", colors.default)
        vim.api.nvim_set_hl (0, "Constant", colors.default)
        vim.api.nvim_set_hl (0, "Delimiter", colors.default)
        vim.api.nvim_set_hl (0, "PreProc", colors.default)
        vim.api.nvim_set_hl (0, "@keyword.directive",
            vim.tbl_extend ("keep", colors.default, { bold = false }))

        vim.api.nvim_set_hl (0, "Type", colors.default)
        vim.api.nvim_set_hl (0, "Operator", colors.default)
    end

    if colors.comment then
        vim.api.nvim_set_hl (0, "Comment", colors.comment)
    end

    if colors.string then
        vim.api.nvim_set_hl (0, "String", colors.string)
    end

    if colors.background then
        vim.api.nvim_set_hl (0, "Normal", colors.background)
    end
end

function Mono.light ()

    local colors = { }

    colors.default = {
        fg = "Black",
        bold = false,
    }

    if not vim.g.isatty then
        colors.background = {
            bg = "#e3e4d0",
            -- bg = "#fdfbd4",
        }
    end

    theme_apply (colors)
end

function Mono.dark ()

    local colors = { }

    colors.default = {
        fg = "White",
        bold = false,
    }

    theme_apply (colors)
end

return Mono
