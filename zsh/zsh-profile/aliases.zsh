#!/bin/env zsh

alias cpy='xclip -selection clipboard'
alias pst='xclip -selection clipboard -o'
alias nv='nvim'
alias cl='clear'
alias t='tmux'
alias his='history | tail -n 20'
alias tss='tmuxss.sh'
alias tat='tmuxat.sh'
alias wlp='wallpaper.sh'
alias lsg='ls -la | grep'
alias spc='sudo pacman'
alias sps='sudo pacman -S'
alias spu='sudo pacman -Syyu'
alias ggc='git diff | fabric --model models/gemini-1.5-pro --pattern create_git_diff_commit'
alias get_idf='. $HOME/dev/esp/esp-idf/export.sh'
alias lg='lazygit'
alias fbf='fzf --preview "cat {}"'
alias cat='bat --color=always --theme=gruvbox-dark'
alias gg='_git_global'
