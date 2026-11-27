import QtQuick
import QtQuick.Shapes

// Kestrel port: flat wave stand-in for the shader wave.
Item {
    property var levels: []
    property real gain: 1
    property int points: 16
    property bool stepped: false
    property real blockPitch: 14

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }
}
