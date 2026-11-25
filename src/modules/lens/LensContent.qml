import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.themes
import qs.configuration
import qs.services
import qs.components
import qs.compositors
import qs.modules.almanac
import qs.modules.signals
import "../../utilities/Fmt.js" as Fmt
import "Intents.js" as Intents

// The Lens — Sovereign Space.
//
// A compass around where you are: the current cell and its windows at the
// centre, the four neighbouring cells on the cardinal points, the session's
// context in the corners, and one intent line at the bottom that searches
// apps, windows, named cells and commands at once.
//
// Alt+arrows travel without closing the Lens; Alt+Shift+arrows carry the
// focused window along.
FocusScope {
    id: lens
    focus: true

    property int current: 0
    readonly property string query: intent.text.trim().toLowerCase()
    readonly property var here: Atlas.cell(Atlas.cursor.x, Atlas.cursor.y)
    readonly property string hereRef: here && here.ref ? here.ref : Compositor.focusedWorkspaceRef
    readonly property var hereWindows: Compositor.windowsOn(hereRef)

    readonly property var results: {
        if (query.length === 0) return [];
        Atlas.revision;
        const labelFor = ref => Atlas.whereIs(ref);
        let all = [];
        all = all.concat(Intents.windows(query, Compositor.windows, labelFor));
        all = all.concat(Intents.cells(query, Atlas.state, Atlas.label));
        all = all.concat(Intents.commands(query));
        const apps = Apps.search(query, "all", 6);
        for (let i = 0; i < apps.length; i++)
            all.push({ kind: "app", title: apps[i].name, subtitle: apps[i].genericName || "Application", glyph: "grid", icon: Apps.iconPath(apps[i].icon), score: 700 - i * 40, payload: apps[i] });
        all.sort((a, b) => b.score - a.score);
        return all.slice(0, 9);
    }
    readonly property int count: query.length > 0 ? results.length : hereWindows.length
    onQueryChanged: current = 0

    function activate(i) {
        if (query.length === 0) {
            const w = hereWindows[i];
            if (w) { Compositor.focusWindow(w.id); Surfaces.close(); }
            return;
        }
        const r = results[i];
        if (!r) return;
        if (r.kind === "app") { Apps.launch(r.payload); Surfaces.close(); }
        else if (r.kind === "window") { Compositor.focusWindow(r.payload); Surfaces.close(); }
        else if (r.kind === "cell") { Atlas.switchCollection(r.payload.collection); Atlas.goto(r.payload.x, r.payload.y); intent.text = ""; }
        else if (r.kind === "command") runCommand(r.payload);
    }

    function runCommand(id) {
        switch (id) {
        case "atlas": Surfaces.open("atlas"); break;
        case "launcher": Surfaces.open("launcher"); break;
        case "settings": Surfaces.close(); SettingsHub.open(); break;
        case "quiet": Notifs.setDnd(!Notifs.dnd); intent.text = ""; break;
        case "mute": Audio.toggleMute(); intent.text = ""; break;
        case "theme": Config.set("appearance.mode", Theme.dark ? "light" : "dark"); intent.text = ""; break;
        case "collection": Atlas.switchCollection(Atlas.addCollection("")); Surfaces.open("atlas"); break;
        case "terminal": Surfaces.close(); Quickshell.execDetached(Config.commands.terminal); break;
        case "lock": Surfaces.close(); Quickshell.execDetached(Config.commands.lock); break;
        case "power": Surfaces.open("power"); break;
        }
    }

    function handleKey(e) {
        const alt = e.modifiers & Qt.AltModifier, shift = e.modifiers & Qt.ShiftModifier;
        const dir = ({ [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Up]: "up", [Qt.Key_Down]: "down" })[e.key];
        if (alt && dir) { if (shift) Atlas.carry(dir); else Atlas.traverse(dir); e.accepted = true; return; }
        if (e.key === Qt.Key_Down) { current = Math.min(count - 1, current + 1); e.accepted = true; }
        else if (e.key === Qt.Key_Up) { current = Math.max(0, current - 1); e.accepted = true; }
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { activate(current); e.accepted = true; }
        else if (e.key === Qt.Key_Delete && query.length === 0 && hereWindows[current]) { Compositor.closeWindow(hereWindows[current].id); e.accepted = true; }
        else if (e.key === Qt.Key_Escape && intent.text.length > 0) { intent.text = ""; e.accepted = true; }
    }

    // ── Centre: here ──────────────────────────────────────────────────
    Item {
        id: centre
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -24
        width: 520
        height: Math.max(220, Math.min(440, 104 + Math.max(1, lens.count) * 44))
        Behavior on height { enabled: Theme.animate; NumberAnimation { duration: Theme.durStd; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveEnter } }

        Plate { anchors.fill: parent; cut: Theme.cutL; color: Theme.surface(Theme.plate); border: Theme.lineStrong }
        Rectangle { // meridian through the centre plate
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 76 }
            height: 1; color: Theme.line
        }

        ColumnLayout {
            anchors { fill: parent; margins: Theme.s5 }
            spacing: Theme.s4
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                spacing: Theme.s4
                Label { role: "heading"; text: Atlas.enabled ? Atlas.label(Atlas.cursor.x, Atlas.cursor.y) : "—"; color: Theme.accent }
                ColumnLayout {
                    spacing: 0
                    Label { role: "micro"; faint: true; text: Atlas.enabled ? Fmt.roman(Atlas.collections.indexOf(Atlas.current) + 1) + " · " + Atlas.current.name : Compositor.displayName }
                    Label { role: "lead"; text: lens.here && lens.here.name ? lens.here.name : (lens.query.length ? "Intent" : "Here") }
                }
                Item { Layout.fillWidth: true }
                Label { role: "micro"; faint: true; text: lens.query.length ? lens.results.length + " results" : lens.hereWindows.length + " windows" }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                interactive: false
                currentIndex: lens.current
                model: lens.query.length > 0 ? lens.results : lens.hereWindows
                delegate: ListRow {
                    required property var modelData
                    required property int index
                    width: list.width
                    current: index === lens.current
                    activeFocusOnTab: false
                    iconSource: lens.query.length > 0 ? (modelData.icon || (modelData.appId ? Apps.iconFor(modelData.appId) : "")) : Apps.iconFor(modelData.appId)
                    glyph: lens.query.length > 0 ? modelData.glyph : "window"
                    title: lens.query.length > 0 ? modelData.title : (modelData.title || modelData.appId)
                    subtitle: lens.query.length > 0 ? modelData.subtitle : (Apps.nameFor(modelData.appId) + (modelData.floating ? " · floating" : "") + (modelData.focused ? " · focused" : ""))
                    hint: current ? (lens.query.length > 0 ? modelData.kind : "↵ focus · del close") : ""
                    onClicked: lens.activate(index)
                    onHoveredChanged: if (hovered) lens.current = index
                }
            }
            Label {
                visible: lens.count === 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                role: "caption"; dim: true
                text: lens.query.length ? "No intent matches “" + intent.text + "”." : "No windows here. Type to launch, or travel with Alt + arrows."
            }
        }
    }

    // ── Compass ───────────────────────────────────────────────────────
    // Hairline meridians tie the neighbours to the centre plate.
    Rectangle { visible: Atlas.enabled; width: 1; color: Theme.line; anchors { horizontalCenter: centre.horizontalCenter; bottom: centre.top; top: parent.top; topMargin: Theme.s7 + 120 } }
    Rectangle { visible: Atlas.enabled; width: 1; color: Theme.line; anchors { horizontalCenter: centre.horizontalCenter; top: centre.bottom; bottom: intent.top; bottomMargin: Theme.s5 } }
    Rectangle { visible: Atlas.enabled; height: 1; color: Theme.line; anchors { verticalCenter: centre.verticalCenter; right: centre.left; left: parent.left; leftMargin: Theme.s7 } }
    Rectangle { visible: Atlas.enabled; height: 1; color: Theme.line; anchors { verticalCenter: centre.verticalCenter; left: centre.right; right: parent.right; rightMargin: Theme.s7 } }

    Compass { visible: Atlas.enabled; dir: "up"; anchors { horizontalCenter: centre.horizontalCenter; bottom: centre.top; bottomMargin: Theme.s5 } }
    Compass { visible: Atlas.enabled; dir: "down"; anchors { horizontalCenter: centre.horizontalCenter; top: centre.bottom; topMargin: Theme.s5 } }
    Compass { visible: Atlas.enabled; dir: "left"; anchors { verticalCenter: centre.verticalCenter; right: centre.left; rightMargin: Theme.s5 } }
    Compass { visible: Atlas.enabled; dir: "right"; anchors { verticalCenter: centre.verticalCenter; left: centre.right; leftMargin: Theme.s5 } }

    // ── Corners ───────────────────────────────────────────────────────
    ColumnLayout { // NW: now
        anchors { left: parent.left; top: parent.top; margins: Theme.s7 }
        width: 340
        spacing: Theme.s3
        Label { role: "micro"; dim: true; text: Time.longDate }
        Label { role: "display"; text: Time.time }
        MediaStrip { compact: true; Layout.fillWidth: true; visible: Config.lens.showMedia && Media.active }
    }
    ColumnLayout { // NE: signals
        visible: Config.lens.showSignals
        anchors { right: parent.right; top: parent.top; margins: Theme.s7 }
        width: 340
        spacing: Theme.s3
        SectionMark { Layout.fillWidth: true; index: String(Notifs.history.length).padStart(2, "0"); text: Notifs.dnd ? "Signals · quiet" : "Signals" }
        Repeater {
            model: Notifs.history.slice(0, 3)
            NotificationCard { required property var modelData; record: modelData; Layout.fillWidth: true }
        }
        Label { visible: Notifs.history.length === 0; role: "caption"; dim: true; text: "All quiet." }
    }
    ColumnLayout { // SE: instruments
        visible: Config.lens.showInstruments
        anchors { right: parent.right; bottom: parent.bottom; margins: Theme.s7 }
        width: 300
        spacing: Theme.s3
        SectionMark { Layout.fillWidth: true; text: "Instruments" }
        RowLayout {
            spacing: Theme.s3
            Icon { name: Audio.muted ? "speakerMute" : "speaker"; size: 14; color: Theme.textDim }
            InstrumentSlider { Layout.fillWidth: true; value: Audio.volume; muted: Audio.muted; activeFocusOnTab: false; onMoved: v => Audio.setVolume(v) }
        }
        RowLayout {
            visible: Brightness.available
            spacing: Theme.s3
            Icon { name: "sun"; size: 14; color: Theme.textDim }
            InstrumentSlider { Layout.fillWidth: true; value: Brightness.value; activeFocusOnTab: false; onMoved: v => Brightness.set(v) }
        }
        RowLayout {
            spacing: Theme.s2
            IconButton { icon: Net.glyph; highlighted: Net.kind !== "none"; activeFocusOnTab: false; onClicked: Surfaces.open("instruments") }
            IconButton { icon: Bt.enabled ? "bluetooth" : "bluetoothOff"; highlighted: Bt.enabled; activeFocusOnTab: false; onClicked: Bt.setEnabled(!Bt.enabled) }
            IconButton { icon: "moon"; highlighted: Notifs.dnd; activeFocusOnTab: false; onClicked: Notifs.setDnd(!Notifs.dnd) }
            IconButton { icon: Audio.micMuted ? "micOff" : "mic"; highlighted: !Audio.micMuted; activeFocusOnTab: false; onClicked: Audio.toggleMic() }
            Item { Layout.fillWidth: true }
            IconButton { icon: "gear"; activeFocusOnTab: false; onClicked: { Surfaces.close(); SettingsHub.open(); } }
            IconButton { icon: "power"; activeFocusOnTab: false; onClicked: Surfaces.open("power") }
        }
    }
    ColumnLayout { // SW: position legend
        anchors { left: parent.left; bottom: parent.bottom; margins: Theme.s7 }
        spacing: Theme.s2
        Label { role: "micro"; dim: true; text: Compositor.displayName + (Power.hasBattery ? " · " + Fmt.percent(Power.level) + " " + Power.stateLabel.toLowerCase() : "") }
        Row {
            spacing: Theme.s4
            Repeater {
                model: [["type", "intent"], ["↑↓ ↵", "choose"], ["alt + arrows", "travel"], ["alt shift + arrows", "carry window"], ["esc", "close"]]
                Row { required property var modelData; spacing: Theme.s2
                    Label { role: "micro"; text: modelData[0] }
                    Label { role: "micro"; dim: true; text: modelData[1] } }
            }
        }
    }

    // ── Intent line ───────────────────────────────────────────────────
    Field {
        id: intent
        width: 520
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.s7 + 8 }
        large: true
        icon: "lens"
        placeholder: "Intent — apps, windows, places, commands"
        focus: true
        input.focus: true
        input.Keys.onPressed: e => lens.handleKey(e)
        Component.onCompleted: focusInput()
    }

}