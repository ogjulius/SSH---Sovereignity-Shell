#!/usr/bin/env bash
# Capture genuine screenshots of a live SSH session (Hyprland + grim).
#
#   scripts/capture-screenshots.sh [--only "name name..."] [OUTDIR]
#   names: meridian lens atlas launcher almanac power instruments signals popups settings
#
# Privacy-safe by construction:
# - SSH runs on a private D-Bus session with isolated XDG config/state, so
#   your notification daemon, settings and Atlas map are untouched, and the
#   notifications shown are ones this script sends.
# - Captures happen on an empty workspace (picked automatically) so no
#   personal windows are visible; you are returned to your workspace after.
# - Window previews are disabled, plates are opaque and the Lens dim is at
#   its maximum, so other desktop components barely show; panels are cropped
#   to SSH's own pixels using `ssh-shell shell rect`.
# - The Wi-Fi network name in the control centre is pixelated (disclosed in
#   the gallery). Review every image before publishing.
set -euo pipefail
cd "$(dirname "$0")/.."
ONLY=""
if [ "${1:-}" = "--only" ]; then ONLY=$2; shift 2; fi
OUT=${1:-assets/screenshots}
export ONLY
command -v grim >/dev/null || { echo "needs grim"; exit 1; }
command -v hyprctl >/dev/null || { echo "this capture script currently supports Hyprland"; exit 1; }

cursor=$(hyprctl cursorpos | tr -d ' ')
orig=$(hyprctl activeworkspace -j | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')
used=$(hyprctl workspaces -j | python3 -c 'import json,sys;print(" ".join(str(w["id"]) for w in json.load(sys.stdin)))')
empty=9; for n in 9 8 7 6 5 10; do case " $used " in *" $n "*) ;; *) empty=$n; break;; esac; done

tmp=$(mktemp -d); restore() {
    hyprctl dispatch "hl.dsp.focus({ workspace = $orig })" >/dev/null 2>&1 || hyprctl dispatch workspace "$orig" >/dev/null 2>&1
    hyprctl dispatch "hl.dsp.cursor.move({ x = ${cursor%,*}, y = ${cursor#*,} })" >/dev/null 2>&1 || true
    rm -rf "$tmp"
}
trap restore EXIT
mkdir -p "$tmp/config/ssh-shell" "$tmp/state/ssh-shell"
cat > "$tmp/config/ssh-shell/config.json" <<JSON
{ "atlas": { "previews": false }, "lens": { "dim": 0.95 }, "appearance": { "opacity": 1 }, "meridian": { "showTitle": false } }
JSON
# A small demo map (cell names only) so the Atlas and Lens have places to show.
python3 - "$tmp/state/ssh-shell/atlas.json" "$empty" <<'PY'
import json, sys
path, ws = sys.argv[1], int(sys.argv[2])
cells = {"1,1": {"ref": "id:%d" % ws, "name": "Studio"}, "0,1": {"name": "Notes"}, "2,1": {"name": "Build"},
         "1,0": {"name": "Mail"}, "1,2": {"name": "Music"}, "3,0": {"name": "Reading"}, "3,1": {"name": "Review"}}
json.dump({"version": 1, "active": "c1", "collections": [
    {"id": "c1", "name": "Main", "cursor": {"x": 1, "y": 1}, "cells": cells},
    {"id": "c2", "name": "Studio", "cursor": {"x": 0, "y": 0}, "cells": {}}]}, open(path, "w"))
PY

mkdir -p "$OUT"/{desktop-bar,launcher,control-center,sovereign-space,infinite-desktop,notifications,settings,hyprland}
hyprctl dispatch "hl.dsp.focus({ workspace = $empty })" >/dev/null 2>&1 || hyprctl dispatch workspace "$empty" >/dev/null
sleep 0.6
W=$(hyprctl monitors -j | python3 -c 'import json,sys;m=[x for x in json.load(sys.stdin) if x["focused"]][0];print(int(m["width"]/m["scale"]), int(m["height"]/m["scale"]))')
hyprctl dispatch "hl.dsp.cursor.move({ x = ${W% *}, y = ${W#* } })" >/dev/null 2>&1 || true

