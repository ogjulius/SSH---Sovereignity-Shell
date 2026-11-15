#!/usr/bin/env bash
# SSH — Sovereignity Shell installer. Run through ./install.sh.
#
#   ./install.sh                 interactive installation
#   ./install.sh --uninstall     remove SSH (keeps your settings unless asked)
#   ./install.sh --dry-run       show the plan; change nothing
#
# Unattended:  --yes [--compositor=hyprland|niri|both] [--profile=minimal|standard|complete]
#              [--terminal=BIN] [--theme=NAME] [--preselect|--no-preselect] [--replace-config]
# Other:       --plain (no arrow-key UI)   --help
#
# Bash runs this script; your interactive shell can be anything. The
# installer never changes your login shell, your shell or compositor
# configuration, your display manager or your bootloader, and it never
# reboots without asking.
set -uo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=lib/ui.sh
. "$REPO/installer/lib/ui.sh"
# shellcheck source=lib/detect.sh
. "$REPO/installer/lib/detect.sh"

# ── Arguments ───────────────────────────────────────────────────────────
OPT_PLAIN=0; OPT_DRY=0; OPT_UNINSTALL=0
ARG_COMP=""; ARG_PROFILE=""; ARG_TERM=""; ARG_THEME=""; ARG_PRESELECT=""; ARG_REPLACE_CONFIG=0
for a in "$@"; do
    case $a in
        --yes|-y) UI_YES=1 ;;
        --plain) OPT_PLAIN=1 ;;
        --dry-run) OPT_DRY=1 ;;
        --uninstall) OPT_UNINSTALL=1 ;;
        --compositor=*) ARG_COMP=${a#*=} ;;
        --profile=*) ARG_PROFILE=${a#*=} ;;
        --terminal=*) ARG_TERM=${a#*=} ;;
        --theme=*) ARG_THEME=${a#*=} ;;
        --preselect) ARG_PRESELECT=1 ;;
        --no-preselect) ARG_PRESELECT=0 ;;
        --replace-config) ARG_REPLACE_CONFIG=1 ;;
        -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "install.sh: unknown option '$a' (try --help)" >&2; exit 2 ;;
    esac
done

ui_init "$OPT_PLAIN"
trap 'ui_cursor_show' EXIT
trap 'ui_cursor_show; ui_abort' INT

STATE_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/ssh-shell
CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/ssh-shell
CONFIG_FILE=$CONFIG_DIR/config.json
STATE_FILE=$STATE_DIR/installer.state
mkdir -p "$STATE_DIR"
UI_LOG=$STATE_DIR/install-$(date +%Y%m%d-%H%M%S).log
: >"$UI_LOG"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/ssh-install.XXXXXX")
trap 'ui_cursor_show; rm -rf "$WORK"' EXIT

log() { printf '%s\n' "$*" >>"$UI_LOG"; }

make_source_tarball() { # OUT PREFIX — the working tree, tracked + untracked-not-ignored files
    local out=$1 prefix=$2
    if have git && [ -d "$REPO/.git" ]; then
        git -C "$REPO" ls-files -co --exclude-standard -z \
            | while IFS= read -r -d '' f; do [ -e "$REPO/$f" ] && printf '%s\0' "$f"; done \
            | tar -czf "$out" --transform="s,^,$prefix/," -C "$REPO" --null -T - 2>>"$UI_LOG"
    else
        tar -czf "$out" --exclude=.git --transform="s,^\./,$prefix/," -C "$REPO" . 2>>"$UI_LOG"
    fi
}

# ── Preflight ───────────────────────────────────────────────────────────
ui_banner
if [ "$(id -u)" = 0 ]; then
    ui_err "Run ./install.sh as your normal user, not as root."
    ui_note "It asks for your password (sudo/doas) only for the steps that need it, and"
    ui_note "your settings belong in your own home directory."
    exit 1
fi
detect_distro; detect_compositors; detect_shells; detect_terminals; detect_priv; detect_dm

ui_title "System"
ui_kv "Distribution" "$DISTRO_NAME"
if [ -z "$BACKEND" ]; then
    ui_err "This distribution is not supported."
    [ -n "$DISTRO_NOTE" ] && ui_note "$DISTRO_NOTE"
    ui_note "Supported: Arch Linux, CachyOS, EndeavourOS, Fedora, NixOS; Void (unofficial)."
    ui_note "Manual installation: docs/installation/README.md"
    exit 1
