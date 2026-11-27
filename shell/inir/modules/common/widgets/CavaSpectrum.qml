import QtQuick
import "../../../../inir/modules/common"
import "../../../../inir/services"

// Kestrel port: CavaSpectrumPainter is a C++ type from Ryoku's own Quickshell
// build. This stand-in draws the same bars with plain rectangles.
Item {
    id: root

    property bool active: false
    property var points: []
    property color spectrumColor: "transparent"
    property var spectrumColors: []
    property real spectrumOpacity: 1
    property bool mirroredStereo: true
    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomLeftRadius: 0
    property real bottomRightRadius: 0
    property real barsOrigin: 0
    property real smoothing: 0
    property string waveMode: ""
    property real lineWidth: 1
    property real edgeInset: 0
    property real edgeSoftness: 0
    property string frequencyProfile: ""
    property real accentStrength: 0
    property real barRadius: 0
    property real barMinHeight: 1
    property real barSpacing: 2
    property real pixelsPerBar: 0
    property real fillRatio: 1
    property string visualizerType: ""
    property real normalizationCeiling: 1
    property real startTaper: 0
    property real endTaper: 0
    property real startOpacity: 1
    property real endOpacity: 1
    property real clipSegments: 0
    property real sampleStartRatio: 0
    property real sampleEndRatio: 1
    property bool reverseFrequency: false

    visible: (root.points?.length ?? 0) > 0 && (root.active || root.opacity > 0.001)
    opacity: root.active ? Math.max(0, Math.min(1, root.spectrumOpacity)) : 0

    Row {
        anchors.fill: parent
        spacing: root.barSpacing

        Repeater {
            model: root.points ?? []

            Rectangle {
                required property var modelData
                width: Math.max(1, root.pixelsPerBar > 0
                    ? root.pixelsPerBar
                    : (parent.width - (root.points.length - 1) * root.barSpacing) / Math.max(1, root.points.length))
                height: Math.max(root.barMinHeight, root.height * Math.min(1, Math.max(0, modelData)))
                radius: root.barRadius
                anchors.bottom: parent.bottom
                color: root.spectrumColor
            }
        }
    }
}
