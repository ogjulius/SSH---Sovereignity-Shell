.pragma library
// Generates compositor keybind blocks from SSH's `shortcuts` config.
// Shortcuts use Hyprland notation: "MODS, KEY" (e.g. "SUPER SHIFT, ESCAPE").

var ACTIONS = [
    ["lens", ["lens", "toggle"]],
    ["launcher", ["launcher", "toggle"]],
    ["atlas", ["atlas", "toggle"]],
    ["instruments", ["panel", "toggle", "instruments"]],
    ["power", ["panel", "toggle", "power"]]
];
var DIRS = [["left", "Left"], ["right", "Right"], ["up", "Up"], ["down", "Down"]];

function split(s) {
    var p = String(s || "").split(",");
    return { mods: (p[0] || "").trim(), key: (p[1] || "").trim() };
}

function hyprland(sc) {
    var out = ["# SSH — Sovereignity Shell (generated)"];
    for (var i = 0; i < ACTIONS.length; i++) {
        var k = split(sc[ACTIONS[i][0]]);
        if (!k.key) continue;
        out.push("bind = " + k.mods + ", " + k.key + ", exec, ssh-shell " + ACTIONS[i][1].join(" "));
    }
    for (var d = 0; d < DIRS.length; d++) {
        if (sc.traverse) out.push("bind = " + sc.traverse + ", " + DIRS[d][0] + ", exec, ssh-shell atlas traverse " + DIRS[d][0]);
        if (sc.carry) out.push("bind = " + sc.carry + ", " + DIRS[d][0] + ", exec, ssh-shell atlas carry " + DIRS[d][0]);
    }
    out.push("bindel = , XF86AudioRaiseVolume, exec, ssh-shell audio up");
    out.push("bindel = , XF86AudioLowerVolume, exec, ssh-shell audio down");
    out.push("bindl = , XF86AudioMute, exec, ssh-shell audio mute");
    out.push("bindl = , XF86AudioMicMute, exec, ssh-shell audio mic");
    out.push("bindel = , XF86MonBrightnessUp, exec, ssh-shell brightness up");
    out.push("bindel = , XF86MonBrightnessDown, exec, ssh-shell brightness down");
    out.push("layerrule = blur, ^(ssh-.*)$");
    out.push("layerrule = ignorezero, ^(ssh-.*)$");
    return out.join("\n");
}

var NIRI_MODS = { SUPER: "Mod", MOD: "Mod", ALT: "Alt", SHIFT: "Shift", CTRL: "Ctrl", CONTROL: "Ctrl" };
function niriCombo(mods, key) {
    var parts = String(mods || "").split(/\s+/).filter(function (m) { return m.length; }).map(function (m) { return NIRI_MODS[m.toUpperCase()] || m; });
    var k = key.length === 1 ? key.toUpperCase() : key.charAt(0).toUpperCase() + key.slice(1).toLowerCase();
    if (k.toLowerCase() === "escape") k = "Escape";
    if (k.toLowerCase() === "space") k = "Space";
    if (k.toLowerCase() === "tab") k = "Tab";
    parts.push(k);
    return parts.join("+");
}
function spawn(args) {
    return "spawn \"ssh-shell\"" + args.map(function (a) { return " \"" + a + "\""; }).join("") + ";";
}

function niri(sc) {
    var out = ["// SSH — Sovereignity Shell (generated)", "binds {"];
    for (var i = 0; i < ACTIONS.length; i++) {
        var k = split(sc[ACTIONS[i][0]]);
        if (!k.key) continue;
        out.push("    " + niriCombo(k.mods, k.key) + " { " + spawn(ACTIONS[i][1]) + " }");
    }
    for (var d = 0; d < DIRS.length; d++) {
        if (sc.traverse) out.push("    " + niriCombo(sc.traverse, DIRS[d][1]) + " { " + spawn(["atlas", "traverse", DIRS[d][0]]) + " }");
        if (sc.carry) out.push("    " + niriCombo(sc.carry, DIRS[d][1]) + " { " + spawn(["atlas", "carry", DIRS[d][0]]) + " }");
    }
    out.push("    XF86AudioRaiseVolume allow-when-locked=true { " + spawn(["audio", "up"]) + " }");
    out.push("    XF86AudioLowerVolume allow-when-locked=true { " + spawn(["audio", "down"]) + " }");
    out.push("    XF86AudioMute allow-when-locked=true { " + spawn(["audio", "mute"]) + " }");
    out.push("    XF86MonBrightnessUp allow-when-locked=true { " + spawn(["brightness", "up"]) + " }");
    out.push("    XF86MonBrightnessDown allow-when-locked=true { " + spawn(["brightness", "down"]) + " }");
    out.push("}");
    return out.join("\n");
}

