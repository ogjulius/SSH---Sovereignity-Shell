// Headless configuration check, used by `ssh-shell check-config` and the
// installer. Validates the file named by SSH_SHELL_CONFIG with SSH's own
// schema (the same code the shell uses) and never writes anything.
//
//   SSH_SHELL_CONFIG=~/.config/ssh-shell/config.json QT_QPA_PLATFORM=offscreen qs -p check-config.qml
//
// Prints "SSH-CHECK OK" or one "SSH-CHECK <problem>" line per problem.
import QtQuick
import Quickshell
import Quickshell.Io
import "configuration/Schema.js" as Schema

ShellRoot {
    function report(lines) {
        if (lines.length === 0) console.info("SSH-CHECK OK");
        else for (const l of lines) console.info("SSH-CHECK " + l);
        Qt.quit();
    }

    FileView {
        path: Quickshell.env("SSH_SHELL_CONFIG") || ""
        printErrors: false
        onLoaded: {
            const raw = text();
            if (raw.trim().length === 0) { report([]); return; }
            let parsed;
            try { parsed = JSON.parse(raw); }
            catch (e) { report(["not valid JSON: " + e.message]); return; }
            if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) { report(["the top level must be a JSON object"]); return; }
            report(Schema.merge(parsed).warnings);
        }
        onLoadFailed: err => report(Quickshell.env("SSH_SHELL_CONFIG") ? ["cannot read " + path] : ["SSH_SHELL_CONFIG is not set"])
    }
}
