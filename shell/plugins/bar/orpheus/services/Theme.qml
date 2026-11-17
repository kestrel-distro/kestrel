pragma Singleton
import QtQuick
import qs.Commons
QtObject {
  readonly property color paper: Color.background
  readonly property color ink: Color.foreground
  readonly property color inkDim: Tokens.inkDim
  readonly property color inkMuted: Tokens.inkMuted
  readonly property color accent: Color.accent
  readonly property color alert: Color.urgent
  readonly property color line: Tokens.line
  readonly property bool light: Tokens.light
  function joinArtists(v) { return Array.isArray(v) ? v.join(", ") : String(v || "") }
}
