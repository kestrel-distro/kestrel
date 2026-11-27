import QtQuick

// Kestrel port: Ryoku's SystemMonitor is a C++ type from its own Quickshell
// build. This stand-in reports idle readings so the surfaces around it load.
Item {
    id: root

    property bool active: false
    property int samplePeriodMs: 1500
    property int historyLimit: 48
    property bool includeVirtualNetwork: true

    readonly property real cpuPercent: 0
    readonly property real memoryPercent: 0
    readonly property real memoryUsedGiB: 0
    readonly property real memoryTotalGiB: 0
    readonly property real cpuTemp: 0
    readonly property bool cpuTempAvailable: false
    readonly property var cpuHistory: []
}
