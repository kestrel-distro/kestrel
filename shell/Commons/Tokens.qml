pragma Singleton
import QtQuick
import qs.Commons

// Ryoku's design vocabulary, resolved from Kestrel's own theme files.
//
// Ryoku.Ui (vendored under shell/Ryoku/Ui) defines this language for its kit:
// paper and a four-tier ink ramp, inversion instead of colour, hairlines
// instead of shadows, and an accent reserved for the frame. Kestrel's surfaces
// already resolve their palette in Commons.Color and their geometry in
// Commons.Style, so this singleton is the bridge: it adds the names the design
// language speaks without re-reading any file or duplicating the palette.
//
// Read Tokens, not raw hex: `Tokens.ink` and `Tokens.line` follow the theme, so
// a light theme (Titan Light, Catppuccin Latte, White) inverts with the paper
// instead of painting white text on white.
QtObject {
  id: root

  // ---------------------------------------------------------------- paper
  readonly property color paper: Color.background
  // A surface lifted off the sheet (a card inside the page). Derived rather
  // than themed: colors.toml has no per-theme lift, and a lift that does not
  // follow the paper is exactly what breaks light themes.
  readonly property color paperLift: Qt.lighter(Color.background, 1.16)
  readonly property bool light: (0.299 * paper.r + 0.587 * paper.g + 0.114 * paper.b) > 0.5

  // ------------------------------------------------------------------ ink
  // Four tiers, all above the 4.5:1 legibility floor on the resolved paper.
  // The ramps are alphas of the theme's own foreground, so they keep their
  // contrast when a theme swaps paper and ink.
  readonly property color ink: Color.foreground
  readonly property color inkDim: Util.alpha(Color.foreground, 0.82)
  readonly property color inkMuted: Util.alpha(Color.foreground, 0.66)
  readonly property color inkFaint: Util.alpha(Color.foreground, 0.48)

  // ------------------------------------------------------- bone (inverted)
  // The emphasis pair: a surface flips to bone with paper ink. It is the only
  // "second value" the language allows.
  readonly property color bone: Color.foreground
  readonly property color inkOnBone: Color.background
  readonly property color inkOnBoneDim: Util.alpha(Color.background, 0.62)

  // ------------------------------------------------------------ hairlines
  readonly property color line: Util.alpha(Color.foreground, 0.26)
  readonly property color lineSoft: Util.alpha(Color.foreground, 0.13)
  readonly property color lineStrong: Util.alpha(Color.foreground, 0.42)
  readonly property int hairline: 1

  // ---------------------------------------------------------------- tints
  readonly property color tint5: Util.alpha(Color.foreground, 0.05)
  readonly property color tint10: Util.alpha(Color.foreground, 0.10)
  readonly property color tint16: Util.alpha(Color.foreground, 0.16)

  // --------------------------------------------------------------- accent
  // sun is the theme accent (frame only). alert stays the urgent red so a
  // badge always reads as an alert even on a monochrome theme.
  readonly property color sun: Color.accent
  readonly property color alert: Color.urgent

  // ------------------------------------------------------------- geometry
  readonly property int radius: Style.cornerRadius
  readonly property int gap: Style.gapsOut
  readonly property int padding: Style.spacing.panelPadding

  // ------------------------------------------------------------- typography
  readonly property string displayFamily: Style.font.displayFamily
  readonly property string uiFamily: Style.font.family
  readonly property string monoFamily: Style.font.monoFamily
  readonly property string jpFamily: Style.font.jpFamily

  // ---------------------------------------------------------------- motion
  readonly property bool reduceMotion: Style.reduceMotion
  function dur(ms) { return Style.duration(ms) }
  readonly property int snap: dur(90)
  readonly property int move: dur(170)
  readonly property int swap: dur(210)
  readonly property int flap: dur(110)
}
