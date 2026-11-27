import QtQuick

Rectangle {
    id: root
    property var group: null
    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomLeftRadius: 0
    property real bottomRightRadius: 0
    property real stiffness: 0
    property real damping: 0
    property real deformScale: 0
    property bool sinks: false

    color: group && group.color ? group.color : "transparent"
    radius: Math.max(root.topLeftRadius, root.topRightRadius,
                     root.bottomLeftRadius, root.bottomRightRadius)
    border.width: group && group.borderWidth ? group.borderWidth : 0
    border.color: group && group.borderColor ? group.borderColor : "transparent"
}
