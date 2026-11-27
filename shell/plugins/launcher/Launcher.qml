import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "LauncherModel.js" as Model

// The command palette, set in the paper-and-ink language: a sheet with a small
// masthead, one search line, a ruled result column, and micro-caps key hints.
// The chosen row is not tinted with colour — it inverts to bone, which is the
// language's only emphasis. Rules, ink and the inversion pair come from the
// shared tokens, so a light theme stays legible and a dark one stays quiet.
//
// Apps come from the shell AppLibrary, matching the menu's hidden entries,
// icons and launch path. Prefixes route: "=" calculates, "?" searches the web,
// "/" lists actions; a bare query searches apps, then falls back to actions
// and finally the web.
Item {
  id: root

  property string kestrelPath: Quickshell.env("KESTREL_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property string query: ""
  property int selectedIndex: 0
  property bool cursorActive: false
  property var rows: []

  // ---------------------------------------------------------------- surfaces
  property color background: Commons.Color.launcher.background
  readonly property color paper: {
    // A sheet one step off the paper, so the card reads as a surface held over
    // the desktop instead of a hole cut in the wallpaper.
    var b = root.background
    return Commons.Tokens.light ? Qt.darker(b, 1.02) : Qt.lighter(b, 1.9)
  }
  property color foreground: Commons.Color.launcher.text
  // Derive the rules and the two muted inks from this surface's own text
  // colour: the card already resolved the theme's [launcher] role, and the
  // shared ink tokens track the *window* foreground, which can lag a theme
  // swap. This keeps the card internally consistent on any theme.
  readonly property color ruleSoft: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.13)
  readonly property color rule: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.26)
  readonly property color ruleStrong: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.42)
  readonly property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.66)
  readonly property color faint: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  readonly property color tint: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.06)
  readonly property string displayFamily: Commons.Tokens.displayFamily
  readonly property string uiFamily: Commons.Tokens.uiFamily
  readonly property string monoFamily: Commons.Tokens.monoFamily
  readonly property int radius: Commons.Tokens.radius

  // ---------------------------------------------------------------- geometry
  readonly property int pad: Style.spacing.panelPadding + Style.spacing.md
  readonly property int rowHeight: Style.space(52)
  readonly property int searchHeight: Style.space(64)
  readonly property int headerHeight: Style.space(44)
  readonly property int groupHeight: Style.space(30)
  readonly property int chipsHeight: root.query.length === 0 ? Style.space(38) : 0
  readonly property int footerHeight: Style.space(44)
  readonly property int cardWidth: Math.min(Style.space(680), panel.width - pad * 2)
  readonly property int visibleRows: Math.min(root.rows.length, 9)
  readonly property int listHeight: root.rows.length > 0 ? root.visibleRows * rowHeight : 0
  readonly property int cardHeight: pad * 2 + headerHeight + 1 + searchHeight + 1
    + (root.rows.length > 0 ? groupHeight + listHeight : 0)
    + chipsHeight + footerHeight + 1

  readonly property string groupLabel: {
    if (root.query.length === 0) return "ACTIONS"
    if (root.query.charAt(0) === "/") return "ACTIONS"
    if (root.query.charAt(0) === "=") return "CALCULATION"
    if (root.query.charAt(0) === "?") return "WEB"
    if (/^[0-9(+-]/.test(root.query)) return "CALCULATION"
    if (root.rows.length > 0 && root.rows[0].kind === "web") return "WEB"
    return "APPLICATIONS"
  }

  property real reveal: root.opened ? 1 : 0
  Behavior on reveal {
    NumberAnimation { duration: Style.duration(140); easing.type: Easing.OutCubic }
  }

  function open(payloadJson) {
    root.query = ""
    root.selectedIndex = 0
    root.cursorActive = false
    root.opened = true
    root.refresh()
    if (root.shell && root.shell.appLibrary) root.shell.appLibrary.refreshIcons()
  }

  function close() {
    root.opened = false
  }

  function appRows(q) {
    var library = root.shell ? root.shell.appLibrary : null
    if (!library || typeof library.sortedEntries !== "function") return []
    var entries = library.sortedEntries(q) || []
    var out = []
    for (var i = 0; i < entries.length && out.length < 50; i++) {
      var entry = entries[i]
      out.push({
        kind: "app",
        id: String(entry.id || ""),
        name: library.entryName(entry),
        subtext: library.entrySubtext(entry),
        icon: library.iconSource(entry.icon || ""),
        hint: ""
      })
    }
    return out
  }

  function actionRows(q) {
    var actions = Model.sortedActions(q)
    var out = []
    for (var i = 0; i < actions.length; i++) {
      out.push({
        kind: "action",
        id: actions[i].id,
        name: actions[i].name,
        subtext: actions[i].subtext,
        icon: ((root.shell && root.shell.appLibrary) ? root.shell.appLibrary.iconSource(actions[i].icon || "") : ""),
        command: actions[i].command,
        hint: "RUN"
      })
    }
    return out
  }

  function calcRow(q) {
    var value = Model.calculate(q)
    if (!value) return null
    return { kind: "calc", id: "calc", name: value, subtext: "Copy the result", icon: "", payload: value, hint: "COPY" }
  }

  function webRow(q) {
    var value = Model.webQuery(q)
    if (!value) return null
    return { kind: "web", id: "web", name: value, subtext: "Search the web", icon: "", payload: value, hint: "WEB" }
  }

  function refresh() {
    var q = String(root.query || "")
    var next = []
    var calc = q.charAt(0) === "=" || /^[0-9(+-]/.test(q) ? root.calcRow(q) : null
    if (calc) next.push(calc)

    if (q.length === 0 || q.charAt(0) !== "/") {
      var apps = root.appRows(q)
      for (var i = 0; i < apps.length; i++) next.push(apps[i])
    }
    if (q.length === 0 || q.charAt(0) === "/" || next.length === 0)
      next = next.concat(root.actionRows(q))
    if (q.length > 0 && q.charAt(0) !== "/" && q.charAt(0) !== "=") {
      var web = root.webRow(q)
      if (web && next.length < 50) next.push(web)
    }
    root.rows = next
    if (root.selectedIndex >= next.length) root.selectedIndex = Math.max(0, next.length - 1)
    if (!root.cursorActive) root.selectedIndex = 0
  }

  function select(delta) {
    if (root.rows.length === 0) return
    var index = root.selectedIndex + delta
    if (index < 0) index = root.rows.length - 1
    if (index >= root.rows.length) index = 0
    root.selectedIndex = index
    root.cursorActive = true
    resultList.positionViewAtIndex(index, ListView.Contain)
  }

  function activate(index) {
    var row = root.rows[index]
    if (!row) return
    root.close()
    if (row.kind === "app") {
      if (root.shell && root.shell.appLibrary) root.shell.appLibrary.launch(row.id, row.name)
    } else if (row.kind === "action") {
      Util.execDetached(row.command)
    } else if (row.kind === "calc") {
      Util.execDetached("wl-copy " + Util.shellQuote(row.payload))
    } else if (row.kind === "web") {
      Util.execDetached("kestrel-launch-browser " + Util.shellQuote("https://duckduckgo.com/?q=" + encodeURIComponent(row.payload)))
    }
  }

  onQueryChanged: root.refresh()
  onOpenedChanged: {
    if (!root.opened) {
      root.query = ""
      return
    }
    Qt.callLater(function() { if (searchInput) searchInput.forceActiveFocus() })
  }

  OverlayWindow {
    id: panel
    shown: root.opened
    shownKeyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "kestrel-launcher"

    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.42)
      opacity: root.reveal
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.opened
      onClicked: root.close()
    }

    Rectangle {
      id: card
      width: root.cardWidth
      height: Math.min(root.cardHeight, panel.height - root.pad * 2)
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.max(root.pad, Math.round((panel.height - height) * 0.2))
      radius: root.radius + 4
      color: root.paper
      border.width: 1
      border.color: root.ruleStrong
      opacity: root.reveal
      scale: 0.985 + 0.015 * root.reveal
      transformOrigin: Item.Top
      Behavior on scale {
        NumberAnimation { duration: Style.duration(140); easing.type: Easing.OutCubic }
      }

      MouseArea { anchors.fill: parent; onClicked: {} }

      FocusScope {
        id: keyScope
        anchors.fill: parent
        anchors.margins: root.pad
        focus: true

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.query.length > 0) root.query = ""
            else root.close()
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.select(1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageUp) {
            root.select(-6)
            event.accepted = true
          } else if (event.key === Qt.Key_PageDown) {
            root.select(6)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activate(root.cursorActive ? root.selectedIndex : 0)
            event.accepted = true
          }
        }

        // ---------------------------------------------------------- masthead
        Item {
          id: header
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: root.headerHeight

          Text {
            id: masthead
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Kestrel"
            font.family: root.displayFamily
            font.pixelSize: Style.font.heading
            font.letterSpacing: 0.4
            color: root.foreground
          }

          Text {
            anchors.left: masthead.right
            anchors.leftMargin: Style.spacing.sm
            anchors.verticalCenter: parent.verticalCenter
            text: "COMMAND PALETTE"
            font.family: root.monoFamily
            font.pixelSize: Math.max(9, Style.font.caption - 2)
            font.letterSpacing: 1.6
            color: root.faint
          }

          // Mode chip: the one place the surface names what the query will do.
          Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Style.space(22)
            width: mode.implicitWidth + Style.spacing.md * 2
            radius: 3
            color: "transparent"
            border.width: 1
            border.color: root.ruleStrong

            Text {
              id: mode
              anchors.centerIn: parent
              text: root.groupLabel
              font.family: root.monoFamily
              font.pixelSize: Math.max(9, Style.font.caption - 2)
              font.letterSpacing: 1.4
              color: root.muted
            }
          }
        }

        Rectangle {
          id: topRule
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: header.bottom
          height: 1
          color: root.rule
        }

        // ------------------------------------------------------------ search
        Item {
          id: searchRow
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: topRule.bottom
          height: root.searchHeight

          Item {
            id: searchGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Style.font.iconLarge
            height: width
            opacity: 0.55

            Rectangle {
              x: 1
              y: 1
              width: parent.width * 0.62
              height: width
              radius: width / 2
              color: "transparent"
              border.width: 1.5
              border.color: root.muted
            }

            Rectangle {
              x: parent.width * 0.58
              y: parent.height * 0.62
              width: 1.5
              height: parent.height * 0.34
              rotation: -45
              transformOrigin: Item.TopLeft
              color: root.muted
            }
          }

          TextInput {
            id: searchInput
            anchors.left: searchGlyph.right
            anchors.leftMargin: Style.spacing.md
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: root.foreground
            selectionColor: root.ruleStrong
            selectedTextColor: root.foreground
            font.family: root.uiFamily
            font.pixelSize: Style.font.heading + 4
            font.letterSpacing: 0.1
            clip: true
            focus: true
            text: root.query
            onTextChanged: if (text !== root.query) {
              root.query = text
              root.cursorActive = false
            }
            Keys.onReturnPressed: function(event) {
              root.activate(root.cursorActive ? root.selectedIndex : 0)
              event.accepted = true
            }
            Keys.onEnterPressed: function(event) {
              root.activate(root.cursorActive ? root.selectedIndex : 0)
              event.accepted = true
            }

            Text {
              anchors.fill: parent
              visible: searchInput.text.length === 0
              verticalAlignment: Text.AlignVCenter
              text: "Search apps, actions, =calc, ?web"
              color: root.faint
              font: searchInput.font
            }
          }
        }

        Rectangle {
          id: bottomRule
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: searchRow.bottom
          height: 1
          color: root.rule
        }

        // ------------------------------------------------------------ results
        Item {
          id: groupHeader
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: bottomRule.bottom
          height: root.groupHeight
          visible: root.rows.length > 0

          Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.spacing.xs
            text: root.groupLabel
            font.family: root.monoFamily
            font.pixelSize: Math.max(9, Style.font.caption - 2)
            font.letterSpacing: 1.5
            color: root.faint
          }

          Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.spacing.xs
            text: root.rows.length + (root.rows.length === 1 ? " ENTRY" : " ENTRIES")
            font.family: root.monoFamily
            font.pixelSize: Math.max(9, Style.font.caption - 2)
            font.letterSpacing: 1.2
            color: root.muted
          }
        }

        ListView {
          id: resultList
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: groupHeader.bottom
          height: root.listHeight
          visible: root.rows.length > 0
          clip: true
          interactive: true
          model: root.rows
          boundsBehavior: Flickable.StopAtBounds
          spacing: 1

          delegate: Rectangle {
            id: row
            required property int index
            required property var modelData
            width: ListView.view.width
            height: root.rowHeight
            radius: Math.min(root.radius, Style.space(5))
            color: row.chosen ? root.tint : "transparent"
            border.width: row.chosen ? 1 : 0
            border.color: root.ruleStrong

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: 1
              color: root.rule
              visible: !row.chosen && row.index < root.rows.length - 1
            }

            readonly property bool chosen: index === root.selectedIndex && root.cursorActive

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: {
                root.selectedIndex = row.index
                root.cursorActive = true
              }
              onClicked: root.activate(row.index)
            }

            Rectangle {
              id: rowIcon
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.md
              anchors.verticalCenter: parent.verticalCenter
              width: Style.font.iconLarge + 4
              height: width
              radius: 3
              color: root.tint
              border.width: 1
              border.color: row.chosen ? root.ruleStrong : root.rule

              Text {
                anchors.centerIn: parent
                text: String(row.modelData.name || "?").charAt(0).toUpperCase()
                font.family: root.monoFamily
                font.pixelSize: Math.max(10, Style.font.caption)
                color: root.foreground
                opacity: 0.85
              }
            }

            Column {
              anchors.left: rowIcon.visible ? rowIcon.right : parent.left
              anchors.leftMargin: rowIcon.visible ? Style.spacing.lg : Style.spacing.md
              anchors.right: rowHint.left
              anchors.rightMargin: Style.spacing.md
              anchors.verticalCenter: parent.verticalCenter
              spacing: 2

              Text {
                width: parent.width
                text: row.modelData.name
                elide: Text.ElideRight
                font.family: root.uiFamily
                font.pixelSize: Style.font.title
                color: root.foreground
              }

              Text {
                width: parent.width
                visible: row.modelData.subtext.length > 0
                text: row.modelData.subtext
                elide: Text.ElideRight
                font.family: root.monoFamily
                font.pixelSize: Math.max(9, Style.font.caption - 1)
                font.letterSpacing: 0.4
                color: root.muted
              }
            }

            Text {
              id: rowHint
              anchors.right: parent.right
              anchors.rightMargin: Style.spacing.md
              anchors.verticalCenter: parent.verticalCenter
              text: row.chosen ? "ENTER" : (row.modelData.hint || "")
              font.family: root.monoFamily
              font.pixelSize: Math.max(9, Style.font.caption - 2)
              font.letterSpacing: 1.3
              color: row.chosen ? Commons.Color.launcher.selectedText : root.muted
            }
          }
        }

        // ------------------------------------------------------------- chips
        Item {
          id: chips
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: resultList.visible ? resultList.bottom : bottomRule.bottom
          height: root.chipsHeight
          visible: root.chipsHeight > 0

          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.sm

            Repeater {
              model: [
                { label: "calc  12*3", fill: "=12*3" },
                { label: "actions  lock", fill: "/lock" },
                { label: "web  wayland", fill: "? wayland" }
              ]

              delegate: Rectangle {
                required property var modelData
                height: Style.space(24)
                width: chipText.implicitWidth + Style.spacing.md * 2
                radius: 3
                color: root.tint
                border.width: 1
                border.color: root.rule

                Text {
                  id: chipText
                  anchors.centerIn: parent
                  text: modelData.label
                  font.family: root.monoFamily
                  font.pixelSize: Math.max(9, Style.font.caption - 2)
                  font.letterSpacing: 0.8
                  color: root.foreground
                  opacity: 0.72
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.query = modelData.fill
                    searchInput.forceActiveFocus()
                  }
                }
              }
            }
          }
        }

        // ------------------------------------------------------------ footer
        Rectangle {
          id: footRule
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: footer.top
          height: 1
          color: root.rule
        }

        Item {
          id: footer
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: root.footerHeight

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.rows.length === 0 && root.query.length > 0 ? "NO MATCHES" : "KESTREL"
            font.family: root.monoFamily
            font.pixelSize: Math.max(9, Style.font.caption - 2)
            font.letterSpacing: 1.4
            color: root.muted
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.md

            Repeater {
              model: [
                { key: "UP/DN", label: "MOVE" },
                { key: "ENTER", label: "OPEN" },
                { key: "ESC", label: "CLOSE" }
              ]

              delegate: Row {
                required property var modelData
                spacing: Style.spacing.xs

                Rectangle {
                  height: Style.space(20)
                  width: keyLabel.implicitWidth + Style.spacing.sm * 2
                  radius: 3
                  color: root.tint
                  border.width: 1
                  border.color: root.rule

                  Text {
                    id: keyLabel
                    anchors.centerIn: parent
                    text: modelData.key
                    font.family: root.monoFamily
                    font.pixelSize: Math.max(9, Style.font.caption - 2)
                    color: root.muted
                  }
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.label
                  font.family: root.monoFamily
                  font.pixelSize: Math.max(9, Style.font.caption - 2)
                  font.letterSpacing: 1.1
                  color: root.muted
                }
              }
            }
          }
        }
      }
    }
  }
}
