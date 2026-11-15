.pragma library
// SSH's keybinds: one action table, one structured list, three outputs.
//
// The `keybinds` options (configuration/Schema.js) map each action to a key in
// Hyprland notation, "MODS, KEY" (e.g. "SUPER SHIFT, ESCAPE"). Every bind runs
// a stable `ssh-shell` CLI verb: binds are thin wrappers, never logic. The
// same list feeds the Hyprland (classic and Lua) and Niri blocks, the runtime
// binds of the SSH login sessions, Settings → Keys, `ssh-shell keybinds list`
// and the cheatsheet. Rationale and defaults: docs/KEYBINDS.md.

// [action, CLI verb args, label, description]
var ACTIONS = [
    ["launcher", ["launcher", "toggle"], "Launcher", "Search and start applications"],
    ["terminal", ["terminal"], "Terminal", "Open your terminal (commands.terminal)"],
    ["atlas", ["atlas", "toggle"], "Atlas", "The map of your workspaces"],
    ["lens", ["lens", "toggle"], "Lens", "Compass around the current cell"],
    ["instruments", ["panel", "toggle", "instruments"], "Instruments", "Audio, network, Bluetooth, brightness, power"],
    ["signals", ["panel", "toggle", "signals"], "Signals", "Notifications and their history"],
    ["almanac", ["panel", "toggle", "almanac"], "Almanac", "Calendar, weather, system load, media"],
    ["settings", ["settings", "toggle"], "Settings", "SSH's settings window"],
    ["power", ["panel", "toggle", "power"], "Power menu", "Lock, suspend, leave, restart, power off"],
    ["cheatsheet", ["keybinds", "cheatsheet"], "Cheatsheet", "Show every SSH keybind"]
];
// Modifier-only actions, combined with the arrow keys.
var MOVES = [
    ["traverse", "atlas", "traverse", "Travel", "Move to the neighbouring cell"],
    ["carry", "atlas", "carry", "Carry", "Take the focused window to the neighbouring cell"]
];
var DIRS = ["left", "right", "up", "down"];
var MEDIA = [
    ["XF86AudioRaiseVolume", ["audio", "up"], true],
    ["XF86AudioLowerVolume", ["audio", "down"], true],
    ["XF86AudioMute", ["audio", "mute"], false],
    ["XF86AudioMicMute", ["audio", "mic"], false],
    ["XF86MonBrightnessUp", ["brightness", "up"], true],
    ["XF86MonBrightnessDown", ["brightness", "down"], true]
];

function split(s) {
    var p = String(s || "").split(",");
    return { mods: (p[0] || "").trim(), key: (p[1] || "").trim() };
}
function cmd(args) { return "ssh-shell " + args.join(" "); }

// Every bind as { action, mods, key, args, media, repeat }. Unset (empty)
// keybinds are left out.
function specs(kb) {
    var out = [], i, d;
    for (i = 0; i < ACTIONS.length; i++) {
        var k = split(kb[ACTIONS[i][0]]);
        if (k.key) out.push({ action: ACTIONS[i][0], mods: k.mods, key: k.key, args: ACTIONS[i][1], media: false, repeat: false });
    }
    for (i = 0; i < MOVES.length; i++) {
        var mods = String(kb[MOVES[i][0]] || "").trim();
        if (!mods) continue;
        for (d = 0; d < DIRS.length; d++)
            out.push({ action: MOVES[i][0], mods: mods, key: DIRS[d], args: [MOVES[i][1], MOVES[i][2], DIRS[d]], media: false, repeat: false });
    }
    for (i = 0; i < MEDIA.length; i++)
        out.push({ action: "media", mods: "", key: MEDIA[i][0], args: MEDIA[i][1], media: true, repeat: MEDIA[i][2] });
    return out;
}

// ── Display ─────────────────────────────────────────────────────────────
function prettyKey(k) {
    var names = { SPACE: "Space", RETURN: "Return", ESCAPE: "Esc", COMMA: ",", PERIOD: ".", SLASH: "/", TAB: "Tab", LEFT: "←", RIGHT: "→", UP: "↑", DOWN: "↓" };
    var u = String(k).toUpperCase();
    return names[u] || (u.length === 1 ? u : u.charAt(0) + u.slice(1).toLowerCase());
}
function prettyMods(m) {
    return String(m || "").split(/\s+/).filter(function (x) { return x.length; }).map(function (x) {
        var u = x.toUpperCase();
        return u === "SUPER" ? "Super" : u === "ALT" ? "Alt" : u === "SHIFT" ? "Shift" : (u === "CTRL" || u === "CONTROL") ? "Ctrl" : x;
    }).join("+");
}
function pretty(binding) {
    var k = split(binding);
    if (!k.key) return "unbound";
    var m = prettyMods(k.mods);
    return (m ? m + "+" : "") + prettyKey(k.key);
}

// Rows for Settings, `keybinds list` and the cheatsheet:
// [{ action, label, keys, verb, description }]
function table(kb) {
    var rows = [], i;
    for (i = 0; i < ACTIONS.length; i++)
        rows.push({ action: ACTIONS[i][0], label: ACTIONS[i][2], keys: pretty(kb[ACTIONS[i][0]]), verb: cmd(ACTIONS[i][1]), description: ACTIONS[i][3] });
    for (i = 0; i < MOVES.length; i++) {
        var m = prettyMods(kb[MOVES[i][0]]);
        rows.push({ action: MOVES[i][0], label: MOVES[i][3], keys: m ? m + "+arrows" : "unbound", verb: "ssh-shell " + MOVES[i][1] + " " + MOVES[i][2] + " <direction>", description: MOVES[i][4] });
    }
    rows.push({ action: "close", label: "Close", keys: "Esc", verb: "ssh-shell panel close", description: "Close the open SSH surface (SSH handles it; not a compositor bind)" });
    return rows;
}
function listText(kb) {
    var rows = table(kb), w1 = 6, w2 = 4, i, out = [];
    for (i = 0; i < rows.length; i++) { w1 = Math.max(w1, rows[i].label.length); w2 = Math.max(w2, rows[i].keys.length); }
    function pad(s, n) { while (s.length < n) s += " "; return s; }
    out.push(pad("ACTION", w1) + "  " + pad("KEYS", w2) + "  COMMAND");
    for (i = 0; i < rows.length; i++) out.push(pad(rows[i].label, w1) + "  " + pad(rows[i].keys, w2) + "  " + rows[i].verb);
    return out.join("\n");
}