// Hyprland ≥ 0.55 Lua configuration (syntax from Hyprland's shipped
// /usr/share/hypr/hyprland.lua).
function luaCombo(mods, key) {
    var parts = String(mods || "").split(/\s+/).filter(function (m) { return m.length; });
    parts.push(key);
    return parts.join(" + ");
}
function hyprlandLua(sc) {
    var out = ["-- SSH — Sovereignity Shell (generated)",
               "hl.on(\"hyprland.start\", function () hl.exec_cmd(\"ssh-shell --daemon\") end)"];
    function bind(combo, args, opts) {
        out.push("hl.bind(\"" + combo + "\", hl.dsp.exec_cmd(\"ssh-shell " + args.join(" ") + "\")" + (opts ? ", " + opts : "") + ")");
    }
    for (var i = 0; i < ACTIONS.length; i++) {
        var k = split(sc[ACTIONS[i][0]]);
        if (k.key) bind(luaCombo(k.mods, k.key), ACTIONS[i][1]);
    }
    for (var d = 0; d < DIRS.length; d++) {
        if (sc.traverse) bind(luaCombo(sc.traverse, DIRS[d][0]), ["atlas", "traverse", DIRS[d][0]]);
        if (sc.carry) bind(luaCombo(sc.carry, DIRS[d][0]), ["atlas", "carry", DIRS[d][0]]);
    }
    var media = "{ locked = true, repeating = true }";
    bind("XF86AudioRaiseVolume", ["audio", "up"], media);
    bind("XF86AudioLowerVolume", ["audio", "down"], media);
    bind("XF86AudioMute", ["audio", "mute"], "{ locked = true }");
    bind("XF86AudioMicMute", ["audio", "mic"], "{ locked = true }");
    bind("XF86MonBrightnessUp", ["brightness", "up"], media);
    bind("XF86MonBrightnessDown", ["brightness", "down"], media);
    return out.join("\n");
}

// ── Runtime binds for SSH login sessions (services/SessionBinds.qml) ──────
// One structured list, so session binds and the generated blocks agree.
// Each entry: { mods: "SUPER SHIFT", key: "ESCAPE", args: [...], media: bool, repeat: bool }
function specs(sc) {
    var out = [];
    for (var i = 0; i < ACTIONS.length; i++) {
        var k = split(sc[ACTIONS[i][0]]);
        if (k.key) out.push({ mods: k.mods, key: k.key, args: ACTIONS[i][1], media: false, repeat: false });
    }
    for (var d = 0; d < DIRS.length; d++) {
        if (sc.traverse) out.push({ mods: sc.traverse, key: DIRS[d][0], args: ["atlas", "traverse", DIRS[d][0]], media: false, repeat: false });
        if (sc.carry) out.push({ mods: sc.carry, key: DIRS[d][0], args: ["atlas", "carry", DIRS[d][0]], media: false, repeat: false });
    }
    out.push({ mods: "", key: "XF86AudioRaiseVolume", args: ["audio", "up"], media: true, repeat: true });
    out.push({ mods: "", key: "XF86AudioLowerVolume", args: ["audio", "down"], media: true, repeat: true });
    out.push({ mods: "", key: "XF86AudioMute", args: ["audio", "mute"], media: true, repeat: false });
    out.push({ mods: "", key: "XF86AudioMicMute", args: ["audio", "mic"], media: true, repeat: false });
    out.push({ mods: "", key: "XF86MonBrightnessUp", args: ["brightness", "up"], media: true, repeat: true });
    out.push({ mods: "", key: "XF86MonBrightnessDown", args: ["brightness", "down"], media: true, repeat: true });
    return out;
}

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

function cmd(args) { return "ssh-shell " + args.join(" "); }
function hyprlandLuaBind(b) {
    var opts = b.media ? (b.repeat ? ", { locked = true, repeating = true }" : ", { locked = true }") : "";
    return "hl.bind(\"" + luaCombo(b.mods, b.key) + "\", hl.dsp.exec_cmd(\"" + cmd(b.args) + "\")" + opts + ")";
}
function hyprlandLuaUnbind(b) { return "hl.unbind(\"" + luaCombo(b.mods, b.key) + "\")"; }
function hyprlandKeyword(b) {
    return "keyword " + (b.media ? (b.repeat ? "bindel" : "bindl") : "bind") + " " + b.mods + ", " + b.key + ", exec, " + cmd(b.args);
}
function hyprlandUnkeyword(b) { return "keyword unbind " + b.mods + ", " + b.key; }

function generate(target, sc) {
    if (target === "niri") return niri(sc);
    if (target === "hyprland-lua") return hyprlandLua(sc);
    return hyprland(sc);
}
