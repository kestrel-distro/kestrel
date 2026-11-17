# Ryoku.Blobs (vendored)

The metaball QML module from Ryoku's liquid bar: `BlobGroup`, `BlobRect`,
`BlobWave`, `BlobInvertedRect` and their material. GPL-3.0; see the repo
`NOTICE`.

Only the Orpheus scene types are vendored. The Stage-only modules
(`Ryoku.Spatial3D`, camera/cava feeds, system monitors) were dropped, which is
what lets this build with Qt Quick + ShaderTools alone.

Kestrel ships it prebuilt (the target has no build toolchain). Build host:

    cmake -S ryoku-blobs -B build/ryoku-blobs -DCMAKE_BUILD_TYPE=Release
    cmake --build build/ryoku-blobs
    cmake --install build/ryoku-blobs --prefix "$KESTREL_PATH"

That installs `shell/Ryoku/Blobs/`, which the shell's QML import root already
covers, so `import Ryoku.Blobs` resolves with no environment change.
