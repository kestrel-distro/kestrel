pragma Singleton
import QtQuick
import Quickshell.Services.Mpris
QtObject {
  readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
  readonly property real position: 0
  readonly property real duration: 0
  readonly property bool holdClock: false
  function coverFor(p) { return "" }
  function seekPosition(p) {}
}
