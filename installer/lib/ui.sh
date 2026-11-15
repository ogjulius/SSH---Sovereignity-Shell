# shellcheck shell=bash
# Terminal UI for the SSH installer.
#
# Two modes, chosen automatically:
#   rich   arrow-key menus and checklists drawn in place, colours, spinners
#   plain  numbered prompts, no cursor movement: used when stdin/stdout is not
#          a terminal, TERM is dumb/unknown, the terminal is narrower than 60
#          columns, or --plain was given
# In --yes mode nothing is asked: every prompt returns its default.

UI_MODE=rich
UI_YES=0
UI_LOG=/dev/null

ui_init() {
    local plain=$1
    if [ "$plain" = 1 ] || [ ! -t 0 ] || [ ! -t 1 ] || [ "${TERM:-dumb}" = dumb ] \
        || ! command -v tput >/dev/null 2>&1 || ! tput cols >/dev/null 2>&1 || [ "$(tput cols 2>/dev/null || echo 0)" -lt 60 ]; then
        UI_MODE=plain
    fi
    if [ "$UI_MODE" = rich ] && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
        C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'
        C_ACCENT=$'\e[38;5;180m'; C_OK=$'\e[32m'; C_WARN=$'\e[33m'; C_ERR=$'\e[31m'; C_INV=$'\e[7m'
    else
        C_RESET=; C_BOLD=; C_DIM=; C_ACCENT=; C_OK=; C_WARN=; C_ERR=; C_INV=
    fi
    G_OK="✓"; G_ADD="+"; G_BAD="✗"; G_WARN="!"; G_ARROW="›"; G_ON="[x]"; G_OFF="[ ]"
    if [ "$UI_MODE" = plain ] || ! locale 2>/dev/null | grep -qi 'utf-\?8'; then
        G_OK="ok"; G_ADD="+"; G_BAD="x"; G_WARN="!"; G_ARROW=">"
    fi
}

ui_cursor_hide() { [ "$UI_MODE" = rich ] && printf '\e[?25l'; }
ui_cursor_show() { [ "$UI_MODE" = rich ] && printf '\e[?25h'; }

ui_banner() {
    printf '\n%s' "$C_ACCENT$C_BOLD"
    cat <<'EOF'
   ███████ ███████ ██   ██
   ██      ██      ██   ██     S O V E R E I G N I T Y
   ███████ ███████ ███████     S H E L L
        ██      ██ ██   ██
   ███████ ███████ ██   ██     installer
EOF
    printf '%s\n' "$C_RESET"
}

ui_title() { printf '\n%s%s %s%s\n' "$C_ACCENT$C_BOLD" "$G_ARROW" "$1" "$C_RESET"; }
ui_note()  { printf '  %s%s%s\n' "$C_DIM" "$1" "$C_RESET"; }
ui_ok()    { printf '  %s%s%s %s\n' "$C_OK" "$G_OK" "$C_RESET" "$1"; }
ui_add()   { printf '  %s%s%s %s\n' "$C_ACCENT" "$G_ADD" "$C_RESET" "$1"; }
ui_warn()  { printf '  %s%s%s %s\n' "$C_WARN" "$G_WARN" "$C_RESET" "$1"; }
ui_err()   { printf '  %s%s%s %s\n' "$C_ERR" "$G_BAD" "$C_RESET" "$1" >&2; }
ui_kv()    { printf '  %-22s %s\n' "$1" "$2"; }

# Reads one key; prints a name: up down enter space esc q a or the character.
ui_key() {
    local k rest
    IFS= read -rsn1 k || { echo q; return; }
    if [ "$k" = $'\e' ]; then
        IFS= read -rsn2 -t 0.05 rest || true
        case $rest in '[A'|'OA') echo up ;; '[B'|'OB') echo down ;; '[C'|'OC') echo right ;; '[D'|'OD') echo left ;; '') echo esc ;; *) echo other ;; esac
        return
    fi
    case $k in '') echo enter ;; ' ') echo space ;; $'\t') echo tab ;; k|K) echo up ;; j|J) echo down ;; h|H) echo left ;; l|L) echo right ;; *) printf '%s\n' "$k" ;; esac
}

