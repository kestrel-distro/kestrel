import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "LauncherModel.js" as Model

// The command palette: a paper card over the desktop, one search row, ranked
// results and a footer of key hints. Apps come from the shell's own
// AppLibrary, so hidden entries, icons and the launch path match the menu.
// Prefixes route the query: "=" calculates, "?" searches the web, "/" lists
// actions; a bare query searches apps and falls back to actions, then the web.
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

  property color background: Commons.Color.launcher.background
  property color foreground: Commons.Color.launcher.text
  property color border: Commons.Color.launcher.border
  property var borderSpec: Border.surfaceSpec("launcher", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Commons.Color.launcher.scrim
  property color selectedBackground: Commons.Color.launcher.selectedBackground
  property color selectedText: Commons.Color.launcher.selectedText
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property int contentMargin: Style.spacing.panelPadding
  property int rowHeight: Math.max(Style.space(44), Style.font.body + Style.spacing.controlPaddingY * 2)
  property int searchHeight: Math.max(Style.space(52), Style.font.title + Style.spacing.controlPaddingY * 2)
  readonly property int cardWidth: Math.min(Style.space(620), panel.width - Style.gapsOut * 2)
  readonly property int visibleRows: Math.min(root.rows.length, 8)
  readonly property int cardHeight: contentMargin * 2 + searchHeight + (root.rows.length > 0 ? Style.spacing.md + visibleRows * rowHeight + Style.spacing.md : 0) + Style.font.caption + Style.spacing.md

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
        glyph: ""
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
        icon: "",
        glyph: actions[i].glyph,
        command: actions[i].command
      })
    }
    return out
  }

  function calcRow(q) {
    var value = Model.calculate(q)
    if (!value) return null
    return { kind: "calc", id: "calc", name: value, subtext: "Copy result", icon: "", glyph: "\uf1ec", payload: value }
  }

  function webRow(q) {
    var value = Model.webQuery(q)
    if (!value) return null
    return { kind: "web", id: "web", name: value, subtext: "Search the web", icon: "", glyph: "\uf002", payload: value }
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
    Qt.callLater(function() { if (searchField) searchField.forceActiveFocus() })
  }

  OverlayWindow {
    id: panel
    shown: root.opened
    shownKeyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "kestrel-launcher"

    Rectangle {
      anchors.fill: parent
      color: root.scrim
      opacity: root.opened ? 1 : 0
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.opened
      onClicked: root.close()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: Math.min(root.cardHeight, panel.height - Style.gapsOut * 2)
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.max(Style.gapsOut, Math.round((panel.height - height) * 0.22))
      radius: root.cornerRadius
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

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

        Column {
          anchors.fill: parent
          spacing: 0

          Item {
            width: parent.width
            height: root.searchHeight

            Text {
              id: searchGlyph
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "\uf002"
              font.family: "Symbols Nerd Font"
              font.pixelSize: Style.font.icon
              color: Commons.Tokens.inkMuted
            }

            TextField {
              id: searchField
              anchors.left: searchGlyph.right
              anchors.leftMargin: Style.spacing.md
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              placeholderText: "Search apps, actions, =calc, ?web"
              foreground: Commons.Color.launcher.text
              accent: Commons.Color.launcher.selectedText
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              horizontalPadding: 0
              verticalPadding: Style.spacing.sm
              text: root.query
              onTextChanged: if (text !== root.query) {
                root.query = text
                root.cursorActive = false
              }

              Keys.onReturnPressed: function(event) {
                root.activate(root.cursorActive ? root.selectedIndex : 0)
                event.accepted = true
              }
            }
          }

          Rectangle {
            width: parent.width
            height: root.rows.length > 0 ? 1 : 0
            color: Commons.Tokens.lineSoft
          }

          ListView {
            id: resultList
            width: parent.width
            height: root.visibleRows * root.rowHeight
            visible: root.rows.length > 0
            clip: true
            interactive: true
            model: root.rows
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
              id: row
              required property int index
              required property var modelData
              width: ListView.view.width
              height: root.rowHeight
              radius: Math.min(root.cornerRadius, Style.space(4))
              color: index === root.selectedIndex && root.cursorActive ? root.selectedBackground : "transparent"

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                  root.selectedIndex = row.index
                  root.cursorActive = true
                }
                onClicked: root.activate(row.index)
              }

              Item {
                id: rowIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Style.font.iconLarge + Style.spacing.sm
                height: width

                Image {
                  anchors.centerIn: parent
                  width: Style.font.iconLarge
                  height: width
                  source: row.modelData.icon
                  sourceSize.width: width
                  sourceSize.height: height
                  visible: row.modelData.icon.length > 0
                  smooth: true
                }

                Text {
                  anchors.centerIn: parent
                  visible: row.modelData.icon.length === 0
                  text: row.modelData.glyph
                  font.family: "Symbols Nerd Font"
                  font.pixelSize: Style.font.icon
                  color: index === root.selectedIndex && root.cursorActive ? root.selectedText : root.foreground
                  opacity: 0.8
                }
              }

              Column {
                anchors.left: rowIcon.right
                anchors.leftMargin: Style.spacing.sm
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                  width: parent.width
                  text: row.modelData.name
                  elide: Text.ElideRight
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  color: index === root.selectedIndex && root.cursorActive ? root.selectedText : root.foreground
                }

                Text {
                  width: parent.width
                  visible: row.modelData.subtext.length > 0
                  text: row.modelData.subtext
                  elide: Text.ElideRight
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  color: root.foreground
                  opacity: 0.55
                }
              }
            }
          }

          Item {
            width: parent.width
            height: Style.font.caption + Style.spacing.md * 2

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: root.rows.length > 0 ? root.rows.length + " result" + (root.rows.length === 1 ? "" : "s") : "No matches"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: root.foreground
              opacity: 0.5
            }

            Text {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: "↑↓ move · Enter open · Esc close"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: root.foreground
              opacity: 0.4
            }
          }
        }
      }
    }
  }

}
