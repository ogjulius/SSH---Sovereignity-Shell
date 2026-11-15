import QtQuick
import qs.components

SurfaceWindow {
    name: "atlas"
    placement: "fill"
    coverBar: true
    dim: 0
    content: Component { AtlasContent {} }
}
