pragma Singleton
import QtQuick
// Adapter: the live audio spectrum for the liquid wave. Silent until the audio
// service exposes levels, so the bar lies flat rather than guessing.
QtObject {
  readonly property var levels: []
  function setActive(v) {}
}
