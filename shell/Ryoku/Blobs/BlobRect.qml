import QtQuick

Rectangle {
    id: root
    property var group: null
    property real stiffness: 0
    property real damping: 0
    property real deformScale: 0
    property bool sinks: false

    color: group && group.color ? group.color : "transparent"
    border.width: group && group.borderWidth ? group.borderWidth : 0
    border.color: group && group.borderColor ? group.borderColor : "transparent"
}
