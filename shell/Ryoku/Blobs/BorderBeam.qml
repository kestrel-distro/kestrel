import QtQuick

Item {
    property string mode: "line"
    property real radius: 0
    property color color: "transparent"
    property real strokeWidth: 1
    property real blur: 0
    property real strength: 1
    property real duration: 2
    property bool active: false

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: parent.active ? parent.strokeWidth : 0
        border.color: parent.color
    }
}
