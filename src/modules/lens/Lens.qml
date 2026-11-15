import QtQuick
import qs.components
import qs.configuration

SurfaceWindow {
    name: "lens"
    placement: "fill"
    coverBar: true
    dim: Config.lens.dim
    content: Component { LensContent {} }
}
