pragma Singleton
import QtQuick
import Quickshell.Services.SystemTray

// Adapter: system tray through Quickshell, wrapped in the shape the Orpheus
// product expects ({ service, id, title, tooltip, itemIsMenu, menu }).
// Activation works; the context-menu tree is Ryoku's own model, so `menu`
// stays null and the card falls back to its item list instead of inventing
// entries.
QtObject {
  id: root

  readonly property var items: {
    var raw = SystemTray.items ? SystemTray.items.values : []
    var out = []
    for (var i = 0; i < raw.length; i++) {
      var it = raw[i]
      out.push({
        service: it,
        id: String(it.id || ""),
        title: String(it.title || ""),
        tooltip: it.tooltip || null,
        itemIsMenu: it.onlyMenu === true,
        menu: null
      })
    }
    return out
  }
  readonly property bool aboutToShowValue: false

  function aboutToShow(menu) { return false }
  function menuEvent(menu, id) { return false }
  function send(channel, payload) { return false }
  function activate(service, x, y) {
    if (service && service.activate) service.activate()
  }
}
