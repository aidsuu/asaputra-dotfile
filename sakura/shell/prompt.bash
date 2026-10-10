# Sakura Bash prompt. Sourced from ~/.bashrc only in an interactive shell.
case $- in *i*) ;; *) return ;; esac

sakura_branch() {
    local branch
    branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || return 0
    printf '  [git:%s]' "$branch"
}

PS1='\[\e[38;5;175m\]╭─\[\e[38;5;181m\]\u\[\e[38;5;139m\]@\h  \[\e[1;38;5;255m\]\W\[\e[0m\]$(sakura_branch)\n\[\e[38;5;175m\]╰─\[\e[1;38;5;182m\]❯ \[\e[0m\]'

if [[ -n ${KITTY_WINDOW_ID:-} && -t 1 && -z ${SAKURA_FETCH_SHOWN:-} ]] && command -v fastfetch >/dev/null 2>&1; then
    export SAKURA_FETCH_SHOWN=1
    fastfetch --config "$HOME/.config/fastfetch/config.jsonc"
fi
