import QtQuick

// Kestrel port: SystemGraph is a C++ history plot from Ryoku's own Quickshell
// build. This stand-in keeps the API and draws a flat baseline.
Item {
    id: root

    property var source: null
    property string detailPoints: ""
    property var channels: []
    property var colors: []
    property color gridColor: "transparent"
    property color fill: "transparent"
    property bool showGrid: false
    property bool animated: false
    property real lineWidth: 1
    property bool clip: false
    property bool active: false

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: root.gridColor
    }
}