# ui_menu VAR "Question" "help" DEFAULT_INDEX option...
# Option text may carry a description after a tab. Sets VAR to the chosen index.
ui_menu() {
    local __var=$1 q=$2 help=$3 sel=$4; shift 4
    local opts=("$@") n=$# i key
    if [ "$UI_YES" = 1 ]; then printf -v "$__var" '%s' "$sel"; return; fi
    ui_title "$q"; [ -n "$help" ] && ui_note "$help"
    if [ "$UI_MODE" = plain ]; then
        for i in "${!opts[@]}"; do printf '   %d) %s\n' $((i+1)) "${opts[$i]//$'\t'/ — }"; done
        while :; do
            printf '  Choice [%d]: ' $((sel+1)); IFS= read -r key || key=""
            [ -z "$key" ] && break
            if [[ $key =~ ^[0-9]+$ ]] && [ "$key" -ge 1 ] && [ "$key" -le "$n" ]; then sel=$((key-1)); break; fi
            echo "  Please enter a number from 1 to $n."
        done
        printf -v "$__var" '%s' "$sel"; return
    fi
    ui_note "↑/↓ to move, Enter to choose"
    ui_cursor_hide
    local first=1
    while :; do
        [ $first = 1 ] || printf '\e[%dA' "$n"
        first=0
        for i in "${!opts[@]}"; do
            local label=${opts[$i]%%$'\t'*} desc=""
            [[ ${opts[$i]} == *$'\t'* ]] && desc=${opts[$i]#*$'\t'}
            if [ "$i" = "$sel" ]; then printf '\r\e[K   %s%s %s%s %s%s%s\n' "$C_ACCENT$C_BOLD" "$G_ARROW" "$label" "$C_RESET" "$C_DIM" "$desc" "$C_RESET"
            else printf '\r\e[K     %s %s%s%s\n' "$label" "$C_DIM" "$desc" "$C_RESET"; fi
        done
        key=$(ui_key)
        case $key in
            up) sel=$(( (sel - 1 + n) % n )) ;;
            down) sel=$(( (sel + 1) % n )) ;;
            enter) break ;;
            q|esc) ui_cursor_show; ui_abort ;;
            [1-9]) [ "$key" -le "$n" ] && sel=$((key-1)) ;;
        esac
    done
    ui_cursor_show
    printf -v "$__var" '%s' "$sel"
}

# ui_checklist ARRAYVAR "Question" "help" option...
# ARRAYVAR holds the initial 0/1 states and receives the result. Options whose
# state is "-" are shown but locked (required, or unavailable).
ui_checklist() {
    local __arr=$1 q=$2 help=$3; shift 3
    local opts=("$@") n=$# sel=0 i key
    local -n __st=$__arr
    [ "$UI_YES" = 1 ] && return
    ui_title "$q"; [ -n "$help" ] && ui_note "$help"
    if [ "$UI_MODE" = plain ]; then
        while :; do
            for i in "${!opts[@]}"; do
                local mark=$G_OFF; [ "${__st[$i]}" = 1 ] && mark=$G_ON; [ "${__st[$i]}" = "-" ] && mark="[-]"
                printf '   %2d) %s %s\n' $((i+1)) "$mark" "${opts[$i]//$'\t'/ — }"
            done
            printf '  Numbers to toggle (e.g. "2 4"), Enter to accept: '; IFS= read -r key || key=""
            [ -z "$key" ] && break
            for i in $key; do
                if [[ $i =~ ^[0-9]+$ ]] && [ "$i" -ge 1 ] && [ "$i" -le "$n" ] && [ "${__st[$((i-1))]}" != "-" ]; then
                    __st[$((i-1))]=$(( 1 - __st[$((i-1))] ))
                fi
            done
        done
        return
    fi
    ui_note "↑/↓ to move, Space to toggle, Enter to accept"
    ui_cursor_hide
    local first=1
    while :; do
        [ $first = 1 ] || printf '\e[%dA' "$n"
        first=0
        for i in "${!opts[@]}"; do
            local label=${opts[$i]%%$'\t'*} desc="" mark=$G_OFF
            [[ ${opts[$i]} == *$'\t'* ]] && desc=${opts[$i]#*$'\t'}
            [ "${__st[$i]}" = 1 ] && mark="$C_OK$G_ON$C_RESET"
            [ "${__st[$i]}" = "-" ] && mark="$C_DIM[-]$C_RESET"
            local pre="     "; [ "$i" = "$sel" ] && pre="   $C_ACCENT$G_ARROW$C_RESET "
            printf '\r\e[K%s%s %s %s%s%s\n' "$pre" "$mark" "$label" "$C_DIM" "$desc" "$C_RESET"
        done
        key=$(ui_key)
        case $key in
            up) sel=$(( (sel - 1 + n) % n )) ;;
            down) sel=$(( (sel + 1) % n )) ;;
            space) [ "${__st[$sel]}" != "-" ] && __st[$sel]=$(( 1 - __st[$sel] )) ;;
            enter) break ;;
            q|esc) ui_cursor_show; ui_abort ;;
        esac
    done
    ui_cursor_show
}

