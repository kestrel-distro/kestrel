import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Widgets
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "LauncherModel.js" as Model

// The command palette, in the paper-and-ink language: one sheet of paper on a
// dimmed desktop, a search line ruled off from the results, and a footer of key
// hints set in micro caps. The chosen row is not tinted with colour; it is
// inverted to bone, the language's only emphasis.
//
// Apps come from the shell AppLibrary, so hidden entries, icons and the launch
// path match the menu. Prefixes route the query: "=" calculates, "?" searches
// the web, "/" lists actions; a bare query searches apps and falls back to the
// action catalogue, then the web.
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

  // Surfaces follow the theme's [launcher] section; the ink, rules and the
  // inversion pair come from the shared design tokens.
  property color background: Commons.Color.launcher.background
  property color foreground: Commons.Color.launcher.text
  readonly property color cardBorder: Commons.Tokens.line
  readonly property color muted: Commons.Tokens.inkMuted
  readonly property color faint: Commons.Tokens.inkFaint
  readonly property color rule: Commons.Tokens.lineSoft
  readonly property color chosenFill: Commons.Tokens.bone
  readonly property color chosenInk: Commons.Tokens.inkOnBone
  readonly property color chosenInkDim: Commons.Tokens.inkOnBoneDim
  readonly property string displayFamily: Commons.Tokens.displayFamily
  readonly property string uiFamily: Commons.Tokens.uiFamily
  readonly property string monoFamily: Commons.Tokens.monoFamily
  readonly property int radius: Commons.Tokens.radius

  property int outerMargin: Style.spacing.panelPadding + Style.spacing.sm
  property int rowHeight: Math.max(Style.space(46), Style.font.body + Style.spacing.rowPaddingX * 2)
  property int searchHeight: Math.max(Style.space(56), Style.font.title + Style.spacing.rowPaddingX * 2)
  readonly property int cardWidth: Math.min(Style.space(640), panel.width - outerMargin * 2)
  readonly property int visibleRows: Math.min(root.rows.length, 9)
  readonly property int resultsHeight: root.rows.length > 0 ? visibleRows * rowHeight : 0
  readonly property int cardHeight: outerMargin + searchHeight + 1 + (resultsHeight > 0 ? Style.spacing.sm + resultsHeight : 0) + Style.space(40) + outerMargin

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
        icon: library.iconSource(entry.icon || "")
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
        command: actions[i].command
      })
    }
    return out
  }

  function calcRow(q) {
    var value = Model.calculate(q)
    if (!value) return null
    return { kind: "calc", id: "calc", name: value, subtext: "Copy result", icon: "", payload: value }
  }

  function webRow(q) {
    var value = Model.webQuery(q)
    if (!value) return null
    return { kind: "web", id: "web", name: value, subtext: "Search the web", icon: "", payload: value }
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
      color: Qt.rgba(0, 0, 0, 0.35)
      opacity: root.opened ? 1 : 0
      Behavior on opacity {
        NumberAnimation { duration: Style.duration(120); easing.type: Easing.OutCubic }
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.opened
      onClicked: root.close()
    }

    // The sheet itself: paper, one hairline, a ruled search line. No shadow, no
    // accent border — depth is the rule, not a stroke around the card.
    Rectangle {
      id: card
      width: root.cardWidth
      height: Math.min(root.cardHeight, panel.height - root.outerMargin * 2)
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.max(root.outerMargin, Math.round((panel.height - height) * 0.2))
      radius: root.radius
      color: root.background
      border.width: 1
      border.color: root.cardBorder

      MouseArea { anchors.fill: parent; onClicked: {} }

      FocusScope {
        id: keyScope
        anchors.fill: parent
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

        Item {
          id: searchRow
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.leftMargin: root.outerMargin
          anchors.rightMargin: root.outerMargin
          height: root.searchHeight

          Image {
            id: searchGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Style.font.icon
            height: width
            source: Quickshell.iconPath("edit-find-symbolic", true)
            sourceSize.width: width
            sourceSize.height: height
            opacity: 0.55
          }

          TextInput {
            id: searchInput
            anchors.left: searchGlyph.right
            anchors.leftMargin: Style.spacing.md
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: root.foreground
            selectionColor: root.chosenFill
            selectedTextColor: root.chosenInk
            font.family: root.uiFamily
            font.pixelSize: Style.font.title
            font.letterSpacing: 0.2
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
          id: rule
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: searchRow.bottom
          anchors.leftMargin: root.outerMargin
          anchors.rightMargin: root.outerMargin
          height: 1
          color: root.rule
        }

        ListView {
          id: resultList
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: rule.bottom
          anchors.topMargin: root.rows.length > 0 ? Style.spacing.sm : 0
          anchors.leftMargin: root.outerMargin
          anchors.rightMargin: root.outerMargin
          height: root.resultsHeight
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
            radius: Math.min(root.radius, Style.space(4))
            color: "transparent"

            readonly property bool chosen: index === root.selectedIndex && root.cursorActive

            Rectangle {
              anchors.fill: parent
              radius: parent.radius
              color: row.chosen ? root.chosenFill : "transparent"
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: {
                root.selectedIndex = row.index
                root.cursorActive = true
              }
              onClicked: root.activate(row.index)
            }

            Image {
              id: rowIcon
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.sm
              anchors.verticalCenter: parent.verticalCenter
              width: Style.font.iconLarge
              height: width
              source: row.modelData.icon
              sourceSize.width: width
              sourceSize.height: height
              visible: row.modelData.icon.length > 0
              smooth: true
            }

            Text {
              id: rowName
              anchors.left: rowIcon.visible ? rowIcon.right : parent.left
              anchors.leftMargin: rowIcon.visible ? Style.spacing.md : Style.spacing.sm
              anchors.right: parent.right
              anchors.rightMargin: Style.spacing.sm
              anchors.verticalCenter: parent.verticalCenter
              anchors.verticalCenterOffset: row.modelData.subtext.length > 0 ? -Style.font.caption * 0.45 : 0
              text: row.modelData.name
              elide: Text.ElideRight
              font.family: root.uiFamily
              font.pixelSize: Style.font.title
              color: row.chosen ? root.chosenInk : root.foreground
            }

            Text {
              anchors.left: rowName.left
              anchors.right: rowName.right
              anchors.top: rowName.bottom
              anchors.topMargin: 1
              visible: row.modelData.subtext.length > 0
              text: row.modelData.subtext
              elide: Text.ElideRight
              font.family: root.monoFamily
              font.pixelSize: Math.max(9, Style.font.caption - 1)
              font.letterSpacing: 0.3
              color: row.chosen ? root.chosenInkDim : root.muted
            }
          }
        }

        Item {
          id: footer
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.leftMargin: root.outerMargin
          anchors.rightMargin: root.outerMargin
          height: Style.space(40)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: {
              if (root.rows.length === 0) return root.query.length > 0 ? "NO MATCHES" : "TYPE TO SEARCH"
              return root.rows.length + (root.rows.length === 1 ? " RESULT" : " RESULTS")
            }
            font.family: root.monoFamily
            font.pixelSize: Math.max(9, Style.font.caption - 2)
            font.letterSpacing: 1.3
            color: root.faint
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "↑↓ MOVE   ENTER OPEN   ESC CLOSE"
            font.family: root.monoFamily
            font.pixelSize: Math.max(9, Style.font.caption - 2)
            font.letterSpacing: 1.1
            color: root.faint
          }
        }
      }
    }
  }
}
