pragma Singleton
import QtQuick
QtObject {
  readonly property bool backlightAvailable: false
  readonly property real backlightPct: 0
  readonly property var ddcMonitors: []
  function setBacklight(v) {}
  function setBrightness(v) {}
  function parseBrightness(v) { return 0 }
  function startProbes() {}
  function stopProbes() {}
}
