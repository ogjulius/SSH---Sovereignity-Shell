import QtQuick
import qs.components

SurfaceWindow {
    name: "lens"
    placement: "fill"
    coverBar: true
    dim: 0.62
    content: Component { LensContent {} }
}
