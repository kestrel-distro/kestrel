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
  readonly property real extent: height

  function maskRect(rect) { return rect }

  Item {
    id: restItem
    anchors.fill: parent
  }
}