fi
# shellcheck source=/dev/null
. "$REPO/installer/backends/$BACKEND.sh"
ui_kv "Installation method" "$(be_label)"
[ -n "$DISTRO_NOTE" ] && ui_warn "$DISTRO_NOTE"
if [ "$DISTRO_OFFICIAL" = 0 ] && [ "$BACKEND" != void ]; then
    ui_confirm "Continue on an unsupported distribution?" n || ui_abort
fi
ui_kv "Hyprland" "$([ $HAS_HYPRLAND = 1 ] && echo "installed ${VER_HYPRLAND}" || echo "not installed")"
ui_kv "Niri" "$([ $HAS_NIRI = 1 ] && echo "installed ${VER_NIRI}" || echo "not installed")"
ui_kv "Shells found" "${SHELLS_FOUND[*]:-none} (login shell: $(basename "$LOGIN_SHELL"), not changed)"
ui_kv "Display manager" "${DM:-none detected}"
ui_kv "Privileges via" "${PRIV:-none found}"
current=$(be_ssh_installed || true)
[ -n "$current" ] && ui_kv "SSH already installed" "$current"
if [ -z "$PRIV" ] && [ "$OPT_DRY" = 0 ]; then
    ui_err "Neither sudo nor doas is available; installing packages needs one of them."
    exit 1
fi

# ═══ Uninstall ══════════════════════════════════════════════════════════
if [ "$OPT_UNINSTALL" = 1 ]; then
    ui_title "Uninstall"
    if [ "$BACKEND" = nixos ]; then
        ui_note "On NixOS: $(be_remove_hint)."
        exit 0
    fi
    ui_note "Removes the ssh-shell package (both login sessions go with it) and undoes"
    ui_note "the login-screen preselection. Dependencies are kept: other software may use them."
    ui_note "Your settings in $CONFIG_DIR are kept unless you choose otherwise."
    [ "$OPT_DRY" = 1 ] && { ui_note "Dry run: nothing changed."; exit 0; }
    ui_confirm "Remove SSH now?" y || ui_abort
    UI_STEPS=3
    ui_step "Removing the package"
    be_uninstall || { ui_err "Removal failed; see $UI_LOG"; exit 1; }
    ui_step "Restoring the login screen choice"
    if [ -f "$STATE_FILE" ]; then
        while read -r kind a b; do
            case $kind in
                dm-sddm) [ -n "$a" ] && $PRIV test -f "$a" && ui_run "Restoring SDDM state from $a" $PRIV cp -a "$a" /var/lib/sddm/state.conf ;;
                dm-accounts) [ -n "$a" ] && ui_run "Restoring AccountsService session '$a'" $PRIV busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User SetSession s "$a" ;;
            esac
        done <"$STATE_FILE"
    else ui_note "nothing recorded"; fi
    ui_step "Your settings"
    if [ -d "$CONFIG_DIR" ] && ui_confirm "Also delete your SSH settings ($CONFIG_DIR) and state ($STATE_DIR)?" n; then
        rm -rf "$CONFIG_DIR"; ui_ok "settings removed"
        rm -rf "$STATE_DIR"; echo "  (log not kept)"
    else ui_ok "settings kept in $CONFIG_DIR"; fi
    if [ -f "$STATE_FILE" ]; then
        deps=$(awk '$1=="pkg"{printf "%s ", $2}' "$STATE_FILE")
        if [ -n "$deps" ]; then
            ui_note "Packages the installer added for SSH (kept): $deps"
            ui_note "Remove them yourself if nothing else needs them: $(be_remove_hint "$deps")"
        fi
        mv -f "$STATE_FILE" "$STATE_FILE.uninstalled" 2>/dev/null
    fi
    printf '\n  SSH has been removed. Your Hyprland/Niri sessions are untouched.\n\n'
    exit 0
fi

# ═══ Choices ════════════════════════════════════════════════════════════
WANT_HYPRLAND=0; WANT_NIRI=0
hypr_avail=1; [ -z "$(be_names hyprland)" ] && [ $HAS_HYPRLAND = 0 ] && hypr_avail=0
case $ARG_COMP in
    hyprland) WANT_HYPRLAND=1 ;; niri) WANT_NIRI=1 ;; both) WANT_HYPRLAND=1; WANT_NIRI=1 ;;
    "")
        opts=(); map=()
        tag() { [ "$1" = 1 ] && echo "installed" || echo "will be installed"; }
        [ $hypr_avail = 1 ] && { opts+=("Hyprland"$'\t'"$(tag $HAS_HYPRLAND)"); map+=(h); }
        opts+=("Niri"$'\t'"$(tag $HAS_NIRI)"); map+=(n)
        [ $hypr_avail = 1 ] && { opts+=("Both"$'\t'"one login session for each"); map+=(b); }
        def=0
        if [ $HAS_HYPRLAND = 1 ] && [ $HAS_NIRI = 1 ]; then def=$(( ${#map[@]} - 1 ))
        elif [ $HAS_NIRI = 1 ] && [ $HAS_HYPRLAND = 0 ]; then for i in "${!map[@]}"; do [ "${map[$i]}" = n ] && def=$i; done; fi
        [ $hypr_avail = 0 ] && ui_note "Hyprland is not in $DISTRO_NAME's repositories; install it yourself to get its session."
        ui_menu pick "Which compositor should SSH run on?" "Each gets its own login session; the plain compositor session stays as a recovery option." "$def" "${opts[@]}"
        case ${map[$pick]} in h) WANT_HYPRLAND=1 ;; n) WANT_NIRI=1 ;; b) WANT_HYPRLAND=1; WANT_NIRI=1 ;; esac ;;
    *) ui_err "--compositor must be hyprland, niri or both"; exit 2 ;;
