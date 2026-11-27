import QtQuick

// Minimal stage layer: with no editor, this is a plain full-size item whose
// `rest` holds the caller's content and whose masks map through unchanged.
Item {
  id: root

  property bool interactive: false
  property string screenName: ""
  property string edge: "top"
  property real restThickness: 0
  property real screenWidth: 0
  property real screenHeight: 0
  readonly property bool framed: false
  readonly property Item rest: restItem
  // The layer's requested thickness, never its own height: the scene binds the
  // window's implicitHeight to this, so deriving it from `height` closes a
  // binding cycle (height -> implicitHeight -> extent -> height) and Qt dies of
  // stack overflow before the bar is ever mapped.
  readonly property real extent: Math.max(1, restThickness)

  function maskRect(rect) { return rect }

  Item {
    id: restItem
    anchors.fill: parent
  }
}
