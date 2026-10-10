# Blue Ocean Bash prompt. Sourced from ~/.bashrc only in an interactive shell.
case $- in *i*) ;; *) return ;; esac

blue_ocean_branch() {
    local branch
    branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || return 0
    printf '  [git:%s]' "$branch"
}

PS1='\[\e[38;5;38m\]╭─\[\e[38;5;117m\]\u\[\e[38;5;74m\]@\h  \[\e[1;38;5;255m\]\W\[\e[0m\]$(blue_ocean_branch)\n\[\e[38;5;38m\]╰─\[\e[1;38;5;81m\]❯ \[\e[0m\]'

if [[ -n ${KITTY_WINDOW_ID:-} && -t 1 && -z ${BLUE_OCEAN_FETCH_SHOWN:-} ]] && command -v fastfetch >/dev/null 2>&1; then
    export BLUE_OCEAN_FETCH_SHOWN=1
    fastfetch --config "$HOME/.config/fastfetch/config.jsonc"
fi
