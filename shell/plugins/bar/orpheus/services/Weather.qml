pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Adapter: wttr.in j1, the same source the weather panel renders, mapped to the
// shape the Orpheus cards read. One fetch on start and every 30 minutes; a
// failed fetch keeps the last payload so the bar never blanks.
QtObject {
  id: root

  property var j1: null
  property string errorText: ""
  property string unit: ""            // "" follows the product setting
  property double updatedAt: 0

  readonly property bool available: j1 !== null && current !== null
  readonly property string city: {
    var area = j1 && j1.nearest_area && j1.nearest_area.length > 0 ? j1.nearest_area[0] : null
    return area ? String(area.areaName && area.areaName[0] ? area.areaName[0].value : "") : ""
  }
  readonly property string location: city
  readonly property string condition: {
    var c = j1 && j1.current_condition && j1.current_condition.length > 0 ? j1.current_condition[0] : null
    return c && c.weatherDesc && c.weatherDesc[0] ? String(c.weatherDesc[0].value || "") : ""
  }
  readonly property bool isDay: {
    var c = j1 && j1.current_condition && j1.current_condition.length > 0 ? j1.current_condition[0] : null
    return c ? Number(c.isday === "Yes") : true
  }
  readonly property string code: {
    var c = j1 && j1.current_condition && j1.current_condition.length > 0 ? j1.current_condition[0] : null
    return c ? String(c.weatherCode || "") : ""
  }
  readonly property string glyph: code
  readonly property string status: available ? "live" : (errorText.length > 0 ? "error" : "loading")
  readonly property var moon: null
  readonly property var air: null

  function pickTemp(celsius, fahrenheit) {
    var wantF = unit === "fahrenheit"
    var v = wantF ? fahrenheit : celsius
    return Number(v || 0)
  }

  readonly property var current: {
    var c = j1 && j1.current_condition && j1.current_condition.length > 0 ? j1.current_condition[0] : null
    if (!c) return null
    return {
      temperature: pickTemp(c.temp_C, c.temp_F),
      temp: pickTemp(c.temp_C, c.temp_F),
      feelsLike: pickTemp(c.FeelsLikeC, c.FeelsLikeF),
      humidity: Number(c.humidity || 0),
      wind: Number(c.windspeedKmph || 0),
      windValue: Number(c.windspeedKmph || 0),
      windUnits: "km/h",
      windDir: String(c.winddir16Point || ""),
      condition: condition,
      code: code,
      icon: code,
      isDay: isDay
    }
  }

  readonly property var hourly: {
    if (!j1 || !j1.weather || j1.weather.length === 0) return []
    var out = []
    var today = j1.weather[0]
    var hours = today.hourly || []
    for (var i = 0; i < hours.length; i++) {
      var h = hours[i]
      out.push({
        time: String(Number(h.time || 0) / 100) + ":00",
        hour: String(Number(h.time || 0) / 100),
        temperature: pickTemp(h.tempC, h.tempF),
        temp: pickTemp(h.tempC, h.tempF),
        chance: Number(h.chanceofrain || 0),
        condition: h.weatherDesc && h.weatherDesc[0] ? String(h.weatherDesc[0].value || "") : "",
        icon: String(h.weatherCode || "")
      })
    }
    return out
  }

  readonly property var daily: {
    if (!j1 || !j1.weather) return []
    var out = []
    for (var i = 0; i < j1.weather.length; i++) {
      var d = j1.weather[i]
      out.push({
        date: String(d.date || ""),
        high: pickTemp(d.maxtempC, d.maxtempF),
        low: pickTemp(d.mintempC, d.mintempF),
        hi: pickTemp(d.maxtempC, d.maxtempF),
        lo: pickTemp(d.mintempC, d.mintempF),
        condition: d.hourly && d.hourly[4] && d.hourly[4].weatherDesc && d.hourly[4].weatherDesc[0]
          ? String(d.hourly[4].weatherDesc[0].value || "") : "",
        icon: d.hourly && d.hourly[4] ? String(d.hourly[4].weatherCode || "") : ""
      })
    }
    return out
  }

  function setUnit(value) { root.unit = String(value || "") }
  function retry() { if (!fetch.running) fetch.running = true }

  Process {
    id: fetch
    command: ["sh", "-c", "curl -fsS --max-time 20 'https://wttr.in/?format=j1'"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text() || "null")
          if (parsed && parsed.current_condition) {
            root.j1 = parsed
            root.errorText = ""
            root.updatedAt = Date.now()
          } else {
            root.errorText = "unexpected weather response"
          }
        } catch (e) {
          root.errorText = "weather unavailable"
        }
      }
    }
  }

  Timer { interval: 1800000; running: true; repeat: true; onTriggered: root.retry() }
  Component.onCompleted: fetch.running = true
}
