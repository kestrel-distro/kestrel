pragma Singleton
import QtQuick
QtObject {
  readonly property bool present: false
  readonly property bool charging: false
  readonly property bool discharging: false
  readonly property bool full: false
  readonly property bool hasTime: false
  readonly property real pct: 0
  readonly property real health: 0
  readonly property bool healthSupported: false
}
