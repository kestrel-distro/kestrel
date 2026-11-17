pragma Singleton
import QtQuick

// Adapter: the live audio spectrum behind the liquid wave. Kestrel has no
// spectrum provider (the visualiser is a separate surface), so the levels stay
// empty and the bar's edge lies flat and still rather than inventing motion.
QtObject {
  readonly property var levels: []
  function setActive(active) {}
}
