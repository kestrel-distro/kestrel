pragma Singleton
import QtQuick
import Quickshell.Services.UPower

// Adapter: the active power profile, the same enum the power panel sets.
QtObject {
  readonly property string profile: {
    switch (PowerProfiles.profile) {
    case PowerProfile.PowerSaver: return "power-saver"
    case PowerProfile.Performance: return "performance"
    default: return "balanced"
    }
  }
}