esac
if [ $WANT_HYPRLAND = 1 ] && [ $hypr_avail = 0 ]; then ui_err "Hyprland is not available on $DISTRO_NAME"; exit 1; fi
DEFAULT_SESSION=hyprland; [ $WANT_HYPRLAND = 0 ] && DEFAULT_SESSION=niri
if [ $WANT_HYPRLAND = 1 ] && [ $WANT_NIRI = 1 ] && [ "$UI_YES" = 0 ]; then
    ui_menu p "Which session should the login screen preselect?" "" 0 "Sovereignity Shell (Hyprland)" "Sovereignity Shell (Niri)"
    [ "$p" = 1 ] && DEFAULT_SESSION=niri
fi

# Terminal
TERMINAL_BIN=""; TERMINAL_PKG=""
if [ -n "$ARG_TERM" ]; then TERMINAL_BIN=$ARG_TERM
else
    opts=(); bins=()
    for t in "${TERMS_FOUND[@]}"; do for e in "${TERMINALS[@]}"; do [ "${e%%|*}" = "$t" ] && { opts+=("${e#*|}"$'\t'"installed"); bins+=("$t"); }; done; done
    for e in "${TERMINALS[@]}"; do
        b=${e%%|*}; case " ${TERMS_FOUND[*]:-} " in *" $b "*) continue ;; esac
        case $b in foot|kitty|alacritty) opts+=("${e#*|}"$'\t'"install"); bins+=("$b") ;; esac
    done
    ui_menu pick "Which terminal should SSH open?" "Used by the launcher and the Lens. You can change it later in Settings → Commands." 0 "${opts[@]}"
    TERMINAL_BIN=${bins[$pick]}
fi
have "$TERMINAL_BIN" || TERMINAL_PKG=$(be_names "term:$TERMINAL_BIN")

# Profile, modules and integrations
declare -A MOD INT MOD_LABEL INT_LABEL
MOD_KEYS=(lens atlas signals osd weather)
MOD_LABEL=([lens]="Lens"$'\t'"the Sovereign Space hub (Super+Space)" [atlas]="Atlas"$'\t'"the infinite desktop map of workspaces" [signals]="Signals"$'\t'"notification daemon and history" [osd]="OSD"$'\t'"volume and brightness indicator" [weather]="Weather"$'\t'"in the Almanac, from Open-Meteo (needs a location)")
INT_KEYS=(audio network battery brightness portal notify bluetooth power)
INT_LABEL=([audio]="Audio"$'\t'"PipeWire + WirePlumber" [network]="Network"$'\t'"NetworkManager (status and Wi-Fi)" [battery]="Battery"$'\t'"UPower" [brightness]="Brightness"$'\t'"brightnessctl" [portal]="Portal"$'\t'"xdg-desktop-portal for your compositor" [notify]="notify-send"$'\t'"libnotify" [bluetooth]="Bluetooth"$'\t'"BlueZ" [power]="Power profiles"$'\t'"power-profiles-daemon")
set_profile() {
    local k
    for k in "${MOD_KEYS[@]}"; do MOD[$k]=0; done
    for k in "${INT_KEYS[@]}"; do INT[$k]=0; done
    MOD[lens]=1; MOD[atlas]=1
    case $1 in
        standard|complete|custom)
            MOD[signals]=1; MOD[osd]=1
            for k in audio network battery brightness portal notify; do INT[$k]=1; done ;;
    esac
    if [ "$1" = complete ]; then MOD[weather]=1; INT[bluetooth]=1; INT[power]=1; fi
}
case $ARG_PROFILE in
    minimal|standard|complete) PROFILE=$ARG_PROFILE ;;
    "")
        ui_menu pick "Installation profile" "" 1 \
            "Minimal"$'\t'"Meridian, Lens, Atlas, launcher; required packages only" \
            "Standard"$'\t'"+ notifications, OSD, audio/network/battery/brightness support" \
            "Complete"$'\t'"+ weather, Bluetooth, power profiles" \
            "Custom"$'\t'"choose modules and integrations"
        PROFILE=$(echo minimal standard complete custom | cut -d' ' -f$((pick+1))) ;;
    *) ui_err "--profile must be minimal, standard or complete"; exit 2 ;;
