pragma Singleton
import QtQuick
import Quickshell.Services.Mpris
QtObject {
  readonly property bool present: Mpris.players.values.length > 0
  readonly property var player: present ? Mpris.players.values[0] : null
  readonly property bool playing: player ? player.isPlaying === true : false
  readonly property bool playerSet: present
  readonly property bool isWallpaper: false
  function toggle() { if (player && player.canTogglePlaying) player.togglePlaying() }
}
