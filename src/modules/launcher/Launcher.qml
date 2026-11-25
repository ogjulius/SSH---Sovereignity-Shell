import QtQuick
import qs.components

SurfaceWindow {
    name: "launcher"
    placement: "center"
    dim: 0.25
    content: Component { LauncherContent {} }
}
