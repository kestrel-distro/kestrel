#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const vm = require('vm')
const read = (file) => fs.readFileSync(path.join(root, file), 'utf8')

// The plugin host loads a menu-kind plugin through the same manifest contract
// as the Kestrel menu, so the launcher is a first-party surface, not a side app.
const manifest = JSON.parse(read('shell/plugins/launcher/manifest.json'))
assertEqual(manifest.id, 'kestrel.launcher', 'the launcher registers as kestrel.launcher')
assert(Array.isArray(manifest.kinds) && manifest.kinds.indexOf('menu') !== -1, 'the launcher is a menu-kind plugin')
assert(manifest.keepLoaded === true, 'the launcher stays warm so Super+Space opens instantly')
assertEqual(manifest.entryPoints.menu, 'Launcher.qml', 'the menu entry point is Launcher.qml')
assert(fs.existsSync(path.join(root, 'shell/plugins/launcher/Launcher.qml')), 'the launcher QML ships')

// Routing: the shell accepts a `launcher` shortcut token and dispatches it to
// the plugin, so the chord never spawns a process.
const shellQml = read('shell/shell.qml')
assert(/"menu", "panel", "audio", "brightness", "ipc", "launcher"/.test(shellQml), 'the shell parses a launcher shortcut kind')
assert(/entry\.kind === "launcher"[\s\S]{0,120}shell\.toggle\("kestrel\.launcher"/.test(shellQml), 'the launcher shortcut toggles the plugin in-process')
assert(/^launcher default$/m.test(read('default/kestrel/shortcuts')), 'the shortcuts file exposes a launcher route')
const helpers = read('default/hypr/helpers.lua')
assert(/elseif value\.launcher then[\s\S]{0,160}kestrel\.launcher/.test(helpers), 'a { launcher = ... } bind dispatches to the shell')
assert(/SUPER \+ SPACE", "Launcher", \{ launcher = "default" \}/.test(read('default/hypr/bindings/utilities.lua')), 'Super+Space opens the launcher')

// The surface itself: one fullscreen overlay that owns the keyboard while it
// is open, and exactly one open handler.
const qml = read('shell/plugins/launcher/Launcher.qml')
assert(/OverlayWindow \{/.test(qml), 'the launcher rides the shared overlay window')
assert(/shownKeyboardFocus: WlrKeyboardFocus\.Exclusive/.test(qml), 'the launcher takes the keyboard, so its search field can be typed into')
assertEqual((qml.match(/onOpenedChanged:/g) || []).length, 1, 'one open handler owns both the reset and the focus')
assert(/appLibrary/.test(qml), 'apps come from the shell AppLibrary')
assert(/solidEntries|sortedEntries/.test(qml), 'apps are ranked by the shared app search')

// The query model: prefixes route, arithmetic is parsed (never eval'd), and a
// non-arithmetic string falls through instead of being executed.
const source = read('shell/plugins/launcher/LauncherModel.js').replace(/^\.pragma library\n/, '')
const context = vm.createContext({})
vm.runInContext(source, context, { timeout: 1000 })
const calc = (q) => vm.runInContext('calculate(' + JSON.stringify(q) + ')', context, { timeout: 1000 })
assertEqual(calc('=2+3*4'), '14', 'prefixed arithmetic evaluates')
assertEqual(calc('=(1+2)*3'), '9', 'parentheses group')
assertEqual(calc('10/4'), '2.5', 'fractions survive')
assertEqual(calc('abc'), '', 'a word is not evaluated')
assertEqual(calc('2+'), '', 'a truncated expression is not evaluated')
assertEqual(calc('alert(1)'), '', 'a call is not evaluated')
const actions = vm.runInContext('sortedActions("/")', context, { timeout: 1000 })
assert(Array.isArray(actions) && actions.length > 0, 'the action catalogue is exposed')
assert(actions.every(a => a.id && a.name && a.command), 'every action names an id, a label and a command')
assertEqual(vm.runInContext('webQuery("? wayland")', context), 'wayland', 'the web prefix is stripped')
JS
