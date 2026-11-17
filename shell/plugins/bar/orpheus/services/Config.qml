pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Adapter: Orpheus' settings live in their own file, so the bar product never
// writes into the desktop's shell.json. The product's Prefs reads `orpheus`
// from here; a missing or half-written file reads as empty and every key falls
// back to its compiled default.
QtObject {
  id: root

  readonly property string path:
    (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config"))
    + "/kestrel/orpheus.json"

  property var orpheus: ({})

  readonly property string weatherUnit: {
    var v = root.orpheus ? root.orpheus.weatherUnit : undefined
    return (typeof v === "string" && v.length > 0) ? v : "auto"
  }

  FileView {
    id: file
    path: root.path
    blockLoading: true
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var o = JSON.parse(text() || "{}")
        root.orpheus = (o && typeof o === "object") ? o : {}
      } catch (e) {
        root.orpheus = {}
      }
    }
    onLoadFailed: root.orpheus = ({})
  }
}
