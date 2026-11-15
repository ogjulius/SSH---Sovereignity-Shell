.pragma library
// Pure data logic for the Atlas (Infinite Desktop).
//
// The Atlas is an SSH-level organisation layer. It never pretends the
// compositor has an infinite canvas: it keeps a map of *cells* (x, y) inside
// named *collections*, and each cell may be *bound* to one real compositor
// workspace reference (a string like "id:4" or "name:ssh-main-2_0").
//
// State shape (persisted as JSON):
// {
//   version: 1,
//   active: "c1",                       // active collection id
//   collections: [ { id, name, cursor: {x, y}, cells: { "x,y": { ref, name } } } ]
// }

var VERSION = 1;

function key(x, y) { return x + "," + y; }

function parseKey(k) {
    var p = k.split(",");
    return { x: parseInt(p[0], 10), y: parseInt(p[1], 10) };
}

function empty() {
    return { version: VERSION, active: "c1", collections: [{ id: "c1", name: "Main", cursor: { x: 0, y: 0 }, cells: {} }] };
}

// Repairs anything malformed instead of discarding the user's map.
function sanitize(s) {
    if (!s || typeof s !== "object" || !Array.isArray(s.collections) || s.collections.length === 0) return empty();
    var out = { version: VERSION, active: String(s.active || ""), collections: [] };
    var seenIds = {};
    for (var i = 0; i < s.collections.length; i++) {
        var c = s.collections[i];
        if (!c || typeof c !== "object") continue;
        var id = typeof c.id === "string" && c.id && !seenIds[c.id] ? c.id : nextCollectionId(out);
        seenIds[id] = true;
        var cells = {};
        var raw = c.cells && typeof c.cells === "object" ? c.cells : {};
        for (var k in raw) {
            if (!/^-?\d+,-?\d+$/.test(k)) continue;
            var cell = raw[k];
            if (!cell || typeof cell !== "object") continue;
            var clean = {};
            if (typeof cell.ref === "string" && /^(id|name):.+/.test(cell.ref)) clean.ref = cell.ref;
            if (typeof cell.name === "string" && cell.name.length > 0) clean.name = cell.name.slice(0, 48);
            if (clean.ref || clean.name) cells[k] = clean;
        }
        var cur = c.cursor && typeof c.cursor.x === "number" && typeof c.cursor.y === "number" ? { x: Math.round(c.cursor.x), y: Math.round(c.cursor.y) } : { x: 0, y: 0 };
        out.collections.push({ id: id, name: typeof c.name === "string" && c.name ? c.name.slice(0, 32) : "Collection", cursor: cur, cells: cells });
    }
    if (out.collections.length === 0) return empty();
    if (!collection(out, out.active)) out.active = out.collections[0].id;
    return out;
}

function nextCollectionId(s) {
    var n = 1;
    var ids = {};
    for (var i = 0; i < s.collections.length; i++) ids[s.collections[i].id] = true;
    while (ids["c" + n]) n++;
    return "c" + n;
}

function collection(s, id) {
    for (var i = 0; i < s.collections.length; i++) if (s.collections[i].id === id) return s.collections[i];
    return null;
}

function active(s) { return collection(s, s.active) || s.collections[0]; }

// Finds the cell bound to `ref` anywhere. -> { collection, x, y } | null
function locate(s, ref) {
    if (!ref) return null;
    for (var i = 0; i < s.collections.length; i++) {
        var c = s.collections[i];
        for (var k in c.cells) if (c.cells[k].ref === ref) {
            var p = parseKey(k);
            return { collection: c.id, x: p.x, y: p.y };
        }
    }
    return null;
}

function allRefs(s) {
    var out = {};
    for (var i = 0; i < s.collections.length; i++)
        for (var k in s.collections[i].cells) if (s.collections[i].cells[k].ref) out[s.collections[i].cells[k].ref] = true;
    return out;
}

// First unbound cell in row y, scanning right from x = 0.
function firstFreeInRow(c, y) {
    for (var x = 0; x < 10000; x++) {
        var cell = c.cells[key(x, y)];
        if (!cell || !cell.ref) return { x: x, y: y };
    }
    return { x: 0, y: y };
}

// Lowest positive integer workspace id not bound in the atlas and not
// currently in use by the compositor (`liveIds` is an array of numbers).
function freeNumericId(s, liveIds) {
    var used = {};
    var refs = allRefs(s);
    for (var r in refs) if (r.indexOf("id:") === 0) used[parseInt(r.slice(3), 10)] = true;
    for (var i = 0; i < liveIds.length; i++) used[liveIds[i]] = true;
    var n = 1;
    while (used[n]) n++;
    return n;
}

function bind(s, collectionId, x, y, ref) {
    var c = collection(s, collectionId);
    if (!c) return;
    // A workspace belongs to at most one cell.
    var prev = locate(s, ref);
    if (prev) {
        var pc = collection(s, prev.collection);
        var pk = key(prev.x, prev.y);
        delete pc.cells[pk].ref;
        if (!pc.cells[pk].name) delete pc.cells[pk];
    }
    var k = key(x, y);
    if (!c.cells[k]) c.cells[k] = {};
    c.cells[k].ref = ref;
}

// Seeds an empty atlas from existing numeric workspaces: id N -> (N-1, 0).
function seed(s, liveIds) {
    var c = active(s);
    var sorted = liveIds.slice().filter(function (n) { return n > 0; }).sort(function (a, b) { return a - b; });
    for (var i = 0; i < sorted.length; i++) {
        var id = sorted[i];
        var pos = id <= 30 && !c.cells[key(id - 1, 0)] ? { x: id - 1, y: 0 } : firstFreeInRow(c, 0);
        bind(s, c.id, pos.x, pos.y, "id:" + id);
    }
}

// Bounding box of a collection's populated cells, padded by `pad`.
function bounds(c, pad) {
    var minX = 0, maxX = 0, minY = 0, maxY = 0, first = true;
    for (var k in c.cells) {
        var p = parseKey(k);
        if (first) { minX = maxX = p.x; minY = maxY = p.y; first = false; }
        else {
            if (p.x < minX) minX = p.x; if (p.x > maxX) maxX = p.x;
            if (p.y < minY) minY = p.y; if (p.y > maxY) maxY = p.y;
        }
    }
    var cx = c.cursor.x, cy = c.cursor.y;
    if (first) { minX = maxX = cx; minY = maxY = cy; }
    if (cx < minX) minX = cx; if (cx > maxX) maxX = cx;
    if (cy < minY) minY = cy; if (cy > maxY) maxY = cy;
    pad = pad || 0;
    return { minX: minX - pad, maxX: maxX + pad, minY: minY - pad, maxY: maxY + pad };
}

// Human coordinate label: columns are letters (A..Z, AA..), rows numbers.
// Negative coordinates are prefixed with a minus sign.
function columnLabel(x) {
    var neg = x < 0;
    var n = Math.abs(x);
    var s = "";
    do { s = String.fromCharCode(65 + (n % 26)) + s; n = Math.floor(n / 26) - 1; } while (n >= 0);
    return (neg ? "−" : "") + s;
}

function coordLabel(x, y) { return columnLabel(x) + (y < 0 ? "−" + Math.abs(y) : String(y + 1)); }
