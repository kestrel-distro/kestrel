#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const read = (f) => fs.readFileSync(path.join(root, f), 'utf8')
const exists = (f) => fs.existsSync(path.join(root, f))
const base = 'shell/plugins/bar/orpheus'

// The Orpheus product is vendored intact: scene, body, modules, kit and the
// shared components its barkit re-exports.
for (const f of ['Scene.qml', 'components/Body.qml', 'components/CardHost.qml',
                 'kit/Style.qml', 'barkit/qmldir', 'modules/Workspaces.qml']) {
  assert(exists(`${base}/${f}`), `Orpheus ships ${f}`)
}

// Its two Ryoku module imports are rewritten onto the vendored/service
// directories, so nothing still reaches for a shell that is not Kestrel's.
let stale = []
for (const dir of [base]) {
  const walk = (d) => fs.readdirSync(path.join(root, d), { withFileTypes: true }).forEach((e) => {
    const p = `${d}/${e.name}`
    if (e.isDirectory()) return walk(p)
    if (!e.name.endsWith('.qml')) return
    const text = read(p)
    if (/import shell\.services|import shell\.barkit/.test(text)) stale.push(p)
  })
  walk(dir)
}
assert(stale.length === 0, 'no Orpheus file imports Ryoku shell services/barkit', stale.join('\n'))

// The adapter module supplies the singletons the scene binds to.
const qmldir = read(`${base}/services/qmldir`)
for (const name of ['Weather', 'Media', 'Battery', 'Audio', 'AudioBars', 'Music',
                    'Devices', 'Tray', 'Updates', 'Bluetooth', 'Config', 'Holidays',
                    'Workspaces', 'Vpn', 'Sysmon', 'Power', 'Notifications',
                    'Motion', 'Theme', 'Icons']) {
  assert(new RegExp(`^singleton ${name} ${name}\\.qml$`, 'm').test(qmldir),
    `adapter module provides ${name}`)
}
// Adapters resolve the live palette, not Ryoku's colour files.
assert(/import qs\.Commons/.test(read(`${base}/services/Theme.qml`)), 'the Theme adapter reads qs.Commons')
assert(/Tokens\.inkDim/.test(read(`${base}/services/Theme.qml`)), 'the Theme adapter uses the design tokens')

// The Stage framing dependency is replaced by a local shim, and the phone
// page (which needed Ryoku's phone module) is dropped with its registry entry.
assert(exists(`${base}/stageframe/qmldir`), 'the stage framing shim ships')
assert(/function framing\(screenName\) \{ return false \}/.test(read(`${base}/stageframe/StageFrame.qml`)),
  'the shim never frames a monitor')
assert(!exists(`${base}/modules/Phone.qml`), 'the phone page is dropped')
assert(!/"phone"/.test(read(`${base}/modules/Registry.js`)), 'no registry entry loads a missing phone page')

// The bar-style host: Orpheus is opt-in and the shipped bar stays default.
const config = JSON.parse(read('config/kestrel/shell.json'))
assertEqual(config.barStyle, 'kestrel', 'the shipped bar style is the Kestrel bar')
const shellQml = read('shell/shell.qml')
assert(/shellConfig\.barStyle === "orpheus" \? "orpheus" : "kestrel"/.test(shellQml),
  'an unknown bar style falls back to the Kestrel bar')

// Settings persistence no longer needs Ryoku's daemon: Prefs patches the
// product's own file, and Config reads it.
const prefs = read(`${base}/settings/Prefs.qml`)
assert(!/ryoku-shell\.sock/.test(prefs), 'Orpheus settings no longer open the Ryoku socket')
assert(/jq --indent 2 --argjson v/.test(prefs), 'settings persist through jq into the product file')
assert(/Config\.path/.test(prefs), 'the writer targets the adapter path')
const configAdapter = read(`${base}/services/Config.qml`)
assert(/kestrel\/orpheus\.json/.test(configAdapter), 'the adapter owns ~/.config/kestrel/orpheus.json')
assert(/property var orpheus/.test(configAdapter) && /FileView/.test(configAdapter), 'the adapter loads the product file')

// Real data where Kestrel already has a source: UPower, PipeWire and the
// system tray, the same providers the panels read.
const battery = read(`${base}/services/Battery.qml`)
assert(/import Quickshell\.Services\.UPower/.test(battery), 'Battery reads UPower')
assert(/timeToEmpty/.test(battery) && /timeStr/.test(battery), 'Battery reports a time string')
const audio = read(`${base}/services/Audio.qml`)
assert(/import Quickshell\.Services\.Pipewire/.test(audio), 'Audio reads PipeWire')
assert(/defaultAudioSink/.test(audio) && /preferredDefaultAudioSink/.test(audio), 'Audio exposes and sets the default sink')
const tray = read(`${base}/services/Tray.qml`)
assert(/import Quickshell\.Services\.SystemTray/.test(tray), 'Tray reads the system tray')
assert(/service: it/.test(tray) && /function activate/.test(tray), 'Tray wraps items and activates them')
const weather = read(`${base}/services/Weather.qml`)
assert(/wttr\.in/.test(weather) && /current_condition/.test(weather), 'Weather fetches wttr.in and parses it')
for (const key of ['hourly', 'daily', 'current', 'available', 'city']) {
  assert(new RegExp('property var ' + key + '\\b|property (bool|string) ' + key + '\\b').test(weather) || weather.includes(key + ':'),
    `Weather exposes ${key}`)
}
const updates = read(`${base}/services/Updates.qml`)
assert(/checkupdates/.test(updates) && /property int pending/.test(updates), 'Updates counts pending packages')
const power = read(`${base}/services/Power.qml`)
assert(/PowerProfiles\.profile/.test(power), 'Power reads the active profile')
const devices = read(`${base}/services/Devices.qml`)
assert(/class\/backlight/.test(devices) && /kestrel-brightness-display/.test(devices),
  'Devices reads the backlight and writes through the brightness command')
assert(/source: "plugins\/bar\/orpheus\/Scene\.qml"/.test(shellQml), 'selecting Orpheus mounts its scene')
assert(/active: shell\.barStyle !== "orpheus" && shell\.activeBarId === shell\.defaultBarId/.test(shellQml),
  'the quattro bar is unmounted while Orpheus runs')
JS