esac
set_profile "$PROFILE"
if [ "$PROFILE" = custom ]; then
    st=(); lab=(); for k in "${MOD_KEYS[@]}"; do st+=("${MOD[$k]}"); lab+=("${MOD_LABEL[$k]}"); done
    ui_checklist st "Modules" "The Meridian bar, launcher, Instruments, Almanac and power menu are always included." "${lab[@]}"
    for i in "${!MOD_KEYS[@]}"; do MOD[${MOD_KEYS[$i]}]=${st[$i]}; done
    st=(); lab=(); for k in "${INT_KEYS[@]}"; do st+=("${INT[$k]}"); lab+=("${INT_LABEL[$k]}"); done
    ui_checklist st "System integrations" "Packages SSH reads when present. Installing a service does not enable it." "${lab[@]}"
    for i in "${!INT_KEYS[@]}"; do INT[${INT_KEYS[$i]}]=${st[$i]}; done
fi

# Theme
THEMES=(); THEME_LABELS=()
for f in "$REPO"/src/themes/presets/*.json; do
    THEMES+=("$(basename "$f" .json)")
    THEME_LABELS+=("$(sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' "$f")")
done
THEME=obsidian-argent
if [ -n "$ARG_THEME" ]; then THEME=$ARG_THEME
else
    def=0; for i in "${!THEMES[@]}"; do [ "${THEMES[$i]}" = obsidian-argent ] && def=$i; done
    ui_menu pick "Theme" "Changeable any time in Settings → Themes." "$def" "${THEME_LABELS[@]}"
    THEME=${THEMES[$pick]}
fi
[ -f "$REPO/src/themes/presets/$THEME.json" ] || { ui_err "unknown theme '$THEME' (have: ${THEMES[*]})"; exit 2; }

# Existing configuration
CONFIG_ACTION=write
if [ -f "$CONFIG_FILE" ]; then
    CONFIG_ACTION=keep
    if [ "$ARG_REPLACE_CONFIG" = 1 ]; then CONFIG_ACTION=replace
    else
        ui_menu pick "You already have SSH settings ($CONFIG_FILE)" "" 0 \
            "Keep them"$'\t'"theme, module and terminal choices above are not applied" \
            "Replace them"$'\t'"the current file is backed up first"
        [ "$pick" = 1 ] && CONFIG_ACTION=replace
    fi
fi

# Login screen preselection
PRESELECT=0
case $DM in sddm|gdm|gdm3|lightdm) PRESELECT=1 ;; esac
[ "$BACKEND" = nixos ] && PRESELECT=0
if [ $PRESELECT = 1 ]; then
    if [ -n "$ARG_PRESELECT" ]; then PRESELECT=$ARG_PRESELECT
    else ui_confirm "Preselect \"Sovereignity Shell ($( [ $DEFAULT_SESSION = hyprland ] && echo Hyprland || echo Niri))\" on the $DM login screen? (You can still pick any session there.)" y || PRESELECT=0
    fi
fi

# ═══ Plan ═══════════════════════════════════════════════════════════════
declare -a P_PRESENT=() P_INSTALL=() P_MISSING=() P_SKIP=()
REQUIRED_MISSING=0
consider() { # GROUP-LABEL REQUIRED(1|0) package...
    local group=$1 req=$2 p; shift 2
    for p in "$@"; do
        [ -n "$p" ] || continue
        if be_pkg_installed "$p"; then P_PRESENT+=("$group|$p")
        else P_INSTALL+=("$group|$p|$req"); fi
    done
}
if [ "$BACKEND" != nixos ]; then
    consider "Required" 1 $(be_names core)
    consider "Build tools" 1 $(be_names build)
    [ $WANT_HYPRLAND = 1 ] && consider "Compositor" 1 $(be_names hyprland)
    [ $WANT_NIRI = 1 ] && consider "Compositor" 1 $(be_names niri)
    [ -n "$TERMINAL_PKG" ] && consider "Terminal" 0 "$TERMINAL_PKG"
    for k in "${INT_KEYS[@]}"; do
        [ "${INT[$k]}" = 1 ] || continue
        if [ $k = portal ]; then
            [ $WANT_HYPRLAND = 1 ] && consider "Integration: portal" 0 $(be_names hyprland-portal)
            [ $WANT_NIRI = 1 ] && consider "Integration: portal" 0 $(be_names niri-portal)
            continue
        fi
        why=$(be_conflict "$k")
        if [ -n "$why" ]; then for p in $(be_names "$k"); do be_pkg_installed "$p" || P_SKIP+=("$p|$why"); done; continue; fi
        consider "Integration: $k" 0 $(be_names "$k")
    done
    # Availability of what would be installed (one query).
    want=(); for e in "${P_INSTALL[@]}"; do IFS='|' read -r _ p _ <<<"$e"; want+=("$p"); done
    if [ ${#want[@]} -gt 0 ]; then
        avail=" $(be_pkg_available "${want[@]}" | tr '\n' ' ') "
        keep=()
        for e in "${P_INSTALL[@]}"; do
            IFS='|' read -r g p req <<<"$e"
            if [[ $avail == *" $p "* ]]; then keep+=("$e")
            else
                # COPR-provided packages are not visible until the COPR is enabled.
                if [ "$BACKEND" = fedora ] && { [ "$p" = quickshell ] || [[ $p == hyprland* || $p == xdg-desktop-portal-hyprland ]]; }; then keep+=("$e"); continue; fi
                P_MISSING+=("$p|$req"); [ "$req" = 1 ] && REQUIRED_MISSING=1
            fi
        done
        P_INSTALL=("${keep[@]}")
    fi
fi

show_plan() {
    ui_title "Dependencies"
    local e g p last=""
    for e in "${P_PRESENT[@]}" ; do IFS='|' read -r g p <<<"$e"; [ "$g" != "$last" ] && { printf '  %s%s%s\n' "$C_DIM" "$g" "$C_RESET"; last=$g; }; ui_ok "$p ${C_DIM}already installed${C_RESET}"; done
    last=""
    for e in "${P_INSTALL[@]}"; do IFS='|' read -r g p _ <<<"$e"; [ "$g" != "$last" ] && { printf '  %s%s%s\n' "$C_DIM" "$g" "$C_RESET"; last=$g; }; ui_add "$p ${C_DIM}will be installed${C_RESET}"; done
    for e in "${P_SKIP[@]}"; do ui_warn "skipped ${e%%|*}: ${e#*|}"; done
    for e in "${P_MISSING[@]}"; do
        if [ "${e#*|}" = 1 ]; then ui_err "${e%%|*} is required but not available in the enabled repositories"
        else ui_warn "${e%%|*} is not available in the enabled repositories (skipped)"; fi
    done
    [ "$BACKEND" = nixos ] && ui_note "On NixOS, dependencies come from nixpkgs through the flake (declarative)."

    ui_title "What will change"
    printf '  %sSystem (needs %s):%s\n' "$C_BOLD" "${PRIV:-root}" "$C_RESET"
    if [ "$BACKEND" = nixos ]; then
        ui_add "nothing directly: you add the generated module to your configuration"
    else
        local repos; repos=$(be_extra_repos)
        if [ -n "$repos" ]; then while IFS='|' read -r id why; do ui_add "enable repository $id — $why"; done <<<"$repos"; fi
        [ ${#P_INSTALL[@]} -gt 0 ] && ui_add "install ${#P_INSTALL[@]} package(s) with the native package manager"
        ui_add "build and install the ssh-shell package from this checkout:"
        ui_note "  /usr/bin/ssh-shell, /usr/bin/ssh-session, /usr/share/ssh-shell/,"
        [ $WANT_HYPRLAND = 1 ] && ui_note "  login session: Sovereignity Shell (Hyprland)"
        [ $WANT_NIRI = 1 ] && ui_note "  login session: Sovereignity Shell (Niri)"
        ui_note "  (both session files are installed; one whose compositor is missing stays hidden)"
        ui_note "  shell completions for bash, fish and zsh (used by: ${SHELLS_FOUND[*]:-none})"
        [ $PRESELECT = 1 ] && ui_add "preselect the $DEFAULT_SESSION session on the $DM login screen (previous choice backed up)"
    fi
    printf '  %sYour account:%s\n' "$C_BOLD" "$C_RESET"
    case $CONFIG_ACTION in
        write) ui_add "create $CONFIG_FILE (theme $THEME, terminal $TERMINAL_BIN, profile $PROFILE)" ;;
        replace) ui_add "replace $CONFIG_FILE (backed up first) with theme $THEME, terminal $TERMINAL_BIN, profile $PROFILE" ;;
        keep) ui_ok "keep $CONFIG_FILE unchanged" ;;
    esac
    [ "$BACKEND" = nixos ] && ui_add "write $CONFIG_DIR/nixos/ssh-shell.nix"
    printf '  %sNot changed:%s\n' "$C_BOLD" "$C_RESET"
    ui_note "your login shell ($(basename "$LOGIN_SHELL")) and shell configuration files"
    ui_note "~/.config/hypr and ~/.config/niri; the plain Hyprland/Niri login sessions"
    ui_note "your display manager, other packages, bootloader and partitions"
    ui_note "Log: $UI_LOG"
}
show_plan

if [ $REQUIRED_MISSING = 1 ]; then
    ui_err "A required package is unavailable; nothing was changed."
    [ "$BACKEND" = void ] && ui_note "Void: run 'sudo xbps-install -S' and try again."
    exit 1
fi
if [ "$OPT_DRY" = 1 ]; then printf '\n  Dry run: nothing was changed.\n\n'; exit 0; fi
ui_confirm "Proceed with the installation?" y || ui_abort

# ═══ Execute ════════════════════════════════════════════════════════════
: >"$STATE_FILE.new"
fail() {
    ui_err "$1"
    printf '\n  %sThe installation stopped.%s Nothing after this step was changed.\n' "$C_BOLD" "$C_RESET"
    printf '  Full log: %s\n' "$UI_LOG"
    printf '  Your existing desktop sessions are untouched; you can log in as before.\n'
    printf '  Retry with ./install.sh, or see docs/TROUBLESHOOTING.md.\n\n'
    [ -s "$STATE_FILE.new" ] && cat "$STATE_FILE.new" >>"$STATE_FILE" && rm -f "$STATE_FILE.new"
    exit 1
}

if [ "$PRIV" = sudo ] && [ "$BACKEND" != nixos ]; then
    printf '\n  Administrator access is needed for the system steps.\n'
    sudo -v || fail "sudo authentication failed"
    ( while sleep 50; do sudo -n true 2>/dev/null || exit; done ) &
    KEEPALIVE=$!
    trap 'ui_cursor_show; rm -rf "$WORK"; kill $KEEPALIVE 2>/dev/null' EXIT
elif [ "$PRIV" = doas ]; then
    ui_note "doas will ask for your password at each system step."
    ui_run() { ui_run_fg "$@"; }
fi

if [ "$BACKEND" = nixos ]; then
    UI_STEPS=4
    nixos_flow || fail "NixOS setup failed"
else
    UI_STEPS=6
    ui_step "Package sources"
    be_setup_repos || fail "Could not enable the required repositories"
    be_refresh || fail "Could not refresh package metadata (network?)"

    ui_step "Dependencies"
    to_install=(); for e in "${P_INSTALL[@]}"; do IFS='|' read -r _ p _ <<<"$e"; to_install+=("$p"); done
    if [ ${#to_install[@]} -gt 0 ]; then
        be_install_pkgs "${to_install[@]}" || fail "Dependency installation failed (no packages were removed)"
        for p in "${to_install[@]}"; do echo "pkg $p" >>"$STATE_FILE.new"; done
    else ui_ok "all dependencies already installed"; fi

    ui_step "Building and installing SSH"
    be_build_and_install "$WORK" || fail "Building or installing the SSH package failed"
    ui_ok "installed: $(be_ssh_installed)"
fi

ui_step "Your settings"
write_config() {
    local appearance
    appearance=$(sed -n 's/.*"appearance": *\({[^}]*}\).*/\1/p' "$REPO/src/themes/presets/$THEME.json")
    [ -n "$appearance" ] || appearance='{}'
    mkdir -p "$CONFIG_DIR"
    cat >"$CONFIG_FILE" <<EOF
{
  "appearance": $appearance,
  "lens": { "enabled": $( [ "${MOD[lens]}" = 1 ] && echo true || echo false) },
  "atlas": { "enabled": $( [ "${MOD[atlas]}" = 1 ] && echo true || echo false) },
  "notifications": { "enabled": $( [ "${MOD[signals]}" = 1 ] && echo true || echo false) },
  "osd": { "enabled": $( [ "${MOD[osd]}" = 1 ] && echo true || echo false) },
  "weather": { "enabled": $( [ "${MOD[weather]}" = 1 ] && echo true || echo false) },
  "commands": { "terminal": ["$TERMINAL_BIN"] }
}
EOF
}
case $CONFIG_ACTION in
    keep) ui_ok "kept $CONFIG_FILE" ;;
    replace)
        b="$CONFIG_FILE.bak-$(date +%Y%m%d-%H%M%S)"
        cp -a "$CONFIG_FILE" "$b" && ui_ok "backed up to $b" || fail "could not back up $CONFIG_FILE"
        echo "config-backup $b" >>"$STATE_FILE.new"
        write_config && ui_ok "wrote $CONFIG_FILE" ;;
    write) write_config && ui_ok "wrote $CONFIG_FILE" ;;
