import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var kestrelPath
  property var shell
  property var manifest
  readonly property string pluginId: (manifest && manifest.id) || "eclipse.pomodoro"
  property bool opened: false
  // pinned = glued above every window (Overlay layer) and position locked.
  // Unpinned behaves like a normal floating window above others (Top layer).
  property bool pinned: false

  readonly property color focusColor: "#f38ba8"
  readonly property color breakColor: "#a6e3a1"
  readonly property color phaseColor: timerLogic.phase === "break" ? breakColor : (timerLogic.phase === "focus" ? focusColor : Color.accent)

  function open(payloadJson) {
    root.opened = true
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide(root.pluginId)
  }

  IpcHandler {
    target: "eclipse.pomodoro"

    function toggle() {
      if (root.opened) root.dismiss()
      else root.open("{}")
    }
  }

  PanelWindow {
    id: win

    visible: root.opened
    color: "transparent"
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    WlrLayershell.namespace: "eclipse-pomodoro"
    WlrLayershell.layer: root.pinned ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: card }

    property int posX: 160
    property int posY: 140

    Rectangle {
      id: card

      x: win.posX
      y: win.posY
      width: 220
      height: 392
      radius: Style.cornerRadius + 4
      gradient: Gradient {
        GradientStop { position: 0; color: Qt.lighter(Color.background, 1.22) }
        GradientStop { position: 1; color: Color.background }
      }
      border.color: root.phaseColor
      border.width: 1

      // ---------------- header ----------------
      Item {
        id: header

        width: parent.width
        height: Style.space(34)

        // Drag surface. Uses global cursor deltas against the position taken
        // at press — local deltas would fight the moving window and glitch.
        MouseArea {
          id: dragArea

          anchors.fill: parent
          cursorShape: root.pinned ? Qt.ArrowCursor : Qt.SizeAllCursor
          enabled: !root.pinned
          property point pressGlobal
          property point pressCard
          onPressed: function(mouse) {
            var gp = dragArea.mapToItem(null, mouse.x, mouse.y)
            pressGlobal = Qt.point(gp.x, gp.y)
            pressCard = Qt.point(card.x, card.y)
          }
          onPositionChanged: function(mouse) {
            if (!pressed || !dragArea.pressed)
              return
            var gp = dragArea.mapToItem(null, mouse.x, mouse.y)
            win.posX = Math.max(0, Math.min(win.screen.width - card.width, pressCard.x + (gp.x - dragArea.pressGlobal.x)))
            win.posY = Math.max(0, Math.min(win.screen.height - card.height, pressCard.y + (gp.y - dragArea.pressGlobal.y)))
          }

          Text {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            text: "POMODORO"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.letterSpacing: 2
            opacity: 0.55
          }
        }

        Row {
          anchors.right: parent.right
          anchors.rightMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(6)

          // Pin: Overlay-layer glue + drag lock.
          Rectangle {
            width: 24
            height: 24
            radius: 6
            color: root.pinned ? Qt.rgba(root.focusColor.r, root.focusColor.g, root.focusColor.b, 0.25) : "transparent"
            border.color: root.pinned ? root.focusColor : Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            // EBA0 pinned / EB2B pin (Codicons)
            Text {
              anchors.centerIn: parent
              text: root.pinned ? "\uEBA0" : "\uEB2B"
              color: root.pinned ? root.focusColor : Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              opacity: root.pinned ? 1 : 0.6
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.pinned = !root.pinned
            }
          }

          Rectangle {
            width: 24
            height: 24
            radius: 6
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: "✕"
              color: Color.foreground
              font.pixelSize: 11
              opacity: 0.7
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.dismiss()
            }
          }
        }
      }

      // ---------------- ring + centered readout ----------------
      Item {
        id: ringBox

        width: 168
        height: 168
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.topMargin: Style.space(6)

        Canvas {
          id: ring

          anchors.fill: parent
          antialiasing: true
          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var cx = width / 2
            var cy = height / 2
            var r = width / 2 - 10
            var lw = 9
            var start = -Math.PI / 2

            // background track
            ctx.lineWidth = lw
            ctx.lineCap = "round"
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08)
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()

            if (timerLogic.phase === "idle") {
              // duration dial: accent arc up to the selected length + knob
              var frac = (timerLogic.focusMinutes - 5) / (120 - 5)
              ctx.strokeStyle = Color.accent
              ctx.beginPath()
              ctx.arc(cx, cy, r, start, start + frac * Math.PI * 2)
              ctx.stroke()

              var ang = start + frac * Math.PI * 2
              ctx.fillStyle = Color.accent
              ctx.beginPath()
              ctx.arc(cx + r * Math.cos(ang), cy + r * Math.sin(ang), lw * 0.85 + 2, 0, Math.PI * 2)
              ctx.fill()
            } else {
              // draining progress arc
              ctx.strokeStyle = root.phaseColor
              ctx.beginPath()
              ctx.arc(cx, cy, r, start, start + timerLogic.fraction * Math.PI * 2)
              ctx.stroke()
            }
          }
        }

        Connections {
          target: timerLogic
          function onRemainingChanged() {
            ring.requestPaint()
          }
          function onFocusMinutesChanged() {
            ring.requestPaint()
          }
          function onPhaseChanged() {
            ring.requestPaint()
          }
          function onPausedChanged() {
            ring.requestPaint()
          }
        }

        // Duration dial (idle only): drag or click along the ring.
        MouseArea {
          anchors.fill: parent
          enabled: timerLogic.phase === "idle"
          cursorShape: Qt.CrossCursor
          property bool setting: false
          onPressed: function(mouse) {
            setting = true
            setFromPoint(mouse.x, mouse.y)
          }
          onPositionChanged: function(mouse) {
            if (setting)
              setFromPoint(mouse.x, mouse.y)
          }
          onReleased: setting = false

          function setFromPoint(x, y) {
            var dx = x - width / 2
            var dy = y - height / 2
            if (Math.sqrt(dx * dx + dy * dy) < width / 2 - 26)
              return // ignore the middle; only the ring is a control
            var deg = (Math.atan2(dy, dx) * 180 / Math.PI + 90 + 360) % 360
            var mins = 5 + Math.round(deg / 360 * (120 - 5))
            // Physical lock: reject wrap-around jumps so the knob stops hard
            // at the ends instead of whipping from 2h straight down to 5m.
            if (Math.abs(mins - timerLogic.focusMinutes) > 62)
              return
            timerLogic.focusMinutes = Math.max(5, Math.min(120, mins))
          }
        }

        Column {
          anchors.centerIn: parent
          spacing: 0

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: timerLogic.phase === "idle" ? "READY" : timerLogic.phase.toUpperCase() + (timerLogic.paused ? " · PAUSED" : "")
            color: root.phaseColor
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.letterSpacing: 2
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: timerLogic.label
            color: Color.foreground
            font.family: Style.resolvedFontFamily
            // 100:00 needs a smaller face to stay inside the ring.
            font.pixelSize: timerLogic.label.length > 4 ? 30 : 40
            font.bold: true
          }
        }
      }

      // ---------------- controls ----------------
      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.space(12)
        width: parent.width - Style.space(32)
        spacing: Style.space(8)

        Button {
          width: parent.width
          text: timerLogic.phase === "idle" ? "▶ Start focus" : (timerLogic.paused ? "▶ Resume" : "⏸ Pause")
          onClicked: timerLogic.toggleStart()
        }

        Button {
          width: parent.width
          text: "↩ Resume focus"
          tooltipText: timerLogic.resumeAvailable ? "Back to your interrupted session (" + Math.ceil(timerLogic.savedFocusRemaining / 60) + " min left)" : "Start a fresh focus block"
          onClicked: timerLogic.resumeFocus()
        }

        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            width: (parent.width - Style.space(8)) / 2
            text: "☕ 1m break"
            tooltipText: "One-minute break"
            onClicked: timerLogic.beginBreak(1)
          }

          Button {
            width: (parent.width - Style.space(8)) / 2
            text: "↺ Reset"
            onClicked: timerLogic.reset()
          }
        }
      }
    }
  }

  QtObject {
    id: timerLogic

    property int focusMinutes: 25
    property int breakMinutes: 5
    property string phase: "idle"
    property bool paused: false
    property int remaining: 0
    property int total: 0
    // What was left of the focus session when the break started.
    property int savedFocusRemaining: 0
    readonly property bool resumeAvailable: savedFocusRemaining > 0

    readonly property real fraction: total > 0 ? Math.max(0, Math.min(1, remaining / total)) : 1

    readonly property string label: phase === "idle"
      ? focusMinutes + ":00"
      : (paused ? "⏸ " : "") + Math.floor(Math.max(remaining, 0) / 60) + ":" + String(Math.max(remaining, 0) % 60).padStart(2, "0")

    function notify(message) {
      Quickshell.execDetached(["kestrel-notification-send", "-g", "󰄉", "Pomodoro", message])
    }

    function begin(minutes, nextPhase) {
      phase = nextPhase
      paused = false
      remaining = minutes * 60
      total = remaining
    }

    function beginBreak(minutes) {
      if (phase === "focus")
        savedFocusRemaining = remaining
      begin(minutes, "break")
    }

    function resumeFocus() {
      if (resumeAvailable) {
        phase = "focus"
        paused = false
        remaining = savedFocusRemaining
        total = savedFocusRemaining
        savedFocusRemaining = 0
      } else {
        begin(focusMinutes, "focus")
      }
    }

    function toggleStart() {
      if (phase === "idle") {
        savedFocusRemaining = 0
        begin(focusMinutes, "focus")
      } else
        paused = !paused
    }

    function reset() {
      phase = "idle"
      paused = false
      remaining = 0
      total = 0
      savedFocusRemaining = 0
    }
  }

  Timer {
    interval: 1000
    running: timerLogic.phase !== "idle" && !timerLogic.paused
    repeat: true
    onTriggered: {
      timerLogic.remaining -= 1
      if (timerLogic.remaining > 0)
        return

      if (timerLogic.phase === "focus") {
        timerLogic.notify("Focus done — take a break")
        timerLogic.beginBreak(timerLogic.breakMinutes)
      } else {
        timerLogic.notify("Break over — back to focus")
        timerLogic.begin(timerLogic.focusMinutes, "focus")
      }
    }
  }
}
