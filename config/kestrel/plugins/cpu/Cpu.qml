import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "eclipse.cpu"

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button

    anchors.fill: parent
    bar: root.bar
    text: "󰻠"
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "Open btop"
    onPressed: root.bar && root.bar.run("uwsm app -- $TERMINAL -e btop")
  }
}
