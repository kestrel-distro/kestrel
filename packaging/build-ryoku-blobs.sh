#!/usr/bin/env bash
# Build the vendored Ryoku.Blobs QML module and install it beside the shell.
#
# Kestrel ships it prebuilt (the installed target has no toolchain), so this
# runs on the package/ISO build host:
#
#   packaging/build-ryoku-blobs.sh [prefix]     # default: /usr/share/kestrel
#
# It installs <prefix>/shell/Ryoku/Blobs/, which the shell's QML import root
# already covers, so `import Ryoku.Blobs` resolves with no env change.
# Requires: cmake, a C++20 compiler and Qt 6.5+ Quick + ShaderTools dev files.
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
prefix="${1:-/usr/share/kestrel}"
build="${BLOBS_BUILD_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/kestrel/ryoku-blobs}"

for tool in cmake; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "build-ryoku-blobs: $tool is required on the build host" >&2
    exit 1
  }
done

cmake -S "$here/ryoku-blobs" -B "$build" -DCMAKE_BUILD_TYPE=Release
cmake --build "$build" --parallel
cmake --install "$build" --prefix "$prefix"

echo "Ryoku.Blobs installed under $prefix/shell/Ryoku/Blobs"
