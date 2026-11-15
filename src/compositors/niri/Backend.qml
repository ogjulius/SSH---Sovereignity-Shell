import QtQuick
import Quickshell
import Quickshell.Io

// Niri backend.
//
// Quickshell has no Niri module, so SSH speaks Niri's documented JSON IPC
// directly: one long-lived Socket on $NIRI_SOCKET subscribed to the event
// stream (state arrives as full snapshots plus deltas), and actions sent as
// short-lived `niri msg` processes with argv arrays (no shell involved).
//
// Niri workspaces are dynamic and per-output; their ids are only stable for
// a session, so the Atlas binds to workspace *names* it assigns itself
// ("name:ssh-..."), falling back to ids for unnamed workspaces.
Item {
    id: b

    property bool connected: false
    property var workspaces: []
    property var windows: []
    property string focusedWorkspaceRef: ""
    property string focusedWindowId: ""
    property string focusedOutput: ""
    readonly property var caps: ({ numericIds: false, namedWorkspaces: true, geometry: false, previews: false })

    // Raw state keyed by niri id.
    property var _ws: ({})
    property var _win: ({})
    property int _retry: 0

    function refOf(w) { return w.name ? "name:" + w.name : "id:" + w.id; }

    function publish() {
        const wsList = [];
        const counts = {};
        for (const k in _win) { const w = _win[k]; counts[w.workspace_id] = (counts[w.workspace_id] || 0) + 1; }
        let focusedRef = "", focusedOut = "";
        for (const k in _ws) {
            const w = _ws[k];
            const ref = refOf(w);
            if (w.is_focused) { focusedRef = ref; focusedOut = w.output || ""; }
            wsList.push({ ref: ref, id: w.id, name: w.name || String(w.idx), idx: w.idx, output: w.output || "",
                          active: !!w.is_active, focused: !!w.is_focused, urgent: !!w.is_urgent, windows: counts[w.id] || 0 });
        }
        wsList.sort((a, b) => a.output === b.output ? a.idx - b.idx : (a.output < b.output ? -1 : 1));
        const winList = [];
        let focusedWin = "";
        for (const k in _win) {
            const w = _win[k];
            const ws = _ws[w.workspace_id];
            if (w.is_focused) focusedWin = String(w.id);
            winList.push({ id: String(w.id), title: w.title || "", appId: w.app_id || "",
                           workspaceRef: ws ? refOf(ws) : "", focused: !!w.is_focused, floating: !!w.is_floating,
                           x: 0, y: 0, w: 0, h: 0, monW: 1, monH: 1, handle: null });
        }
        workspaces = wsList;
        windows = winList;
        focusedWorkspaceRef = focusedRef;
        focusedOutput = focusedOut;
        focusedWindowId = focusedWin;
    }

    function handle(ev) {
        if (ev.WorkspacesChanged) {
            const m = {};
            for (const w of ev.WorkspacesChanged.workspaces) m[w.id] = w;
            _ws = m;
        } else if (ev.WorkspaceActivated) {
            const a = ev.WorkspaceActivated, target = _ws[a.id];
            if (target) for (const k in _ws) {
                const w = _ws[k];
                if (w.output === target.output) w.is_active = (w.id === a.id);
                if (a.focused) w.is_focused = (w.id === a.id);
            }
        } else if (ev.WorkspaceUrgencyChanged) {
            const w = _ws[ev.WorkspaceUrgencyChanged.id];
            if (w) w.is_urgent = ev.WorkspaceUrgencyChanged.urgent;
        } else if (ev.WindowsChanged) {
            const m = {};
            for (const w of ev.WindowsChanged.windows) m[w.id] = w;
            _win = m;
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window;
            if (w.is_focused) for (const k in _win) _win[k].is_focused = false;
            _win[w.id] = w;
        } else if (ev.WindowClosed) {
            delete _win[ev.WindowClosed.id];
        } else if (ev.WindowFocusChanged) {
            const id = ev.WindowFocusChanged.id;
            for (const k in _win) _win[k].is_focused = (_win[k].id === id);
        } else if (ev.WindowUrgencyChanged) {
            const w = _win[ev.WindowUrgencyChanged.id];
            if (w) w.is_urgent = ev.WindowUrgencyChanged.urgent;
        } else {
            return; // layouts, keyboard, overview, etc. are not needed here
        }
        publishTimer.restart();
    }

    Timer { id: publishTimer; interval: 16; onTriggered: b.publish() }

    Socket {
        id: stream
        path: Quickshell.env("NIRI_SOCKET") || ""
        connected: path.length > 0
        onConnectedChanged: {
            b.connected = connected;
            if (connected) {
                b._retry = 0;
                write("\"EventStream\"\n");
                flush();
            } else {
                reconnect.interval = Math.min(10000, 500 * Math.pow(2, b._retry++));
                reconnect.restart();
            }
        }
        onError: err => console.warn("[ssh] niri socket error: " + err)
        parser: SplitParser {
            onRead: line => {
                if (!line || line.length === 0) return;
                try {
                    const msg = JSON.parse(line);
                    if (msg.Ok !== undefined || msg.Err !== undefined) {
                        if (msg.Err) console.warn("[ssh] niri: " + JSON.stringify(msg.Err));
                        return;
                    }
                    b.handle(msg);
                } catch (e) {
                    console.warn("[ssh] niri: unparseable event: " + e.message);
                }
            }
        }
    }
    Timer {
        id: reconnect
        onTriggered: { stream.connected = false; stream.connected = true; }
    }

    // ── Actions ────────────────────────────────────────────────────────
    // Queue of argv arrays, run one after another so ordered sequences
    // (name an empty workspace, then focus it) stay ordered.
    property var _queue: []
    function run(argv) { _queue.push(argv); if (!proc.running) next(); }
    function next() {
        if (_queue.length === 0) return;
        proc.command = _queue.shift();
        proc.running = true;
    }
    Process {
        id: proc
        stderr: StdioCollector { onStreamFinished: if (text.trim().length) console.warn("[ssh] niri msg: " + text.trim()) }
        onExited: b.next()
    }

    function refArg(ref) { return ref.indexOf("id:") === 0 ? null : ref.slice(5); }

    // Index of the trailing empty workspace on the focused output; niri always keeps one.
    function emptyIdx() {
        let maxIdx = 1;
        for (const k in _ws) { const w = _ws[k]; if (w.output === focusedOutput && w.idx > maxIdx) maxIdx = w.idx; }
        return maxIdx;
    }

    function wsIdFor(ref) {
        if (ref.indexOf("id:") === 0) return parseInt(ref.slice(3));
        for (const k in _ws) if (_ws[k].name === ref.slice(5)) return _ws[k].id;
        return -1;
    }

    function focusRef(ref, create) {
        const id = wsIdFor(ref);
        if (id >= 0) {
            // niri references by index or name; ids map back to the current index.
            const w = _ws[id];
            run(["niri", "msg", "action", "focus-workspace", w.name ? w.name : String(w.idx)]);
            return;
        }
        if (create && ref.indexOf("name:") === 0) {
            const idx = String(emptyIdx());
            run(["niri", "msg", "action", "set-workspace-name", "--workspace", idx, ref.slice(5)]);
            run(["niri", "msg", "action", "focus-workspace", ref.slice(5)]);
        }
    }
    function moveWindowTo(windowId, ref, follow, create) {
        if (wsIdFor(ref) < 0 && create && ref.indexOf("name:") === 0)
            run(["niri", "msg", "action", "set-workspace-name", "--workspace", String(emptyIdx()), ref.slice(5)]);
        const id = wsIdFor(ref);
        const target = ref.indexOf("name:") === 0 ? ref.slice(5) : (id >= 0 && _ws[id] ? String(_ws[id].idx) : "");
        if (!target) return;
        run(["niri", "msg", "action", "move-window-to-workspace", "--window-id", String(windowId), "--focus", follow ? "true" : "false", target]);
    }
    function focusWindow(id) { run(["niri", "msg", "action", "focus-window", "--id", String(id)]); }
    function closeWindow(id) { run(["niri", "msg", "action", "close-window", "--id", String(id)]); }
    function quit() { run(["niri", "msg", "action", "quit", "--skip-confirmation"]); }
}
