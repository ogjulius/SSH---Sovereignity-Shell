# shellcheck shell=bash
# Void Linux (UNOFFICIAL): xbps for dependencies, and a real local XBPS
# package for SSH built with xbps-create from `make install` into a staging
# root, so xbps owns every file and `xbps-remove ssh-shell` uninstalls it.
# Quickshell and Niri are in Void's repositories; Hyprland is not.

be_label() { echo "xbps (Void repositories) + local xbps-create package"; }

be_names() {
    case $1 in
        core) echo "quickshell qt6-declarative qt6-svg qt6-wayland font-inter" ;;
        build) echo "make" ;;
        hyprland) echo "" ;;            # not in Void's repositories
        hyprland-portal) echo "" ;;
        niri) echo "niri" ;;
        niri-portal) echo "xdg-desktop-portal-gnome" ;;
        audio) echo "pipewire wireplumber" ;;
        network) echo "NetworkManager" ;;
        bluetooth) echo "bluez" ;;
        battery) echo "upower" ;;
        power) echo "power-profiles-daemon" ;;
        brightness) echo "brightnessctl" ;;
        notify) echo "libnotify" ;;
        term:*) echo "${1#term:}" ;;
    esac
}

be_conflict() {
    local p
    case $1 in
        power) for p in tlp auto-cpufreq; do be_pkg_installed "$p" && { echo "$p is installed and conflicts with power-profiles-daemon"; return; }; done ;;
    esac
}

be_pkg_installed() { xbps-query "$1" >/dev/null 2>&1; }
be_pkg_available() { local p; for p in "$@"; do xbps-query -R "$p" >/dev/null 2>&1 && echo "$p"; done; }
be_extra_repos() { :; }
be_setup_repos() { :; }
be_refresh() { ui_run "Synchronising repository index" $PRIV xbps-install -S; }
be_install_pkgs() { [ $# -eq 0 ] && return 0; ui_run "Installing ${#} package(s): $*" $PRIV xbps-install -y "$@"; }
be_ssh_installed() { xbps-query -p pkgver ssh-shell 2>/dev/null; }

be_build_and_install() {
    local work=$1 ver deps="" d
    ver=$(sed -n 's/.*version: "\(.*\)".*/\1/p' "$REPO/src/configuration/Version.qml" | tr -d '-')
    mkdir -p "$work/root" "$work/repo"
    ui_run "Staging files (make install)" make -C "$REPO" install DESTDIR="$work/root" PREFIX=/usr || return 1
    for d in $(be_names core); do deps="$deps $d>=0"; done
    ui_run "Creating the ssh-shell XBPS package" env -C "$work/repo" xbps-create -A noarch -n "ssh-shell-${ver}_1" \
        -s "Spatial Quickshell desktop shell for Hyprland and Niri" -D "${deps# }" \
        -H "https://github.com/ogjulius/SSH---Sovereignity-Shell" -l "GPL-3.0-or-later" \
        -m "SSH contributors <ssh-shell@users.noreply.github.com>" "$work/root" || return 1
    ui_run "Indexing the local repository" xbps-rindex -a "$work"/repo/*.xbps || return 1
    ui_run "Installing ssh-shell" $PRIV xbps-install -y -f --repository="$work/repo" ssh-shell
}

be_uninstall() {
    be_pkg_installed ssh-shell || return 0
    ui_run "Removing ssh-shell" $PRIV xbps-remove -y ssh-shell
}
be_remove_hint() { echo "sudo xbps-remove $*"; }
