pragma Singleton
import QtQuick
import Quickshell

// XDG locations for SSH. Computed once; SSH never writes outside these.
Singleton {
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")
    readonly property string cacheHome: Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")

    readonly property string configDir: configHome + "/ssh-shell"
    readonly property string stateDir: stateHome + "/ssh-shell"
    readonly property string cacheDir: cacheHome + "/ssh-shell"
    readonly property string themesDir: configDir + "/themes"

    readonly property string configFile: (Quickshell.env("SSH_SHELL_CONFIG") || (configDir + "/config.json"))
    readonly property string atlasFile: stateDir + "/atlas.json"
    readonly property string usageFile: stateDir + "/launcher-usage.json"
    readonly property string historyFile: stateDir + "/notifications.json"

    function ensure(dir) {
        // argv form: never passed through a shell.
        Quickshell.execDetached(["mkdir", "-p", dir]);
    }
}
