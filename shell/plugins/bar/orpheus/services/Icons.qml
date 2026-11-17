pragma Singleton
import QtQuick
import Quickshell
QtObject {
  function path(name) { return Quickshell.iconPath(String(name || ""), true) }
}
