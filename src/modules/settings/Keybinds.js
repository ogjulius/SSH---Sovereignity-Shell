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

function generate(target, sc) {
    if (target === "niri") return niri(sc);
    if (target === "hyprland-lua") return hyprlandLua(sc);
    return hyprland(sc);
}
