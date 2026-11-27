import QtQuick

Item {
    property string state: ""
    property string preset: ""
    property color ink: "transparent"
    property bool animated: false

    Rectangle {
        anchors.centerIn: parent
        width: 20
        height: 20
        radius: 10
        color: "transparent"
        border.width: 2
        border.color: parent.ink
        opacity: parent.animated ? 1 : 0
    }
}
