if status is-interactive
    # Commands to run in interactive sessions can go here
end

if type --query mise
    mise activate fish | source
end

set -x EDITOR nvim

alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../../'

alias	o "xdg-open"
alias	cls "clear"

abbr --add --position anywhere L '| less'
abbr --add re-ne --set-cursor 'readelf --all % | rg NEEDED'
abbr --add re-rp --set-cursor 'readelf --all % | rg "RUNPATH|RPATH"'

alias ob objdump
alias re readelf
alias ni ninja

alias +x 'chmod +x'
alias psg 'ps aux | rg'

abbr py python

if test -f ~/.config/fish/local.fish
    source ~/.config/fish/local.fish
end

