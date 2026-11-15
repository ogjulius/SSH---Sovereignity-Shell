// Headless keybind output for `ssh-shell keybinds <target>`: reads your
// configuration with SSH's schema and prints the block, so it works without a
// running shell. Never writes anything.
//
//   SSH_KEYBINDS_TARGET=hyprland|hyprland-lua|niri|list QT_QPA_PLATFORM=offscreen qs -p keybinds-print.qml
//
// Prints one "SSH-OUT <line>" per output line.
import QtQuick
import Quickshell
import Quickshell.Io
import "configuration/Schema.js" as Schema
import "modules/settings/Keybinds.js" as KB

ShellRoot {
    id: root
    readonly property string file: Quickshell.env("SSH_SHELL_CONFIG")
        || ((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/ssh-shell/config.json")

    function emit(user) {
        const kb = Schema.merge(user).value.keybinds;
        for (const line of KB.generate(Quickshell.env("SSH_KEYBINDS_TARGET") || "hyprland", kb).split("\n"))
            console.info("SSH-OUT " + line);
        Qt.quit();
    }

    FileView {
        path: root.file
        printErrors: false
        onLoaded: { let u = {}; try { u = JSON.parse(text() || "{}"); } catch (e) {} root.emit(u); }
        onLoadFailed: err => root.emit({})
    }
}
