# shellcheck shell=bash
# Fedora Linux: dnf + an RPM built with rpmbuild from this checkout
# (packaging/fedora/ssh-shell.spec). Quickshell comes from the
# errornointernet/quickshell COPR (the one the Quickshell docs point to);
# Hyprland, which Fedora does not ship, from the solopasha/hyprland COPR.

be_label() { echo "dnf (Fedora repositories + COPR) + rpmbuild"; }

be_names() {
    case $1 in
        core) echo "quickshell qt6-qtdeclarative qt6-qtsvg rsms-inter-fonts jetbrains-mono-fonts" ;;
        build) echo "rpm-build make tar" ;;
        hyprland) echo "hyprland" ;;
        hyprland-portal) echo "xdg-desktop-portal-hyprland" ;;
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
        power) for p in tuned-ppd tlp auto-cpufreq; do be_pkg_installed "$p" && { echo "$p is installed and conflicts with power-profiles-daemon"; return; }; done ;;
    esac
}

be_pkg_installed() { rpm -q --quiet "$1" 2>/dev/null || rpm -q --quiet --whatprovides "$1" 2>/dev/null; }
be_pkg_available() {
    [ $# -eq 0 ] && return 0
    dnf -q repoquery --qf '%{name}\n' "$@" 2>/dev/null | sort -u
}

# Extra repositories this plan needs, one "id|reason" per line.
be_extra_repos() {
    local need_quickshell=1 r
    be_pkg_installed quickshell && need_quickshell=0
    for r in $(dnf -q copr list 2>/dev/null); do case $r in *errornointernet/quickshell*) need_quickshell=0 ;; esac; done
    [ $need_quickshell = 1 ] && echo "errornointernet/quickshell|Quickshell is not in Fedora's repositories (COPR referenced by the Quickshell docs)"
    if [ "${WANT_HYPRLAND:-0}" = 1 ] && ! be_pkg_installed hyprland; then
        local have_h=0
        for r in $(dnf -q copr list 2>/dev/null); do case $r in *solopasha/hyprland*) have_h=1 ;; esac; done
        [ $have_h = 0 ] && echo "solopasha/hyprland|Hyprland is not in Fedora's repositories (community COPR)"
    fi
}

be_setup_repos() {
    local line id
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        id=${line%%|*}
        ui_run "Installing the dnf COPR plugin" $PRIV dnf -y install 'dnf-command(copr)' || return 1
        ui_run "Enabling COPR $id" $PRIV dnf -y copr enable "$id" || return 1
        echo "copr $id" >>"$STATE_FILE.new"
    done <<<"$(be_extra_repos)"
}

be_refresh() { ui_run "Refreshing package metadata" $PRIV dnf -y makecache; }
# Never --allowerasing: a conflicting transaction fails instead of removing packages.
be_install_pkgs() { [ $# -eq 0 ] && return 0; ui_run "Installing ${#} package(s): $*" $PRIV dnf -y install "$@"; }

be_ssh_installed() { rpm -q ssh-shell 2>/dev/null | grep -v 'not installed'; }

be_build_and_install() {
    local work=$1
    mkdir -p "$work"/{SOURCES,SPECS,BUILD,RPMS,SRPMS}
    make_source_tarball "$work/SOURCES/ssh-shell-main.tar.gz" SSH---Sovereignity-Shell-main || return 1
    ui_run "Building the ssh-shell RPM (rpmbuild)" rpmbuild --define "_topdir $work" -bb "$REPO/packaging/fedora/ssh-shell.spec" || return 1
    local rpm
    rpm=$(ls "$work"/RPMS/noarch/ssh-shell-*.rpm 2>/dev/null | head -1)
    [ -n "$rpm" ] || { ui_err "rpmbuild produced no package"; return 1; }
    if be_pkg_installed ssh-shell; then
        ui_run "Reinstalling $(basename "$rpm")" $PRIV dnf -y reinstall "$rpm" || ui_run "Upgrading to $(basename "$rpm")" $PRIV dnf -y upgrade "$rpm"
    else
        ui_run "Installing $(basename "$rpm")" $PRIV dnf -y install "$rpm"
    fi
}

be_uninstall() {
    be_pkg_installed ssh-shell || return 0
    ui_run "Removing ssh-shell" $PRIV dnf -y remove ssh-shell
}
be_remove_hint() { echo "sudo dnf remove $*"; }
