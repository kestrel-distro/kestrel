import QtQuick
import "Singletons"

// Kestrel port: the depth-displaced mesh needs Ryoku.Spatial3D, a Quick3D
// geometry type from Ryoku's own plugin build. Without it the stage backdrop
// draws the wallpaper flat instead of in relief.
Item {
    id: root

    property url backgroundPath
    property url depthPath
    property url mattePath
    property size textureSize: Qt.size(Math.max(1, width), Math.max(1, height))
    property real pointerX: 0
    property real pointerY: 0
    property string mode: "spatial"
    property bool stretch: false
    property string screenName: ""
    property bool layered: false

    readonly property string motionMode: root.mode === "parallax" ? "parallax" : "spatial"
    readonly property real pivotDistance: 0

    function publishPivot() {}

    Image {
        id: backdrop
        anchors.fill: parent
        source: root.backgroundPath
        fillMode: root.stretch ? Image.Stretch : Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }
}
