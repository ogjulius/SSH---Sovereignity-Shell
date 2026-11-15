pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.configuration

// Notification daemon (org.freedesktop.Notifications) with history, DND,
// popups and actions. If another daemon already owns the bus name, SSH
// keeps running without one and says so in the log.
Singleton {
    id: n

    property var history: []        // newest first: plain records
    property var popups: []         // records currently shown as popups
    property var live: ({})         // id -> Notification (while the sender keeps it alive)
    property bool dnd: Config.notifications.doNotDisturb
    readonly property int unread: history.filter(h => !h.read).length
    readonly property bool serving: loader.active && loader.item !== null

    function record(notif) {
        return {
            id: notif.id, app: notif.appName || "Application", appIcon: notif.appIcon || "",
            summary: notif.summary || "", body: notif.body || "", image: notif.image || "",
            urgency: notif.urgency, time: Date.now(), read: false,
            actions: notif.actions ? notif.actions.map(a => ({ id: a.identifier, text: a.text })) : []
        };
    }

    function onIncoming(notif) {
        notif.tracked = true;
        const r = record(notif);
        const l = Object.assign({}, live); l[r.id] = notif; live = l;
        notif.closed.connect(() => { const m = Object.assign({}, n.live); delete m[r.id]; n.live = m; n.dropPopup(r.id); });
        // Replacement (same id) updates in place.
        history = [r].concat(history.filter(h => h.id !== r.id)).slice(0, Config.notifications.historyLimit);
        const critical = notif.urgency === NotificationUrgency.Critical;
        if (!dnd || critical) {
            popups = [r].concat(popups.filter(p => p.id !== r.id)).slice(0, Config.notifications.maxPopups);
        }
        persist.restart();
    }

    function dropPopup(id) { popups = popups.filter(p => p.id !== id); }
    function dismiss(id) {
        const obj = live[id];
        if (obj) obj.dismiss();
        dropPopup(id);
        history = history.filter(h => h.id !== id);
        persist.restart();
    }
    function invoke(id, actionId) {
        const obj = live[id];
        if (!obj) return;
        const a = obj.actions.find(x => x.identifier === actionId);
        if (a) a.invoke();
        dropPopup(id);
    }
    function clearAll() {
        for (const k in live) live[k].dismiss();
        history = []; popups = [];
        persist.restart();
    }
    function markRead() { history = history.map(h => Object.assign({}, h, { read: true })); }
    function setDnd(on) { Config.set("notifications.doNotDisturb", on); if (on) popups = popups.filter(p => p.urgency === NotificationUrgency.Critical); }

    // Grouped by app for the history view: [{ app, items: [...] }]
    readonly property var groups: {
        const order = [], map = {};
        for (const h of history) {
            if (!map[h.app]) { map[h.app] = { app: h.app, appIcon: h.appIcon, items: [] }; order.push(map[h.app]); }
            map[h.app].items.push(h);
        }
        return order;
    }

    Loader {
        id: loader
        active: Config.notifications.enabled && Quickshell.env("SSH_SHELL_NO_NOTIFICATIONS") !== "1"
        sourceComponent: NotificationServer {
            keepOnReload: true
            bodySupported: true
            bodyMarkupSupported: false
            actionsSupported: true
            imageSupported: true
            persistenceSupported: true
            onNotification: notif => n.onIncoming(notif)
        }
    }

    // Optional plain-text persistence (off by default).
    Timer {
        id: persist
        interval: 1500
        onTriggered: {
            if (!Config.notifications.persistHistory) return;
            Paths.ensure(Paths.stateDir);
            store.setText(JSON.stringify(n.history.map(h => ({ app: h.app, summary: h.summary, body: h.body, time: h.time, urgency: h.urgency, read: h.read, id: -h.time }))));
        }
    }
    FileView {
        id: store
        path: Config.notifications.persistHistory ? Paths.historyFile : ""
        printErrors: false
        onLoaded: {
            try {
                const old = JSON.parse(text());
                if (Array.isArray(old)) n.history = n.history.concat(old.map(o => Object.assign({ appIcon: "", image: "", actions: [] }, o)));
            } catch (e) {}
        }
    }
}
