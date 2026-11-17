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

// Inert until the bar-style host mounts it: the running shell must not
// reference the vendored tree yet.
const shellQml = read('shell/shell.qml')
assert(!/plugins\/bar\/orpheus/.test(shellQml), 'the live shell does not mount Orpheus yet')
JS
