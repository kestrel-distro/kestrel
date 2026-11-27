import QtQuick

// Kestrel port: CavaFeed is a C++ type from Ryoku's own Quickshell build. This
// stand-in reports silence so the meters around it load.
Item {
    id: root

    property bool active: false
    property int bars: 32
    property int framerate: 30
    property string method: "pipewire"
    property string source: "auto"
    property bool autosens: true
    property real sensitivity: 150
    property real noiseReduction: 25
    property bool peakFollow: true
    property real staleMs: 120
    property real noiseFloor: 0.06
    property bool captureActive: false

    readonly property var levels: []
    readonly property real energy: 0
    readonly property bool silent: true
}
