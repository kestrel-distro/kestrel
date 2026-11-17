pragma Singleton
import QtQuick
import Quickshell.Bluetooth
QtObject {
  readonly property var defaultAdapter: Bluetooth.defaultAdapter
  readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []
}