# ui_confirm "Question" y|n  → returns 0 for yes.
ui_confirm() {
    local q=$1 def=$2 key
    if [ "$UI_YES" = 1 ]; then [ "$def" = y ]; return; fi
    local hint="[Y/n]"; [ "$def" = n ] && hint="[y/N]"
    while :; do
        printf '\n  %s%s%s %s ' "$C_BOLD" "$q" "$C_RESET" "$hint"
        IFS= read -r key || key=""
        case ${key:-$def} in y|Y|yes|YES) return 0 ;; n|N|no|NO) return 1 ;; esac
    done
}

ui_abort() { printf '\n  Cancelled. Nothing further was changed.\n'; exit 130; }

# ── Progress ────────────────────────────────────────────────────────────
UI_STEP=0
UI_STEPS=0
ui_step() { UI_STEP=$((UI_STEP+1)); printf '\n%s[%d/%d]%s %s%s%s\n' "$C_ACCENT" "$UI_STEP" "$UI_STEPS" "$C_RESET" "$C_BOLD" "$1" "$C_RESET"; }

# ui_run "label" command...   output goes to the log; the last log line is
# shown live next to a spinner. Returns the command's status; on failure the
# end of the log is printed.
ui_run() {
    local label=$1; shift
    printf '\n$ %s\n' "$*" >>"$UI_LOG"
    if [ "$UI_MODE" = plain ]; then
        printf '  … %s\n' "$label"
        "$@" >>"$UI_LOG" 2>&1 </dev/null
        local rc=$?
        if [ $rc -eq 0 ]; then ui_ok "$label"; else ui_err "$label (exit $rc)"; ui_tail; fi
        return $rc
    fi
    "$@" >>"$UI_LOG" 2>&1 </dev/null &
    local pid=$! frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' f=0 start=$SECONDS cols last
    cols=$(tput cols 2>/dev/null || echo 80)
    ui_cursor_hide
    while kill -0 $pid 2>/dev/null; do
        last=$(tail -n 1 "$UI_LOG" 2>/dev/null | tr -d '\r' | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')
        local line="  ${frames:f%10:1} $label ($((SECONDS-start))s)  $last"
        printf '\r\e[K%s%s%s' "$C_DIM" "${line:0:$((cols-1))}" "$C_RESET"
        f=$((f+1)); sleep 0.12
    done
    wait $pid; local rc=$?
    ui_cursor_show
    printf '\r\e[K'
    if [ $rc -eq 0 ]; then ui_ok "$label ${C_DIM}($((SECONDS-start))s)${C_RESET}"; else ui_err "$label (exit $rc)"; ui_tail; fi
    return $rc
}

# For commands that may need the terminal (a password prompt).
ui_run_fg() {
    local label=$1; shift
    printf '\n$ %s\n' "$*" >>"$UI_LOG"
    printf '  … %s\n' "$label"
    "$@" 2>&1 | tee -a "$UI_LOG"
    local rc=${PIPESTATUS[0]}
    if [ $rc -eq 0 ]; then ui_ok "$label"; else ui_err "$label (exit $rc)"; fi
    return $rc
}

ui_tail() {
    printf '  %s── last lines of %s ──%s\n' "$C_DIM" "$UI_LOG" "$C_RESET"
    tail -n 15 "$UI_LOG" | sed 's/^/    /'
}
