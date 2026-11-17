pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

// Adapter: the default PipeWire sink/source, the same nodes the audio panel
// drives. Orpheus binds node.audio.volume/muted through `sink`/`source`.
QtObject {
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property bool alive: sink !== null || source !== null
  readonly property var outputs: Pipewire.nodes ? Pipewire.nodes.values.filter(n => n.isSink === true) : []
  readonly property var inputs: Pipewire.nodes ? Pipewire.nodes.values.filter(n => n.isSink === false) : []
  readonly property var captureStreams: []

  function setOutput(node) { if (node) Pipewire.preferredDefaultAudioSink = node }
  function setInput(node) { if (node) Pipewire.preferredDefaultAudioSource = node }
  function nodeIcon(node) { return node ? String(node.properties["application.icon-name"] || "") : "" }
  function nodeLabel(node) {
    if (!node) return ""
    return String(node.properties["application.name"] || node.description || node.name || "")
  }
}
