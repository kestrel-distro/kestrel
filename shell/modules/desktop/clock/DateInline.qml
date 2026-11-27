pragma ComponentBehavior: Bound
import QtQuick
import "../Singletons"
import "lib/clock.js" as Clk
import "../../../services" as Svc

// inline date: one quiet caption. weekday in accent, then month + day in soft
// ink, split by a dot. default companion to the time, reads as one line, never
// competes with the clock above.
Item {
    id: date

    // the widget floats on the wallpaper, so its ink is picked against the patch
    // of picture under it. WidgetSlot measures it and pushes it in.
    property real underL: Scheme.wallLstar
    // a pinned colour ("" = follow wallpaper) paints this strip's own ink.
    property string inkColorA: ""
    property real s: 1
    // Kestrel port: palette roles, not a contrast colour computed on the
    // wallpaper; a pinned per-widget colour still wins.
    readonly property bool pinned: date.inkColorA !== ""
    readonly property color ink:     date.pinned ? Qt.color(date.inkColorA) : Theme.ink
    readonly property color inkDim:  date.pinned ? Qt.color(date.inkColorA) : Theme.inkDim
    readonly property color inkSoft: date.pinned ? Qt.color(date.inkColorA) : Theme.inkDim

    readonly property var dp: Clk.dateParts(Now.date, Svc.Config.formatLoc)
    readonly property color accent: Clk.pickAccent(Config.clockAccent, (Scheme.surfaceLstar > 50 ? "#864647" : Theme.accent), Theme.brand, date.ink)
    readonly property real px: Math.round(22 * date.s)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: Math.round(8 * date.s)

        Text {
            text: date.dp.weekday
            color: date.accent
            font.family: Theme.font
            font.pixelSize: date.px
            font.weight: Font.DemiBold
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u00b7"
            color: date.inkDim
            font.family: Theme.font
            font.pixelSize: date.px
            font.weight: Font.Bold
        }
        Text {
            text: date.dp.month + " " + date.dp.dom
            color: date.inkSoft
            font.family: Theme.font
            font.pixelSize: date.px
            font.weight: Font.Medium
        }
    }
}
