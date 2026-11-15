# fish completion for ssh-shell (SSH — Sovereignity Shell)
set -l top run --daemon status keybinds doctor check-config quit version help lens launcher atlas panel audio brightness notifications settings shell
complete -c ssh-shell -f
complete -c ssh-shell -n "not __fish_seen_subcommand_from $top" -a "$top"
complete -c ssh-shell -n "__fish_seen_subcommand_from lens" -a "toggle open close"
complete -c ssh-shell -n "__fish_seen_subcommand_from launcher settings" -a "toggle open"
complete -c ssh-shell -n "__fish_seen_subcommand_from atlas; and not __fish_seen_subcommand_from traverse carry" -a "toggle traverse carry goto collection where"
complete -c ssh-shell -n "__fish_seen_subcommand_from traverse carry" -a "left right up down"
complete -c ssh-shell -n "__fish_seen_subcommand_from panel; and not __fish_seen_subcommand_from toggle" -a "toggle close"
complete -c ssh-shell -n "__fish_seen_subcommand_from panel; and __fish_seen_subcommand_from toggle" -a "instruments almanac signals power"
complete -c ssh-shell -n "__fish_seen_subcommand_from audio" -a "up down mute mic"
complete -c ssh-shell -n "__fish_seen_subcommand_from brightness" -a "up down"
complete -c ssh-shell -n "__fish_seen_subcommand_from notifications" -a "quiet clear"
complete -c ssh-shell -n "__fish_seen_subcommand_from keybinds" -a "hyprland hyprland-lua niri"
complete -c ssh-shell -n "__fish_seen_subcommand_from check-config" -F
