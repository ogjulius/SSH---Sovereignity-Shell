.pragma library
// SSH configuration schema.
//
// Every user-facing option is declared exactly once, here. Each leaf carries
// its type, default and constraints. `merge()` walks this tree against the
// user's JSON, keeping valid values, replacing invalid ones with defaults and
// recording a human-readable warning for each replacement. Nothing outside
// this file decides what a valid configuration is.
//
// Leaf kinds:
//   bool, num (min/max), int (min/max), str, enum (v: [...]), argv (array of
//   non-empty strings, never passed to a shell), strlist, color (#rrggbb or
//   #aarrggbb), numOrNull.

var ACCENTS = ["argent", "brass", "ember", "verdigris", "cobalt", "oxblood", "custom"];

var tree = {
    version: { t: "int", d: 1, min: 1, max: 1 },
    appearance: {
        mode: { t: "enum", d: "dark", v: ["dark", "light", "auto"] },
        appIcons: { t: "bool", d: false },
        accent: { t: "enum", d: "argent", v: ACCENTS },
        customAccent: { t: "color", d: "#c9bfa9" },
        opacity: { t: "num", d: 0.94, min: 0.5, max: 1 },
        animationScale: { t: "num", d: 1, min: 0, max: 2 },
        fontUi: { t: "str", d: "Inter" },
        fontDisplay: { t: "str", d: "Inter Display" },
        fontMono: { t: "str", d: "JetBrains Mono" },
        fontScale: { t: "num", d: 1.08, min: 0.8, max: 1.4 },
        chamfer: { t: "num", d: 1, min: 0, max: 2 },
        autoLightFrom: { t: "int", d: 7, min: 0, max: 23 },
        autoDarkFrom: { t: "int", d: 19, min: 0, max: 23 }
    },
    meridian: {
        position: { t: "enum", d: "top", v: ["top", "bottom"] },
        height: { t: "int", d: 34, min: 26, max: 52 },
        monitors: { t: "strlist", d: [] },
        showTicks: { t: "bool", d: true },
        showMinimap: { t: "bool", d: true },
        showRow: { t: "bool", d: true },
        showTitle: { t: "bool", d: true },
        showTray: { t: "bool", d: true },
        showBatteryPercent: { t: "bool", d: true },
        showVolumePercent: { t: "bool", d: false }
    },
    lens: {
        enabled: { t: "bool", d: true },
        dim: { t: "num", d: 0.6, min: 0, max: 0.95 },
        showSignals: { t: "bool", d: true },
        showMedia: { t: "bool", d: true },
        showInstruments: { t: "bool", d: true }
    },
    atlas: {
        enabled: { t: "bool", d: true },
        previews: { t: "bool", d: true },
        maxPreviews: { t: "int", d: 16, min: 0, max: 64 },
        autoPlace: { t: "bool", d: true },
        carryFollows: { t: "bool", d: true },
        traverseToast: { t: "bool", d: true },
        cellWidth: { t: "int", d: 232, min: 140, max: 420 }
    },
    launcher: {
        maxResults: { t: "int", d: 8, min: 4, max: 30 },
        showCategories: { t: "bool", d: true },
        recentCount: { t: "int", d: 5, min: 0, max: 20 }
    },
    notifications: {
        enabled: { t: "bool", d: true },
        position: { t: "enum", d: "top-right", v: ["top-right", "top-left", "bottom-right", "bottom-left", "top-center"] },
        timeout: { t: "int", d: 5500, min: 1000, max: 60000 },
        doNotDisturb: { t: "bool", d: false },
        historyLimit: { t: "int", d: 80, min: 5, max: 500 },
        maxPopups: { t: "int", d: 4, min: 1, max: 10 },
        // Off by default: notification text is private and stays in memory only.
        persistHistory: { t: "bool", d: false }
    },
    osd: {
        enabled: { t: "bool", d: true },
        timeout: { t: "int", d: 1300, min: 400, max: 6000 }
    },
    clock: {
        format24h: { t: "bool", d: true },
        showSeconds: { t: "bool", d: false },
        showDate: { t: "bool", d: true },
        weekStartsMonday: { t: "bool", d: true }
    },
    weather: {
        enabled: { t: "bool", d: true },
        provider: { t: "enum", d: "open-meteo", v: ["open-meteo", "none"] },
        latitude: { t: "numOrNull", d: null, min: -90, max: 90 },
        longitude: { t: "numOrNull", d: null, min: -180, max: 180 },
        locationName: { t: "str", d: "" },
        units: { t: "enum", d: "metric", v: ["metric", "imperial"] },
        refreshMinutes: { t: "int", d: 30, min: 10, max: 360 }
    },
    commands: {
        lock: { t: "argv", d: ["loginctl", "lock-session"] },
        suspend: { t: "argv", d: ["loginctl", "suspend"] },
        reboot: { t: "argv", d: ["loginctl", "reboot"] },
        poweroff: { t: "argv", d: ["loginctl", "poweroff"] },
        terminal: { t: "argv", d: ["foot"] }
    },
    session: {
        // In the Sovereignity Shell login sessions, bind the shortcuts below
        // automatically (keys your compositor config already binds are left alone).
        keybinds: { t: "bool", d: true }
    },
    shortcuts: {
        lens: { t: "str", d: "SUPER, SPACE" },
        launcher: { t: "str", d: "SUPER, D" },
        atlas: { t: "str", d: "SUPER, TAB" },
        instruments: { t: "str", d: "SUPER, A" },
        power: { t: "str", d: "SUPER SHIFT, ESCAPE" },
        traverse: { t: "str", d: "SUPER ALT" },
        carry: { t: "str", d: "SUPER ALT SHIFT" }
    }
};

