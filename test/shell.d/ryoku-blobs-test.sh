#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const read = (f) => fs.readFileSync(path.join(root, f), 'utf8')
const exists = (f) => fs.existsSync(path.join(root, f))

// The liquid bar's metaball module is vendored, GPL-3.0, with attribution.
for (const src of ['blobgroup', 'blobshape', 'blobrect', 'blobwave',
                   'blobinvertedrect', 'blobmaterial']) {
  assert(exists(`ryoku-blobs/src/${src}.cpp`) && exists(`ryoku-blobs/src/${src}.hpp`),
    `Ryoku.Blobs vendors ${src}`)
}
assert(exists('ryoku-blobs/shaders/blob.vert') && exists('ryoku-blobs/shaders/blob.frag'),
  'the blob material shaders ship')
assert(/GPL-3\.0/.test(read('ryoku-blobs/README.md')), 'the vendored module names its license')
assert(/Ryoku/.test(read('NOTICE')), 'the repo NOTICE attributes Ryoku')

// Only the Orpheus types are vendored: the trimmed module must not need
// Quick3D or Multimedia, or it would not build on the package host.
const cmake = read('ryoku-blobs/CMakeLists.txt')
assert(/URI Ryoku\.Blobs/.test(cmake), 'the module registers as Ryoku.Blobs')
assert(/find_package\(Qt6 6\.5 REQUIRED COMPONENTS Quick ShaderTools\)/.test(cmake),
  'the module needs only Qt Quick and ShaderTools')
assert(!/Qt6::(Quick3D|Multimedia)/.test(cmake) && !/DEPENDENCIES/.test(cmake),
  'the Stage-only dependencies stay out')
assert(/qt_add_shaders\(/.test(cmake), 'the shaders are baked at build time')
assert(/DESTINATION shell\/Ryoku/.test(cmake), 'the install lands in the shell import root')

// Prebuilt on the build host, installed beside the shell.
const script = read('packaging/build-ryoku-blobs.sh')
assert(/cmake --install "\$build" --prefix "\$prefix"/.test(script),
  'the packaging helper installs the built module')
assert(/-rwx|executable/.test('' + fs.statSync(path.join(root, 'packaging/build-ryoku-blobs.sh')).mode)
  || (fs.statSync(path.join(root, 'packaging/build-ryoku-blobs.sh')).mode & 0o111) !== 0,
  'the helper is executable')
JS
