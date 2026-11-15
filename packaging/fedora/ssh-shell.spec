# RPM spec for SSH — Sovereignity Shell.
# Quickshell is not in Fedora's official repositories at the time of writing;
# install it first (see docs/INSTALLATION.md), then build with:
#   rpmbuild -ba packaging/fedora/ssh-shell.spec --define "_sourcedir $PWD/.."
Name:           ssh-shell
Version:        0.1.0~alpha
Release:        1%{?dist}
Summary:        Spatial Quickshell desktop shell for Hyprland and Niri
License:        GPL-3.0-or-later
URL:            https://github.com/ogjulius/SSH---Sovereignity-Shell
Source0:        %{url}/archive/refs/heads/main.tar.gz#/%{name}-main.tar.gz
BuildArch:      noarch
BuildRequires:  make
Requires:       quickshell >= 0.3
Requires:       qt6-qtdeclarative
Requires:       qt6-qtsvg
Requires:       rsms-inter-fonts
Requires:       jetbrains-mono-fonts
Recommends:     pipewire
Recommends:     NetworkManager
Recommends:     bluez
Recommends:     upower
Recommends:     power-profiles-daemon
Recommends:     brightnessctl

%description
SSH (Sovereignity Shell) is a Quickshell desktop shell built around a spatial
model: workspaces are cells on an extensible map (the Atlas), surfaced through
a compass-like hub (the Lens), an instrument bar (the Meridian), a control
centre, dashboard and notification daemon. Supports Hyprland and Niri.

%prep
%autosetup -n SSH---Sovereignity-Shell-main

%build
# Interpreted QML: nothing to build.

%install
make install DESTDIR=%{buildroot} PREFIX=%{_prefix}

%files
%license LICENSE
%{_bindir}/ssh-shell
%{_datadir}/ssh-shell/
%{_docdir}/ssh-shell/
%{_datadir}/licenses/ssh-shell/
%{_datadir}/icons/hicolor/scalable/apps/ssh-shell.svg
%{_datadir}/icons/hicolor/256x256/apps/ssh-shell.png

%changelog
* Sun Nov 15 2026 SSH contributors - 0.1.0~alpha-1
- First packaged pre-release.
