pragma Singleton
import QtQuick
import Quickshell
import qs.compositors

// Popup coordination. Exactly one *surface* (Lens, Atlas, launcher, a
// bar panel, power menu) is open at a time; opening one closes the other.
// Surfaces are created lazily on first open and destroyed after their exit
// animation, so a closed surface costs nothing.
Singleton {
    id: s

    property string active: ""          // name of the open surface, "" if none
    property var loaded: ({})           // name -> true while instantiated
    property string screenName: ""      // output the surface opens on
    property var anchorRect: null       // optional {x, y, w} hint from the bar

    function targetScreen() {
        const want = Compositor.focusedOutput;
        for (const sc of Quickshell.screens) if (sc.name === want) return sc;
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function open(name, screen, anchor) {
        const sc = screen || targetScreen();
        screenName = sc ? sc.name : "";
        anchorRect = anchor || null;
        const l = Object.assign({}, loaded);
        l[name] = true;
        loaded = l;
        active = name;
    }
    function close(name) {
        if (name === undefined || active === name) active = "";
    }
    function toggle(name, screen, anchor) {
        if (active === name) close(); else open(name, screen, anchor);
    }
    function isOpen(name) { return active === name; }
    // Called by a surface once its exit animation has finished.
    function release(name) {
        if (active === name) return;
        const l = Object.assign({}, loaded);
        delete l[name];
        loaded = l;
    }
}
