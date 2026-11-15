# bash completion for ssh-shell (SSH — Sovereignity Shell)
_ssh_shell() {
    local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
    local top="run --daemon status keybinds doctor check-config quit version help lens launcher atlas panel audio brightness notifications settings shell"
    if [ "$COMP_CWORD" -eq 1 ]; then COMPREPLY=($(compgen -W "$top" -- "$cur")); return; fi
    case $prev in
        lens) COMPREPLY=($(compgen -W "toggle open close" -- "$cur")) ;;
        launcher|settings) COMPREPLY=($(compgen -W "toggle open" -- "$cur")) ;;
        atlas) COMPREPLY=($(compgen -W "toggle traverse carry goto collection where" -- "$cur")) ;;
        traverse|carry) COMPREPLY=($(compgen -W "left right up down" -- "$cur")) ;;
        panel) COMPREPLY=($(compgen -W "toggle close" -- "$cur")) ;;
        toggle) [ "${COMP_WORDS[1]}" = panel ] && COMPREPLY=($(compgen -W "instruments almanac signals power" -- "$cur")) ;;
        audio) COMPREPLY=($(compgen -W "up down mute mic" -- "$cur")) ;;
        brightness) COMPREPLY=($(compgen -W "up down" -- "$cur")) ;;
        notifications) COMPREPLY=($(compgen -W "quiet clear" -- "$cur")) ;;
        keybinds) COMPREPLY=($(compgen -W "hyprland hyprland-lua niri" -- "$cur")) ;;
        check-config) COMPREPLY=($(compgen -f -- "$cur")) ;;
    esac
}
complete -F _ssh_shell ssh-shell
