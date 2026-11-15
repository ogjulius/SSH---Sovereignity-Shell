pragma Singleton
import QtQuick
import Quickshell

// Opens/closes the Settings window (a normal toplevel, so it tiles and
// behaves like any application window).
Singleton {
    property bool shown: false
    property string page: "appearance"
    function open(p) { if (p) page = p; shown = true; }
    function close() { shown = false; }
    function toggle() { shown = !shown; }
}
