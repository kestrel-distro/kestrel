pragma Singleton
import QtQuick
QtObject {
  readonly property bool available: false
  readonly property string city: ""
  readonly property string condition: ""
  readonly property var current: null
  readonly property var hourly: []
  readonly property var daily: []
  readonly property var air: null
  readonly property string errorText: ""
}
