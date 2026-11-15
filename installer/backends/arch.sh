# shellcheck shell=bash
# Arch Linux, CachyOS, EndeavourOS: pacman + a package built with makepkg
# from this checkout (packaging/arch/PKGBUILD.local).

be_label() { echo "pacman (Arch repositories) + makepkg"; }

be_names() {
    case $1 in
        core) echo "quickshell qt6-declarative qt6-svg inter-font ttf-jetbrains-mono" ;;
        build) echo "base-devel" ;;
        hyprland) echo "hyprland" ;;
        hyprland-portal) echo "xdg-desktop-portal-hyprland" ;;
        niri) echo "niri" ;;
        niri-portal) echo "xdg-desktop-portal-gnome" ;;
        audio) echo "pipewire wireplumber" ;;
        network) echo "networkmanager" ;;
        bluetooth) echo "bluez bluez-utils" ;;
        battery) echo "upower" ;;
        power) echo "power-profiles-daemon" ;;
        brightness) echo "brightnessctl" ;;
        notify) echo "libnotify" ;;
        term:*) echo "${1#term:}" ;;
    esac
}

# Installed packages that would conflict with a logical group: print a reason.
be_conflict() {
    local p
    case $1 in
        power) for p in tlp tuned-ppd auto-cpufreq; do be_pkg_installed "$p" && { echo "$p is installed and conflicts with power-profiles-daemon"; return; }; done ;;
        audio) be_pkg_installed pipewire-media-session && echo "pipewire-media-session is installed and conflicts with wireplumber" ;;
    esac
}

be_pkg_installed() { pacman -Qq "$1" >/dev/null 2>&1 || pacman -Qqg "$1" >/dev/null 2>&1; }
be_pkg_available() { local p; for p in "$@"; do pacman -Sp --print-format %n "$p" >/dev/null 2>&1 && echo "$p"; done; }

be_extra_repos() { :; }   # none needed on Arch
be_setup_repos() { :; }

# No `pacman -Sy` here: syncing without upgrading is a partial upgrade, which
# Arch does not support. Packages come from the databases as they are; if they
# are stale the user is told to run a full upgrade first.
be_refresh() { ui_ok "using the current package databases (no partial upgrade)"; }
be_install_pkgs() {
    [ $# -eq 0 ] && return 0
    ui_run "Installing ${#} package(s): $*" $PRIV pacman -S --needed --noconfirm "$@" && return 0
    ui_note "If pacman could not download packages, your package databases are out of date:"
    ui_note "run 'sudo pacman -Syu' to update the system, then ./install.sh again."
    return 1
}

be_ssh_installed() { pacman -Q ssh-shell 2>/dev/null || pacman -Q ssh-shell-git 2>/dev/null; }

be_build_and_install() {
    local work=$1
    mkdir -p "$work/pkg" "$work/out"
    make_source_tarball "$work/pkg/ssh-shell-src.tar.gz" ssh-shell || return 1
    cp "$REPO/packaging/arch/PKGBUILD.local" "$work/pkg/PKGBUILD"
    ui_run "Building the ssh-shell package (makepkg)" \
        env -C "$work/pkg" PKGDEST="$work/out" BUILDDIR="$work/build" SRCDEST="$work/pkg" makepkg -f --noconfirm --nocheck || return 1
    local pkg
    pkg=$(ls "$work"/out/ssh-shell-*.pkg.tar.* 2>/dev/null | grep -v -- '-debug-' | head -1)
    [ -n "$pkg" ] || { ui_err "makepkg produced no package"; return 1; }
    if pacman -Q ssh-shell-git >/dev/null 2>&1; then
        ui_run "Removing the previous ssh-shell-git package (replaced by ssh-shell)" $PRIV pacman -R --noconfirm ssh-shell-git || return 1
    fi
    ui_run "Installing $(basename "$pkg")" $PRIV pacman -U --noconfirm "$pkg"
}

be_uninstall() {
    local p
    for p in ssh-shell ssh-shell-git; do
        pacman -Q "$p" >/dev/null 2>&1 && { ui_run "Removing $p" $PRIV pacman -R --noconfirm "$p" || return 1; }
    done
    return 0
}
be_remove_hint() { echo "sudo pacman -Rs $*"; }
