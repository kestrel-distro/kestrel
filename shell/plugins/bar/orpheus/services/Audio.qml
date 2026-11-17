pragma Singleton
import QtQuick
QtObject {
  readonly property bool alive: false
  readonly property var outputs: []
  readonly property var inputs: []
  readonly property var captureStreams: []
  function setOutput(v) {}
  function setInput(v) {}
  function nodeIcon(n) { return "" }
  function nodeLabel(n) { return "" }
}