esac
CHECKER=ssh-shell; have ssh-shell || CHECKER="$REPO/bin/ssh-shell"
if [ -f "$CONFIG_FILE" ] && have qs; then
    if out=$("$CHECKER" check-config "$CONFIG_FILE" 2>&1); then ui_ok "settings validated with SSH's schema"
    else ui_warn "settings check: $out"; fi
fi

if [ "$BACKEND" != nixos ]; then
    ui_step "Login screen"
    sess_file="ssh-$DEFAULT_SESSION.desktop"
    if [ $PRESELECT = 1 ]; then
        case $DM in
            sddm)
                f=/var/lib/sddm/state.conf
                if $PRIV test -f "$f"; then
                    b="$f.ssh-backup-$(date +%Y%m%d-%H%M%S)"
                    $PRIV cp -a "$f" "$b" && echo "dm-sddm $b" >>"$STATE_FILE.new"
                    cur=$($PRIV sed -n 's/^Session=//p' "$f" | head -1)
                    val=$sess_file; [[ $cur == */* || -z $cur ]] && val=$(find_session_file "$sess_file" || echo "/usr/share/wayland-sessions/$sess_file")
                    $PRIV cat "$f" | awk -v v="$val" '
                        /^\[/ { if (inlast && !done) { print "Session=" v; done = 1 }
                                inlast = ($0 == "[Last]"); if (inlast) seen = 1 }
                        inlast && /^Session=/ { if (!done) { print "Session=" v; done = 1 }; next }
                        { print }
                        END { if (!done) { if (!seen) print "[Last]"; print "Session=" v } }' >"$WORK/state.conf"
                    if $PRIV sh -c 'cat > "$1"' sh "$f" <"$WORK/state.conf"; then ui_ok "SDDM will preselect $sess_file (backup: $b)"
                    else ui_warn "could not update $f; pick the session on the login screen"; fi
                else
                    ui_note "SDDM has no saved state yet: pick \"Sovereignity Shell\" once on the login screen; SDDM remembers it."
                fi ;;
            gdm|gdm3|lightdm)
                prev=$(busctl get-property org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User Session 2>/dev/null | sed -n 's/^s "\(.*\)"$/\1/p')
                if $PRIV busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User SetSession s "ssh-$DEFAULT_SESSION" >>"$UI_LOG" 2>&1; then
                    $PRIV busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User SetSessionType s wayland >>"$UI_LOG" 2>&1 || true
                    echo "dm-accounts ${prev:-}" >>"$STATE_FILE.new"
                    ui_ok "$DM will preselect ssh-$DEFAULT_SESSION (previous: ${prev:-none})"
                else ui_warn "could not set the session through AccountsService; pick it on the login screen"; fi ;;
        esac
    elif [ -n "$DM" ]; then
        ui_ok "$DM lists the new session(s); pick \"Sovereignity Shell\" at login"
    else
        ui_warn "No display manager detected. Start the session from a TTY with:  ssh-session $DEFAULT_SESSION"
    fi
fi

# ═══ Validate ═══════════════════════════════════════════════════════════
ui_step "Validating the installation"
VFAIL=0
v_ok() { ui_ok "$1"; }
v_bad() { ui_err "$1"; VFAIL=$((VFAIL+1)); }
if [ "$BACKEND" = nixos ] && [ "${NIXOS_REBUILT:-0}" = 0 ] && ! have ssh-shell; then
    ui_note "Skipped until you rebuild your system."
else
    have ssh-shell && v_ok "ssh-shell $(ssh-shell version) on PATH" || v_bad "ssh-shell is not on PATH"
    have ssh-session && v_ok "ssh-session on PATH" || v_bad "ssh-session is not on PATH"
    have qs && v_ok "Quickshell $(qs --version 2>/dev/null | head -1 | awk '{print $2}')" || v_bad "Quickshell (qs) is not installed"
    for c in hyprland niri; do
        [ "$c" = hyprland ] && [ $WANT_HYPRLAND = 0 ] && continue
        [ "$c" = niri ] && [ $WANT_NIRI = 0 ] && continue
        detect_compositors
        bin=Hyprland; [ $c = niri ] && bin=niri
        have "$bin" && v_ok "$bin $(comp_version $c) installed" || v_bad "$bin is not installed"
        if s=$(find_session_file "ssh-$c.desktop"); then v_ok "login session: $s"; else v_bad "login session ssh-$c.desktop missing"; fi
        if s=$(find_session_file "$c.desktop"); then v_ok "recovery session kept: $s"
        else ui_warn "no plain $c session file found (your compositor package normally provides one)"; fi
        if out=$(ssh-session --check "$c" 2>&1); then v_ok "session start-up check ($c) passed"
        else v_bad "session start-up check ($c) failed:"; echo "$out" | sed 's/^/      /'; fi
        log "$out"
    done
    ssh-shell doctor >>"$UI_LOG" 2>&1 && v_ok "ssh-shell doctor: no problems" || ui_warn "ssh-shell doctor reported problems (details in the log)"
fi

if [ -s "$STATE_FILE.new" ]; then cat "$STATE_FILE.new" >>"$STATE_FILE"; fi
rm -f "$STATE_FILE.new"
{ echo "installed $(date '+%F %T') backend=$BACKEND sessions=$( [ $WANT_HYPRLAND = 1 ] && printf 'hyprland ')$( [ $WANT_NIRI = 1 ] && printf 'niri')"; } >>"$STATE_FILE"

if [ $VFAIL -gt 0 ]; then
    printf '\n  %s%d validation check(s) failed.%s See above and %s.\n' "$C_ERR" "$VFAIL" "$C_RESET" "$UI_LOG"
    printf '  Your previous sessions are untouched. Run "ssh-shell doctor" after fixing.\n\n'
    exit 1
fi

# ═══ Done ═══════════════════════════════════════════════════════════════
label="Sovereignity Shell ($( [ $DEFAULT_SESSION = hyprland ] && echo Hyprland || echo Niri))"
printf '\n%s' "$C_ACCENT$C_BOLD"
printf '  ┌──────────────────────────────────────────────┐\n'
printf '  │                                              │\n'
printf '  │             SOVEREIGNITY SHELL               │\n'
printf '  │                                              │\n'
printf '  │           INSTALLATION COMPLETE              │\n'
printf '  │                                              │\n'
printf '  │          Your new desktop is ready.          │\n'
printf '  │                                              │\n'
printf '  └──────────────────────────────────────────────┘\n'
printf '%s\n' "$C_RESET"
if [ "$BACKEND" = nixos ] && [ "${NIXOS_REBUILT:-0}" = 0 ]; then
    printf '  Finish by adding the module and running: sudo nixos-rebuild switch\n\n'
    exit 0
fi
if [ -n "$DM" ]; then printf '  At the login screen choose  %s%s%s.\n' "$C_BOLD" "$label" "$C_RESET"
else printf '  From a text console, log in and run  %sssh-session %s%s.\n' "$C_BOLD" "$DEFAULT_SESSION" "$C_RESET"; fi
printf '  SSH starts by itself. The plain %s session stays available for recovery.\n' "$( [ $DEFAULT_SESSION = hyprland ] && echo Hyprland || echo Niri)"
printf '  If anything goes wrong: ssh-shell doctor · logs in %s\n' "$STATE_DIR"

reboot_now() {
    if have systemctl && [ -d /run/systemd/system ]; then systemctl reboot || $PRIV systemctl reboot
    else $PRIV reboot; fi
}
if [ "$UI_YES" = 1 ]; then printf '\n  Reboot when convenient (unattended mode never reboots).\n\n'; exit 0; fi
if [ "$UI_MODE" = rich ]; then
    sel=1; ui_cursor_hide; echo
    while :; do
        if [ $sel = 0 ]; then printf '\r\e[K   %s[ REBOOT NOW ]%s    [ REBOOT LATER ]   ' "$C_INV$C_BOLD" "$C_RESET"
        else printf '\r\e[K   [ REBOOT NOW ]    %s[ REBOOT LATER ]%s   ' "$C_INV$C_BOLD" "$C_RESET"; fi
        k=$(ui_key)
        case $k in left) sel=0 ;; right) sel=1 ;; up|down|tab) sel=$((1-sel)) ;; enter) break ;; q|esc) sel=1; break ;; esac
    done
    ui_cursor_show; echo
else
    printf '\n   1) REBOOT NOW\n   2) REBOOT LATER\n  Choice [2]: '; IFS= read -r k || k=2
    sel=1; [ "$k" = 1 ] && sel=0
fi
if [ $sel = 0 ] && ui_confirm "Reboot now? Save your work in other applications first." n; then
    reboot_now
else
    printf '\n  Reboot or log out when you are ready.\n\n'
fi
