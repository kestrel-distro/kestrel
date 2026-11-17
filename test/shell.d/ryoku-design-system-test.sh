#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const join = (...p) => path.join(root, ...p)
const read = (...p) => fs.readFileSync(join(...p), 'utf8')

// The vendored design system is the shell's second import root: Quickshell
// resolves `Ryoku.Ui` from <config>/Ryoku/Ui, the same layout Ryoku installs.
const qmldir = read('shell/Ryoku/Ui/qmldir')
assert(/^module Ryoku\.Ui$/m.test(qmldir), 'Ryoku.Ui module ships in the shell import root')
const singletons = read('shell/Ryoku/Ui/Singletons/qmldir')
assert(/^singleton Tokens Tokens\.qml$/m.test(singletons), 'Ryoku.Ui.Singletons declares Tokens')

// The token vocabulary is the design contract: paper/ink/bone/line/sun and a
// light-mode flag every surface can ask about.
const tokens = read('shell/Ryoku/Ui/Singletons/Tokens.qml')
for (const token of ['paper', 'paperLift', 'ink', 'inkDim', 'bone', 'inkOnBone',
                     'line', 'tint5', 'sun', 'alert', 'light', 'radius',
                     'rowH', 'motionScale', 'reduceMotion']) {
  assert(new RegExp(`property (color|int|real|bool|string) ${token}\\b`).test(tokens),
    `Tokens exposes ${token}`)
}
assert(/function role\(/.test(tokens) && /namedScheme/.test(tokens) && /matchWallpaper/.test(tokens),
  'Tokens resolves a named scheme, then the live wallpaper palette, then the default')

// The qs.Commons bridge gives every surface the design vocabulary without a
// second palette: Tokens derives paper/ink/bone/line/tint from Color and Style.
const commons = read('shell/Commons/qmldir')
assert(/^singleton Tokens 1\.0 Tokens\.qml$/m.test(commons), 'qs.Commons registers Tokens')
const bridge = read('shell/Commons/Tokens.qml')
for (const token of ['paper', 'paperLift', 'light', 'ink', 'inkDim', 'inkMuted',
                     'inkFaint', 'bone', 'inkOnBone', 'line', 'lineSoft', 'tint5',
                     'sun', 'alert', 'radius', 'monoFamily', 'reduceMotion']) {
  assert(new RegExp(`property (color|int|real|bool|string) ${token}\\b`).test(bridge),
    `qs.Commons Tokens exposes ${token}`)
}
assert(/readonly property color paper: Color\.background/.test(bridge) &&
  /readonly property color ink: Color\.foreground/.test(bridge),
  'qs.Commons Tokens resolves the palette instead of holding hex')
assert(/0\.299 \* paper\.r/.test(bridge), 'qs.Commons Tokens derives the light flag from the paper')

// Theme fonts: the template documents the keys, Style parses them and exposes
// them with a session-font fallback.
const tpl = read('default/themed/shell.toml.tpl')
for (const key of ['family', 'display-family', 'mono-family', 'jp-family']) {
  assert(new RegExp(`#?\\s*${key}\\s*=`).test(tpl),
    `shell.toml documents [font] ${key}`)
}
const style = read('shell/Commons/Style.qml')
for (const key of ['family', 'display-family', 'mono-family', 'jp-family']) {
  assert(style.includes(`"${key}"`), `Style parses [font] ${key}`)
}
for (const prop of ['displayFamily', 'monoFamily', 'jpFamily']) {
  assert(style.includes(`property string ${prop}:`), `Style.font exposes ${prop}`)
}
assert(/uiFamilyOverride\.length > 0 \? root\.uiFamilyOverride : root\.fontFamily/.test(style),
  'the UI family follows the theme voice, else the session font')
assert(/displayFamilyOverride\.length > 0 \? root\.displayFamilyOverride : root\.fontFamily/.test(style),
  'an unset family falls back to the session font')

// Titan Black and Titan Light are complete themes: palette plus the section
// overrides that give them the paper-and-steel frame, cards and launcher.
for (const theme of ['titan-black', 'titan-light']) {
  const colors = read(`themes/${theme}/colors.toml`)
  for (const key of ['mode', 'accent', 'background', 'foreground', 'red', 'green', 'blue']) {
    assert(new RegExp(`^${key} = `, 'm').test(colors), `${theme} colors.toml defines ${key}`)
  }
  for (const override of ['shell.hyprland.toml', 'shell.popups.toml', 'shell.menu.toml', 'shell.launcher.toml']) {
    const text = read(`themes/${theme}/${override}`)
    assert(/^\[[a-z-]+\]$/m.test(text), `${theme} ships ${override}`)
  }
  const menu = read(`themes/${theme}/shell.menu.toml`)
  for (const key of ['background', 'background-alpha', 'text', 'border', 'border-alpha',
                     'scrim', 'scrim-alpha', 'selected-background', 'selected-text']) {
    assert(new RegExp(`^${key}\\s*=`, 'm').test(menu), `${theme} menu override sets ${key}`)
  }
}
assert(/^mode = "light"$/m.test(read('themes/titan-light/colors.toml')), 'Titan Light is a light theme')
assert(/^mode = "dark"$/m.test(read('themes/titan-black/colors.toml')), 'Titan Black is a dark theme')
JS
