pragma Singleton
import QtQuick
// Adapter: the Orpheus product's own settings namespace. Empty until the
// product settings page exists; the keys it reads return their defaults.
QtObject {
  id: root
  property var orpheus: ({})
  readonly property string weatherUnit: "auto"
}