function isLeaf(n) { return n !== null && typeof n === "object" && typeof n.t === "string"; }

function clone(v) { return v === undefined ? undefined : JSON.parse(JSON.stringify(v)); }

function defaults(node) {
    node = node || tree;
    var out = {};
    for (var k in node) out[k] = isLeaf(node[k]) ? clone(node[k].d) : defaults(node[k]);
    return out;
}

var HEX = /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/;

// Returns null when valid, otherwise a reason string.
function check(spec, v) {
    switch (spec.t) {
    case "bool": return typeof v === "boolean" ? null : "expected true/false";
    case "num":
    case "int":
        if (typeof v !== "number" || !isFinite(v)) return "expected a number";
        if (spec.t === "int" && Math.floor(v) !== v) return "expected a whole number";
        if (spec.min !== undefined && v < spec.min) return "below minimum " + spec.min;
        if (spec.max !== undefined && v > spec.max) return "above maximum " + spec.max;
        return null;
    case "numOrNull":
        if (v === null) return null;
        return check({ t: "num", min: spec.min, max: spec.max }, v);
    case "str": return typeof v === "string" ? null : "expected text";
    case "enum": return spec.v.indexOf(v) >= 0 ? null : "expected one of: " + spec.v.join(", ");
    case "color": return typeof v === "string" && HEX.test(v) ? null : "expected #rrggbb";
    case "strlist":
        if (!Array.isArray(v)) return "expected a list of text";
        for (var i = 0; i < v.length; i++) if (typeof v[i] !== "string") return "expected a list of text";
        return null;
    case "argv":
        if (!Array.isArray(v) || v.length === 0) return "expected a non-empty command list";
        for (var j = 0; j < v.length; j++) if (typeof v[j] !== "string" || v[j].length === 0) return "command parts must be non-empty text";
        return null;
    }
    return "unknown option type";
}

// merge(user) -> { value, warnings[] }. Unknown keys are reported, not kept.
function merge(user, node, path, warnings) {
    node = node || tree;
    path = path || "";
    warnings = warnings || [];
    var out = {};
    var u = (user !== null && typeof user === "object" && !Array.isArray(user)) ? user : {};
    if (user !== undefined && u !== user && path !== "") warnings.push(path + ": expected a section, using defaults");
    for (var k in node) {
        var p = path ? path + "." + k : k;
        if (isLeaf(node[k])) {
            if (!(k in u)) { out[k] = clone(node[k].d); continue; }
            var why = check(node[k], u[k]);
            if (why) { warnings.push(p + ": " + why + " (using default)"); out[k] = clone(node[k].d); }
            else out[k] = clone(u[k]);
        } else {
            out[k] = merge(u[k], node[k], p, warnings).value;
        }
    }
    for (var extra in u) if (!(extra in node)) warnings.push((path ? path + "." : "") + extra + ": unknown option (ignored)");
    return { value: out, warnings: warnings };
}

function specAt(path) {
    var parts = path.split(".");
    var n = tree;
    for (var i = 0; i < parts.length; i++) {
        if (!n || isLeaf(n)) return null;
        n = n[parts[i]];
    }
    return isLeaf(n) ? n : null;
}

// Writes `value` into a (cloned) sparse user tree at `path`. Values equal to
// the default are removed so that the user's file only holds real choices.
function setPath(userTree, path, value) {
    var root = clone(userTree) || {};
    var parts = path.split(".");
    var n = root;
    for (var i = 0; i < parts.length - 1; i++) {
        if (typeof n[parts[i]] !== "object" || n[parts[i]] === null || Array.isArray(n[parts[i]])) n[parts[i]] = {};
        n = n[parts[i]];
    }
    var spec = specAt(path);
    if (spec && JSON.stringify(spec.d) === JSON.stringify(value)) delete n[parts[parts.length - 1]];
    else n[parts[parts.length - 1]] = clone(value);
    return root;
}
