import QtQuick
import qs.components

SurfaceWindow {
    name: "power"
    placement: "center"
    coverBar: true
    dim: 0.7
    content: Component { PowerContent {} }
}
