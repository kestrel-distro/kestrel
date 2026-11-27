import QtQuick

// Kestrel port: ScreencopyView is a Quickshell type this build does not ship.
// The windows that preview other surfaces draw an empty frame instead.
Item {
    id: root

    property var captureSource: null
    property bool live: false
    property bool paintCursor: false
    property bool hasContent: false
    property bool hasCursor: false
    property size constraintSize: Qt.size(width, height)
    property Component sourceComponent: null

    signal started()
    signal stopped()
    signal failed()
    signal captured()

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }
}
