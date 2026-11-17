pragma Singleton
import QtQuick
QtObject {
  readonly property var items: []
  readonly property bool aboutToShow: false
  function activate(v) {}
  function menuEvent(v) {}
  function send(v) {}
}
