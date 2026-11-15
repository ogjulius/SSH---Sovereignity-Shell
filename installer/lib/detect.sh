# shellcheck shell=bash
# Detection helpers for the SSH installer. Nothing here changes the system.

have() { command -v "$1" >/dev/null 2>&1; }

# Sets DISTRO_ID, DISTRO_NAME, BACKEND (arch|fedora|nixos|void|""), DISTRO_OFFICIAL (1|0).
detect_distro() {
    local id="" like="" name=""
    if [ -r "${SSH_OS_RELEASE:-/etc/os-release}" ]; then
        # shellcheck disable=SC1090
        id=$(. "${SSH_OS_RELEASE:-/etc/os-release}"; echo "${ID:-}")
        like=$(. "${SSH_OS_RELEASE:-/etc/os-release}"; echo "${ID_LIKE:-}")
        name=$(. "${SSH_OS_RELEASE:-/etc/os-release}"; echo "${PRETTY_NAME:-${NAME:-$id}}")
    fi
    DISTRO_ID=$id; DISTRO_NAME=${name:-unknown}; BACKEND=""; DISTRO_OFFICIAL=0; DISTRO_NOTE=""
    case $id in
        arch|cachyos|endeavouros) BACKEND=arch; DISTRO_OFFICIAL=1 ;;
        fedora) BACKEND=fedora; DISTRO_OFFICIAL=1 ;;
        nixos) BACKEND=nixos; DISTRO_OFFICIAL=1 ;;
        void) BACKEND=void; DISTRO_OFFICIAL=0; DISTRO_NOTE="Void Linux is an unofficial, community-supported target." ;;
        manjaro*) DISTRO_NOTE="Manjaro holds Arch packages back; SSH's Arch package needs current Quickshell and is not supported there." ;;
        *)
            case " $like " in
                *" arch "*) BACKEND=arch; DISTRO_NOTE="$name is Arch-based but not a supported target; the Arch backend may work." ;;
                *" fedora "*) BACKEND=fedora; DISTRO_NOTE="$name is Fedora-based but not a supported target; the Fedora backend may work." ;;
            esac ;;
    esac
}

comp_version() {
    case $1 in
        hyprland) Hyprland --version 2>/dev/null | sed -n 's/^Hyprland \([^ ]*\).*/\1/p' | head -1 ;;
        niri) niri --version 2>/dev/null | awk '{print $2}' | head -1 ;;
    esac
}

# HAS_HYPRLAND / HAS_NIRI (1|0) and their versions.
detect_compositors() {
    HAS_HYPRLAND=0; HAS_NIRI=0; VER_HYPRLAND=""; VER_NIRI=""
    if have Hyprland; then HAS_HYPRLAND=1; VER_HYPRLAND=$(comp_version hyprland); fi
    if have niri; then HAS_NIRI=1; VER_NIRI=$(comp_version niri); fi
}

# SHELLS_FOUND: interactive shells present (bash fish zsh), LOGIN_SHELL.
detect_shells() {
    SHELLS_FOUND=()
    local s
    for s in bash fish zsh; do have "$s" && SHELLS_FOUND+=("$s"); done
    LOGIN_SHELL=$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)
    LOGIN_SHELL=${LOGIN_SHELL:-${SHELL:-unknown}}
}

# Terminal emulators SSH can launch: "binary|Label".
TERMINALS=("foot|Foot" "kitty|Kitty" "alacritty|Alacritty" "ghostty|Ghostty" "wezterm|WezTerm" "konsole|Konsole" "gnome-terminal|GNOME Terminal" "xfce4-terminal|Xfce Terminal")
detect_terminals() {
    TERMS_FOUND=()
    local t
    for t in "${TERMINALS[@]}"; do have "${t%%|*}" && TERMS_FOUND+=("${t%%|*}"); done
}

# DM: sddm gdm lightdm greetd ly … or "".
detect_dm() {
    DM=""
    local l
    l=$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)
    [ -n "$l" ] && DM=$(basename "$l" .service)
    if [ -z "$DM" ] && [ -d /var/service ]; then
        for l in sddm gdm lightdm greetd ly emptty; do [ -e "/var/service/$l" ] && DM=$l && break; done
    fi
    if [ -z "$DM" ] && [ "$BACKEND" = nixos ] && [ -e /etc/systemd/system/display-manager.service ]; then
        DM=$(grep -o 'ExecStart=[^ ]*' /etc/systemd/system/display-manager.service 2>/dev/null | sed 's|.*/||')
    fi
}

# Privilege tool: sudo or doas. Never run the installer as root.
detect_priv() {
    PRIV=""
    if have sudo; then PRIV=sudo; elif have doas; then PRIV=doas; fi
}

session_dirs() { printf '%s\n' /usr/share/wayland-sessions /usr/local/share/wayland-sessions /run/current-system/sw/share/wayland-sessions; }
find_session_file() {
    local d
    for d in $(session_dirs); do [ -f "$d/$1" ] && { echo "$d/$1"; return 0; }; done
    return 1
}
