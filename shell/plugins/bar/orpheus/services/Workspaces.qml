pragma Singleton
import QtQuick
import Quickshell.Hyprland
QtObject {
  readonly property var all: Hyprland.workspaces ? Hyprland.workspaces.values : []
}
