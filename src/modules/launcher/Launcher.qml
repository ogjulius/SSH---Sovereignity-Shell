import QtQuick
import qs.components

SurfaceWindow {
    name: "launcher"
    placement: "top"
    dim: 0.25
    content: Component { LauncherContent {} }
}
