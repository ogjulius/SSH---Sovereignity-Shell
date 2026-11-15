pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.configuration
import qs.compositors
import "../utilities/AtlasModel.js" as M

// Infinite Desktop orchestration.
//
// Owns the persistent map (collections → cells → workspace refs) and keeps it
// in sync with the compositor in both directions:
//   • SSH → compositor: traverse/carry/goto focus or move to the bound ref,
//     creating the workspace on first visit.
//   • compositor → SSH: native workspace switches move the Atlas cursor; a
//     workspace SSH has never seen is auto-placed (optional) so native
//     keybinds never break.
Singleton {
    id: a

    property var state: M.empty()
    property int revision: 0          // bump to notify bindings after in-place edits
    property bool ready: false
    property string lastDirection: "" // "left"|"right"|"up"|"down" for transitions
    signal traversed(string direction)

    readonly property bool enabled: Config.atlas.enabled && Compositor.kind !== "none"
    readonly property var current: { revision; return M.active(state); }
    readonly property var cursor: { revision; return current.cursor; }
    readonly property var collections: { revision; return state.collections; }

    function cell(x, y, coll) {
        revision;
        const c = coll || current;
        return c.cells[M.key(x, y)] || null;
    }
    function label(x, y) { return M.coordLabel(x, y); }
    function cellName(x, y, coll) {
        const c = cell(x, y, coll);
        return c && c.name ? c.name : "";
    }
    function workspaceAt(x, y, coll) {
        const c = cell(x, y, coll);
        return c && c.ref ? Compositor.workspace(c.ref) : null;
    }
    function windowCount(x, y, coll) {
        const w = workspaceAt(x, y, coll);
        return w ? w.windows : 0;
    }
    // "Main · C2" for a workspace ref, or the workspace's own name if unmapped.
    function whereIs(ref) {
        revision;
        const loc = M.locate(state, ref);
        if (loc) { const c = M.collection(state, loc.collection); return c.name + " · " + M.coordLabel(loc.x, loc.y); }
        const w = Compositor.workspace(ref);
        return w ? "workspace " + w.name : "";
    }
    function bounds(pad) { revision; return M.bounds(current, pad || 0); }

    // ── Mutations ──────────────────────────────────────────────────────
    function touch() { revision++; saveTimer.restart(); }

    function newRef(x, y, coll) {
        if (Compositor.caps.numericIds) return "id:" + M.freeNumericId(state, Compositor.liveNumericIds());
        return "name:ssh-" + (coll || current).id + "-" + x + "_" + y;
    }

    function ensureRef(x, y, coll) {
        const c = coll || current;
        const k = M.key(x, y);
        if (c.cells[k] && c.cells[k].ref) return { ref: c.cells[k].ref, created: false };
        const ref = newRef(x, y, c);
        M.bind(state, c.id, x, y, ref);
        return { ref: ref, created: true };
    }

    function goto(x, y, collId) {
        if (!enabled) return;
        if (collId && collId !== state.active) { state.active = collId; }
        const c = current;
        c.cursor = { x: x, y: y };
        const r = ensureRef(x, y, c);
        touch();
        Compositor.focusRef(r.ref, true);
    }

    function delta(dir) {
        return ({ left: [-1, 0], right: [1, 0], up: [0, -1], down: [0, 1] })[dir] || [0, 0];
    }

    function traverse(dir) {
        const d = delta(dir);
        lastDirection = dir;
        goto(cursor.x + d[0], cursor.y + d[1]);
        traversed(dir);
    }

    function carry(dir) {
        const win = Compositor.focusedWindowId;
        if (!enabled || !win) return;
        const d = delta(dir);
        carryTo(win, cursor.x + d[0], cursor.y + d[1], Config.atlas.carryFollows);
        if (Config.atlas.carryFollows) { lastDirection = dir; traversed(dir); }
    }

    function carryTo(windowId, x, y, follow) {
        const c = current;
        const r = ensureRef(x, y, c);
        if (follow) c.cursor = { x: x, y: y };
        touch();
        Compositor.moveWindowTo(windowId, r.ref, follow, true);
    }

    function rename(x, y, name) {
        const c = current;
        const k = M.key(x, y);
        const clean = (name || "").trim().slice(0, 48);
        if (!c.cells[k]) { if (!clean) return; c.cells[k] = {}; }
        if (clean) c.cells[k].name = clean; else delete c.cells[k].name;
        if (!c.cells[k].name && !c.cells[k].ref) delete c.cells[k];
        touch();
    }

    // Forget a cell's binding. The workspace itself is untouched.
    function release(x, y) {
        const c = current;
        delete c.cells[M.key(x, y)];
        touch();
    }

    function addCollection(name) {
        const id = M.nextCollectionId(state);
        state.collections.push({ id: id, name: (name || ("Collection " + (state.collections.length + 1))).slice(0, 32), cursor: { x: 0, y: 0 }, cells: {} });
        touch();
        return id;
    }
    function renameCollection(id, name) {
        const c = M.collection(state, id);
        if (c && name && name.trim()) { c.name = name.trim().slice(0, 32); touch(); }
    }
    function removeCollection(id) {
        if (state.collections.length <= 1) return;
        state.collections = state.collections.filter(c => c.id !== id);
        if (state.active === id) state.active = state.collections[0].id;
        touch();
    }
    function switchCollection(id) {
        const c = M.collection(state, id);
        if (!c) return;
        state.active = id;
        goto(c.cursor.x, c.cursor.y, id);
    }
    function cycleCollection(step) {
        const list = state.collections;
        let i = list.findIndex(c => c.id === state.active);
        i = (i + step + list.length) % list.length;
        switchCollection(list[i].id);
    }

    // ── Compositor → Atlas ─────────────────────────────────────────────
    function follow() {
        if (!ready || !enabled) return;
        const ref = Compositor.focusedWorkspaceRef;
        if (!ref) return;
        const where = M.locate(state, ref);
        if (where) {
            const c = M.collection(state, where.collection);
            const moved = state.active !== where.collection || c.cursor.x !== where.x || c.cursor.y !== where.y;
            if (moved) {
                state.active = where.collection;
                c.cursor = { x: where.x, y: where.y };
                touch();
            }
            return;
        }
        if (!Config.atlas.autoPlace) return;
        const c = current;
        const here = c.cells[M.key(c.cursor.x, c.cursor.y)];
        const pos = (here && here.ref) ? M.firstFreeInRow(c, c.cursor.y) : { x: c.cursor.x, y: c.cursor.y };
        M.bind(state, c.id, pos.x, pos.y, ref);
        c.cursor = pos;
        touch();
    }

    Connections {
        target: Compositor
        function onFocusedWorkspaceRefChanged() { followTimer.restart(); }
    }
    Timer { id: followTimer; interval: 30; onTriggered: a.follow() }

    // ── Persistence ────────────────────────────────────────────────────
    Timer { id: saveTimer; interval: 800; onTriggered: { Paths.ensure(Paths.stateDir); file.setText(JSON.stringify(a.state) + "\n"); } }
    Timer { id: seedTimer; interval: 400; onTriggered: { M.seed(a.state, Compositor.liveNumericIds()); a.touch(); a.follow(); } }

    FileView {
        id: file
        path: Paths.atlasFile
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try { a.state = M.sanitize(JSON.parse(text())); }
            catch (e) { console.warn("[ssh] atlas state unreadable, starting a fresh map: " + e.message); a.state = M.empty(); }
            a.ready = true;
            a.revision++;
            followTimer.restart();
        }
        onLoadFailed: err => {
            a.state = M.empty();
            a.ready = true;
            // First run: give existing numeric workspaces a place on row 1.
            if (Compositor.caps.numericIds) seedTimer.restart(); else followTimer.restart();
        }
    }
}
