pragma Singleton
import QtQuick

// Adapter: notification list hooks used by the product. Kestrel owns the
// notification server and its history; the product shows no list today, so the
// adapter stays empty rather than duplicating state.
QtObject {
  readonly property var list: []
  function dismiss(item) {}
}
