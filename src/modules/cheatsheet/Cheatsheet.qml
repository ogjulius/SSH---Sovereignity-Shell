import QtQuick
import qs.components

// Keybind cheatsheet (`ssh-shell keybinds cheatsheet`, Super+F1 by default).
// Created on open, destroyed after it closes, like every surface.
SurfaceWindow {
    name: "cheatsheet"
    placement: "center"
    coverBar: true
    dim: 0.55
    content: Component { CheatsheetContent {} }
}
