pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../Singletons"
import "../../../services" as Svc
import "lib/clock.js" as Clk

/**
 * Banner face: NibrasShell's wide clock, ported directly -- one line reading
 * "hh:mm AP - MM/DD", big and calm, made to pair with depth. A soft adaptive
 * halo (dark behind light ink, light behind dark) keeps the time legible on any
 * wallpaper, even in the moment a new one is still being recoloured.
 */
Item {
    id: face

    property real underL: Scheme.wallLstar
    // a pinned colour ("" = follow wallpaper) paints this face's own ink.
    property string inkColorA: ""
    property real s: 1
    // Kestrel port: the time and date take the theme's own text and accent
    // roles instead of a contrast colour computed on the wallpaper, so the
    // clock is literally part of the palette (c8c8d4 on Titan Black, 23232e on
    // Titan Light). A pinned per-widget colour still wins.
    readonly property bool pinned: face.inkColorA !== ""
    readonly property color ink: face.pinned ? Qt.color(face.inkColorA) : Theme.ink
    readonly property color inkDim: face.pinned ? Qt.color(face.inkColorA) : Theme.inkDim
    readonly property color accent: Clk.pickAccent("", Svc.Config.clockAccentColor && Svc.Config.clockAccentColor.length > 0 ? Svc.Config.clockAccentColor : Theme.accent, Theme.brand, face.ink)

    readonly property var t: Clk.parts(Now.date, Config.clock24h)
    readonly property var dt: Clk.dateParts(Now.date)
    readonly property real px: Math.round(150 * face.s)
    readonly property real track: Math.round(face.px * -0.01)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    width: implicitWidth
    height: implicitHeight

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: face.underL < 50 ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(1, 1, 1, 0.6)
        shadowBlur: 0.7
        shadowVerticalOffset: 0
        shadowHorizontalOffset: 0
    }

    Row {
        id: row
        spacing: Math.round(face.px * 0.16)

        // hh:mm, tight
        Row {
            id: hm
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: face.t.hh
                color: face.ink
                font.family: Theme.font
                font.weight: Font.Bold
                font.pixelSize: face.px
                font.letterSpacing: face.track
            }
            Text {
                text: ":"
                color: face.accent
                font.family: Theme.font
                font.weight: Font.Bold
                font.pixelSize: face.px
                font.letterSpacing: face.track
            }
            Text {
                text: face.t.mm
                color: face.ink
                font.family: Theme.font
                font.weight: Font.Bold
                font.pixelSize: face.px
                font.letterSpacing: face.track
            }
        }

        // AM/PM, small, on the time's baseline (12h only)
        Text {
            visible: !Config.clock24h
            anchors.bottom: hm.bottom
            anchors.bottomMargin: Math.round(face.px * 0.14)
            text: face.t.ampm
            color: face.inkDim
            font.family: Theme.font
            font.weight: Font.DemiBold
            font.pixelSize: Math.round(face.px * 0.24)
            font.letterSpacing: 2
        }

        // separator
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u2013"
            color: face.inkDim
            font.family: Theme.font
            font.weight: Font.Bold
            font.pixelSize: face.px
        }

        // MM/DD
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Clk.pad2(face.dt.mon + 1) + "/" + Clk.pad2(face.dt.dom)
            color: face.ink
            font.family: Theme.font
            font.weight: Font.Bold
            font.pixelSize: face.px
            font.letterSpacing: face.track
        }
    }
}
