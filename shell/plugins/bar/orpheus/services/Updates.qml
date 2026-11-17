pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Adapter: pending package updates through checkupdates (pacman-contrib), the
// same question the update widget asks. A missing tool reads as zero updates.
QtObject {
  id: root

  readonly property string channel: "stable"
  property int pending: 0

  function check() { if (!probe.running) probe.running = true }

  Process {
    id: probe
    command: ["sh", "-c", "command -v checkupdates >/dev/null 2>&1 && checkupdates 2>/dev/null | wc -l || echo 0"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var n = Number(String(text()).trim())
        root.pending = isFinite(n) && n > 0 ? n : 0
      }
    }
  }

  Timer { interval: 21600000; running: true; repeat: true; onTriggered: root.check() }
  Component.onCompleted: check()
}
