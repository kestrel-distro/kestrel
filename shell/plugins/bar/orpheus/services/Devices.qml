pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Adapter: the panel backlight. Reads the kernel's brightness file and writes
// through kestrel-brightness-display, the same command the brightness keys use,
// so the choice lands everywhere the desktop expects it. DDC monitors are the
// external path and stay out until the product asks for them.
QtObject {
  id: root

  readonly property string sysRoot: "/sys/class/backlight"
  property real backlightPct: 0
  readonly property bool backlightAvailable: _max > 0
  readonly property var ddcMonitors: []

  property real _max: 0

  function setBacklight(value) {
    var pct = Math.max(1, Math.min(100, Math.round(Number(value) || 0)))
    root.backlightPct = pct
    if (!setter.running) setter.running = true
    root.pending = pct
  }

  property real pending: 0

  function parseBrightness(value) {
    if (typeof value === "number") return value
    var m = String(value || "").match(/-?\d+(?:\.\d+)?/)
    return m ? Number(m[0]) : 0
  }

  function setBrightness(value) { root.setBacklight(value) }
  function startProbes() { if (!probe.running) probe.running = true }
  function stopProbes() {}

  Process {
    id: probe
    command: ["sh", "-c", "for b in /sys/class/backlight/*; do "
      + "[ -r \"$b/brightness\" ] || continue; "
      + "printf '%s %s\\n' \"$(cat \"$b/brightness\")\" \"$(cat \"$b/max_brightness\")\"; break; done"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parts = String(text()).trim().split(/\s+/)
        var cur = Number(parts[0] || 0)
        var max = Number(parts[1] || 0)
        root._max = max
        if (max > 0) root.backlightPct = Math.round(cur / max * 100)
      }
    }
  }

  Process {
    id: setter
    command: ["kestrel-brightness-display", "--no-osd", Math.round(root.pending) + "%"]
  }

  Timer { interval: 0; running: false; repeat: false }
  Timer { interval: 30000; running: true; repeat: true; onTriggered: root.startProbes() }
  Component.onCompleted: startProbes()
}
