pragma Singleton
import QtQuick
import Quickshell.Services.UPower

// Adapter: UPower through Quickshell, the same source the power panel reads.
// Orpheus wants a percentage and a human time string; the device exposes
// fractions and seconds.
QtObject {
  readonly property var d: UPower.displayDevice
  readonly property bool present: !!(d && d.isPresent)
  readonly property bool charging: present && d.state === UPowerDeviceState.Charging
  readonly property bool discharging: present && UPower.onBattery
  readonly property bool full: present && d.state === UPowerDeviceState.FullyCharged
  readonly property real pct: present ? Math.round(Math.max(0, Math.min(1, d.percentage)) * 100) : 0
  readonly property real health: (present && Number(d.healthPercentage) > 0)
    ? Math.round(Number(d.healthPercentage) * 100) : 0
  readonly property bool healthSupported: present && Number(d.healthPercentage) > 0

  readonly property real _seconds: present
    ? Math.max(Number(d.timeToEmpty) || 0, Number(d.timeToFull) || 0) : 0
  readonly property bool hasTime: present && _seconds > 0
  readonly property string timeStr: {
    if (!hasTime) return ""
    var minutes = Math.round(_seconds / 60)
    var h = Math.floor(minutes / 60)
    var m = minutes % 60
    return h > 0 ? (h + "h " + m + "m") : (m + "m")
  }
}
