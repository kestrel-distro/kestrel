pragma Singleton
import QtQuick
import qs.Commons
QtObject {
  readonly property bool reduce: Style.reduceMotion
  readonly property int open: Style.duration(170)
  readonly property int morph: Style.duration(210)
  readonly property var easeMorph: Easing.OutCubic
  readonly property var morphCurve: [0.2, 0, 0, 1, 1, 1]
}