// ── Hyprland (classic) ──────────────────────────────────────────────────
function hyprlandKeyword(b) {
    return "keyword " + (b.media ? (b.repeat ? "bindel" : "bindl") : "bind") + " " + b.mods + ", " + b.key + ", exec, " + cmd(b.args);
}
function hyprlandUnkeyword(b) { return "keyword unbind " + b.mods + ", " + b.key; }
function hyprland(kb) {
    var out = ["# SSH — Sovereignity Shell keybinds (generated by `ssh-shell keybinds hyprland`)"];
    var list = specs(kb);
    for (var i = 0; i < list.length; i++) out.push(hyprlandKeyword(list[i]).replace(/^keyword (\w+) /, "$1 = "));
    out.push("layerrule = blur, ^(ssh-.*)$");
    out.push("layerrule = ignorezero, ^(ssh-.*)$");
    return out.join("\n");
}

// ── Hyprland ≥ 0.55 Lua (syntax from Hyprland's shipped hyprland.lua) ────
function luaCombo(mods, key) {
    var parts = String(mods || "").split(/\s+/).filter(function (m) { return m.length; });
    parts.push(key);
    return parts.join(" + ");
}
function hyprlandLuaBind(b) {
    var opts = b.media ? (b.repeat ? ", { locked = true, repeating = true }" : ", { locked = true }") : "";
    return "hl.bind(\"" + luaCombo(b.mods, b.key) + "\", hl.dsp.exec_cmd(\"" + cmd(b.args) + "\")" + opts + ")";
}
function hyprlandLuaUnbind(b) { return "hl.unbind(\"" + luaCombo(b.mods, b.key) + "\")"; }
function hyprlandLua(kb) {
    var out = ["-- SSH — Sovereignity Shell keybinds (generated by `ssh-shell keybinds hyprland-lua`)",
               "hl.on(\"hyprland.start\", function () hl.exec_cmd(\"ssh-shell --daemon\") end)"];
    var list = specs(kb);
    for (var i = 0; i < list.length; i++) out.push(hyprlandLuaBind(list[i]));
    return out.join("\n");
}

// ── Niri ────────────────────────────────────────────────────────────────
var NIRI_MODS = { SUPER: "Mod", MOD: "Mod", ALT: "Alt", SHIFT: "Shift", CTRL: "Ctrl", CONTROL: "Ctrl" };
function niriCombo(mods, key) {
    var parts = String(mods || "").split(/\s+/).filter(function (m) { return m.length; }).map(function (m) { return NIRI_MODS[m.toUpperCase()] || m; });
    var k = key.length === 1 ? key.toUpperCase() : (key.indexOf("XF86") === 0 ? key : key.charAt(0).toUpperCase() + key.slice(1).toLowerCase());
    parts.push(k);
    return parts.join("+");
}
function niriSpawn(args) { return "spawn \"ssh-shell\"" + args.map(function (a) { return " \"" + a + "\""; }).join("") + ";"; }
function niri(kb) {
    var out = ["// SSH — Sovereignity Shell keybinds (generated by `ssh-shell keybinds niri`)", "binds {"];
    var list = specs(kb);
    for (var i = 0; i < list.length; i++)
        out.push("    " + niriCombo(list[i].mods, list[i].key) + (list[i].media ? " allow-when-locked=true" : "") + " { " + niriSpawn(list[i].args) + " }");
    out.push("}");
    return out.join("\n");
}

// ── Runtime binds in SSH sessions (services/SessionBinds.qml) ───────────
// Hyprland's modifier bitmask, as reported by `hyprctl binds -j`.
var MASK = { SHIFT: 1, CAPS: 2, CTRL: 4, CONTROL: 4, ALT: 8, MOD2: 16, MOD3: 32, SUPER: 64, WIN: 64, LOGO: 64, MOD4: 64, META: 64, MOD5: 128 };
function hyprMask(mods) {
    var m = 0, parts = String(mods || "").toUpperCase().split(/[\s_+]+/);
    for (var i = 0; i < parts.length; i++) if (MASK[parts[i]]) m |= MASK[parts[i]];
    return m;
}
function comboId(mask, key) { return mask + ":" + String(key).toLowerCase(); }
// Splits specs into those whose key combination is free and those the
// user's compositor config already binds (`taken`: [{ modmask, key }]).
function partition(list, taken) {
    var used = {};
    for (var i = 0; i < taken.length; i++) if (!taken[i].submap) used[comboId(taken[i].modmask, taken[i].key)] = true;
    var free = [], skipped = [];
    for (var j = 0; j < list.length; j++) (used[comboId(hyprMask(list[j].mods), list[j].key)] ? skipped : free).push(list[j]);
    return { free: free, skipped: skipped };
}

// target: hyprland | hyprland-lua | niri | list
function generate(target, kb) {
    if (target === "niri") return niri(kb);
    if (target === "hyprland-lua") return hyprlandLua(kb);
    if (target === "list") return listText(kb);
    return hyprland(kb);
}