export XDG_CONFIG_HOME="$tmp/config" XDG_STATE_HOME="$tmp/state"
dbus-run-session -- bash -s "$OUT" <<'INNER'
set -u
OUT=$1
want() { [ -z "$ONLY" ] || case " $ONLY " in *" $1 "*) return 0;; *) return 1;; esac; }
ipc() { qs -p src ipc call "$@" >/dev/null 2>&1; }
qs -n -p src >/dev/null 2>&1 &
until qs -p src ipc call shell status >/dev/null 2>&1; do sleep 0.1; done
sleep 2
geo() { hyprctl layers -j | python3 -c "
import json,sys
want=sys.argv[1]
for mon in json.load(sys.stdin).values():
  for ls in mon['levels'].values():
    for l in ls:
      if l['namespace']==want: print('%d,%d %dx%d'%(l['x'],l['y'],l['w'],l['h'])); sys.exit()" "$1"; }
shot() { sleep "${3:-1.4}"; grim ${2:+-g "$2"} "$OUT/$1"; echo "captured $1"; }
panel() { # open a surface and capture only its content rectangle
    ipc shell open "$1"; sleep 1.4
    local r o g
    r=$(qs -p src ipc call shell rect 2>/dev/null)      # window-relative
    o=$(geo "ssh-$1")                                    # window position on screen
    g=$(python3 -c "import sys;r,o=sys.argv[1],sys.argv[2];rx,ry=map(int,r.split()[0].split(','));wh=r.split()[1];ox,oy=map(int,o.split()[0].split(','));print('%d,%d %s'%(ox+rx,oy+ry,wh))" "$r" "$o" 2>/dev/null)
    grim ${g:+-g "$g"} "$OUT/$2"; echo "captured $2 ($g)"
    ipc panel close; sleep 0.4
}

want meridian && shot desktop-bar/meridian.png "$(geo ssh-meridian)" 0.5
want lens  && { ipc shell open lens;  shot sovereign-space/lens.png;   ipc panel close; sleep 0.4; }
want atlas && { ipc shell open atlas; shot infinite-desktop/atlas.png; ipc panel close; sleep 0.4; }
want launcher    && panel launcher    launcher/launcher.png
want almanac     && panel almanac     desktop-bar/almanac.png
want power       && panel power       hyprland/power-menu.png
want instruments && panel instruments control-center/instruments.png
if want popups || want signals; then
    notify-send -a "SSH" "Welcome to the Atlas" "Travel with Super+Alt+arrows."
    notify-send -a "Build" -u critical "Build failed" "Critical signals stay until dismissed."
    ( notify-send -a "Mail" -A "open=Open" -A "later=Later" "Weekly report" "Two actions, rendered by SSH." & )
    want popups && shot notifications/popups.png "$(sleep 1.2; geo ssh-toasts)" 0.3
    want signals && panel signals notifications/signals.png
    ipc notifications clear; sleep 0.6
fi
if want settings; then
    ipc settings open; sleep 1.8
    g=$(hyprctl clients -j | python3 -c "import json,sys;c=[x for x in json.load(sys.stdin) if x['title']=='SSH Settings'];print('%d,%d %dx%d'%(c[0]['at'][0],c[0]['at'][1],c[0]['size'][0],c[0]['size'][1]) if c else '')")
    grim ${g:+-g "$g"} "$OUT/settings/settings.png"; echo "captured settings/settings.png ($g)"
    ipc settings toggle; sleep 0.3
fi
qs -p src kill >/dev/null 2>&1
INNER
# Redact the Wi-Fi network name (first key's detail line) in the control centre.
if command -v magick >/dev/null && [ -f "$OUT/control-center/instruments.png" ]; then
    f="$OUT/control-center/instruments.png"
    magick "$f" \( +clone -crop 104x20+24+108 +repage -scale 10% -scale 1000% \) -geometry +24+108 -composite "$f"
fi
echo "done; review images in $OUT before committing"
