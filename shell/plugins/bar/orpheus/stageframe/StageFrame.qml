pragma Singleton
import QtQuick

// Stand-in for Ryoku's Stage Editor framing singleton. Kestrel has no Stage
// Editor, so no monitor is ever framed and every matrix is the identity; the
// Orpheus scene keeps its structure without the editor dependency.
QtObject {
  readonly property matrix4x4 identity: Qt.matrix4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
  function framing(screenName) { return false }
  function matrixFor(screenName, screenWidth, screenHeight, originX, originY) { return identity }
  function mapRect(screenName, screenWidth, screenHeight, originX, originY, rect) { return rect }
}
