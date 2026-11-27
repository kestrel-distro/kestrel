import QtQuick

// Kestrel port: the shader blob renderer is not built for this image, so a blob
// group only carries its paint settings and the rects draw as plain shapes.
QtObject {
    property color color: "transparent"
    property color borderColor: "transparent"
    property real borderWidth: 0
    property real smoothing: 0
    property real shadowStrength: 0
    property real shadowSize: 0
    property real radius: 0
}
