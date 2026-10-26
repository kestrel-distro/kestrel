import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "eclipse.mpris"

  readonly property int maxWidth: Number(setting("maxWidth", 220))
  property string track: ""

  // Always present as a slot; shows only the glyph when nothing is playing.
  visible: true
  implicitWidth: track !== "" && !vertical
    ? Math.min(maxWidth, label_row.implicitWidth + Style.spacing.controlPaddingX * 2)
    : icon.implicitWidth + Style.spacing.controlPaddingX * 2
  implicitHeight: barSize

  Behavior on implicitWidth {
    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
  }

  property bool spotifyAvailable: false

  function poll() {
    if (!spotifyCheck.running) spotifyCheck.running = true
  }

  Process {
    id: spotifyCheck
    command: ["playerctl", "-p", "spotify,spotify_player,zuno", "status"]
    onExited: function(code) {
      root.spotifyAvailable = code === 0
      var prefix = root.spotifyAvailable ? ["playerctl", "-p", "spotify,spotify_player,zuno"] : ["playerctl"]
      statusProc.command = prefix.concat(["status"])
      metaProc.command = prefix.concat(["metadata", "--format", "{{ artist }} – {{ title }}"])
      if (!statusProc.running) statusProc.running = true
    }
  }

  Process {
    id: statusProc
    onExited: function(code) {
      if (code !== 0) { root.track = ""; return }
      if (!metaProc.running) metaProc.running = true
    }
  }

  Process {
    id: metaProc
    stdout: StdioCollector {
      onStreamFinished: {
        const t = text.trim().replace(/\s+–\s+$/, "").trim()
        root.track = t === "" || t === "–" ? "Unknown track" : t
      }
    }
  }

  Timer {
    interval: 2500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.poll()
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    onClicked: root.bar && root.bar.run("playerctl -p spotify,spotify_player,zuno play-pause")

    // Scroll = player volume steps. Wheel tilt (horizontal scroll) = prev/next.
    onWheel: function(wheel) {
      if (!root.bar)
        return
      if (wheel.angleDelta.x !== 0) {
        if (wheel.angleDelta.x > 0)
          root.bar.run("playerctl -p spotify,spotify_player,zuno next")
        else
          root.bar.run("playerctl -p spotify,spotify_player,zuno previous")
      } else if (wheel.angleDelta.y !== 0) {
        var step = wheel.angleDelta.y > 0 ? "0.05+" : "0.05-"
        root.bar.run("playerctl -p spotify,spotify_player,zuno volume " + step)
      }
    }
  }



  Row {
    id: label_row
    anchors.centerIn: parent
    spacing: Style.space(6)

    Text {
      id: icon
      anchors.verticalCenter: parent.verticalCenter
      text: "󰎈"
      color: root.bar ? root.bar.barForeground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      opacity: 0.85
    }

    Item {
      width: Math.min(root.maxWidth, trackText.implicitWidth)
      height: barSize
      clip: true

      Text {
        id: trackText
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        width: parent.width
        text: root.track
        color: root.bar ? root.bar.barForeground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
        opacity: 0.85
      }
    }
  }
}
