#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

export PATH="$ROOT/bin:$PATH"

require_command jq
require_command lua
require_command python3

jq empty "$ROOT/config/kestrel/shell.json"
pass "default shell.json is valid JSON"

jq -e '.version == 1 and (.bar.layout.left | type == "array") and (.bar.layout.center | type == "array") and (.bar.layout.right | type == "array")' "$ROOT/config/kestrel/shell.json" >/dev/null
pass "default shell.json has versioned bar layout"

jq -e '
  (.bar.centerAnchor // "") as $anchor |
  any(.bar.layout.center[]; (.id // .) == $anchor)
' "$ROOT/config/kestrel/shell.json" >/dev/null
pass "default center anchor exists in center layout"

jq -e '
  def ids: map(.id // .);
  (.bar.layout.center | ids) as $ids |
  ($ids | index("kestrel.elsewhen")) as $elsewhen |
  ($ids | index("kestrel.clock")) as $clock |
  $elsewhen != null and $clock == $elsewhen + 1
' "$ROOT/config/kestrel/shell.json" >/dev/null
pass "default center layout puts elsewhen immediately before the clock"

jq -e '
  any(.bar.layout.center[]; (.id // .) == "kestrel.clock" and (.formatAlt // "") == "d MMMM \u0027W\u0027ww yyyy")
' "$ROOT/config/kestrel/shell.json" >/dev/null
pass "default clock date format has no leading zero"

jq -e '
  def ids: map(.id // .);
  (.bar.layout.right | ids) as $ids |
  ($ids | index("kestrel.tray")) as $tray |
  ($ids | index("kestrel.agents")) as $agents |
  $tray != null and $agents == $tray + 1
' "$ROOT/config/kestrel/shell.json" >/dev/null
pass "default right layout keeps agents next to the tray"

ROOT="$ROOT" python3 <<'PY'
import json
import os
import sys
from pathlib import Path

root = Path(os.environ["ROOT"])
config = json.loads((root / "config/kestrel/shell.json").read_text())
manifests = {}
for manifest_path in (root / "shell/plugins").glob("**/*.manifest.json"):
  data = json.loads(manifest_path.read_text())
  manifests[data.get("id", "")] = (manifest_path, data)
for manifest_path in (root / "shell/plugins").glob("**/manifest.json"):
  data = json.loads(manifest_path.read_text())
  manifests[data.get("id", "")] = (manifest_path, data)

entries = []
for section in ("left", "center", "right"):
  entries.extend(config["bar"]["layout"][section])

missing = []
bad = []
for entry in entries:
  widget_id = entry["id"] if isinstance(entry, dict) else str(entry)
  if not widget_id.startswith("kestrel."):
    continue

  row = manifests.get(widget_id)
  if row is None:
    missing.append(widget_id)
    continue
  manifest_path, manifest = row

  if "bar-widget" not in manifest.get("kinds", []):
    bad.append(f"{widget_id}: missing bar-widget kind")
  entry_point = manifest.get("entryPoints", {}).get("barWidget")
  if not entry_point:
    bad.append(f"{widget_id}: missing barWidget entry point")
  elif not (manifest_path.parent / entry_point).exists():
    bad.append(f"{widget_id}: missing {entry_point}")

if missing or bad:
  for item in missing:
    print(f"missing manifest for {item}", file=sys.stderr)
  for item in bad:
    print(item, file=sys.stderr)
  sys.exit(1)
PY
pass "default bar widget ids resolve to manifests and entry points"

ROOT="$ROOT" python3 <<'PY'
import os
import sys
from pathlib import Path

root = Path(os.environ["ROOT"])
home = Path.home()
pkgs_candidates = [
  root.parent / "kestrel-pkgs/pkgbuilds",
  root.parent / "kestrel/kestrel-pkgs/pkgbuilds",
  root.parent.parent / "kestrel-pkgs/pkgbuilds",
  root.parent / "emiliano-go/kestrel-pkgs/pkgbuilds",
  root.parent.parent / "emiliano-go/kestrel-pkgs/pkgbuilds",
  home / "Work/emiliano-go/kestrel-pkgs/pkgbuilds",
]
# Checkouts differ per machine, so allow an explicit pointer at the sibling repo.
# Accepts either the kestrel-pkgs checkout or its pkgbuilds/ directory.
override = os.environ.get("KESTREL_PKGS_PATH")
if override:
  pkgs_candidates = [Path(override) / "pkgbuilds", Path(override)] + pkgs_candidates
pkgs_root = next((path for path in pkgs_candidates if path.exists()), None)
if pkgs_root is None:
  print("not ok - kestrel-pkgs checkout found for PKGBUILD coverage", file=sys.stderr)
  print(
    "looked in:\n  " + "\n  ".join(str(path) for path in pkgs_candidates) +
    "\nset KESTREL_PKGS_PATH to the kestrel-pkgs checkout",
    file=sys.stderr,
  )
  sys.exit(1)
settings_pkgbuild_path = pkgs_root / "kestrel-settings/PKGBUILD"
kestrel_pkgbuild_path = pkgs_root / "kestrel/PKGBUILD"
if not settings_pkgbuild_path.exists():
  settings_pkgbuild_path = pkgs_root / "kestrel-settings-dev/PKGBUILD"
if not kestrel_pkgbuild_path.exists():
  kestrel_pkgbuild_path = pkgs_root / "kestrel-dev/PKGBUILD"
pkgbuild = settings_pkgbuild_path.read_text()
kestrel_pkgbuild = kestrel_pkgbuild_path.read_text()
errors = []
package_defaults = [
  ("default/uwsm/env.d/10-kestrel", "/usr/share/uwsm/env.d/10-kestrel", "uwsm/env"),
  ("default/uwsm/default", None, "uwsm/default"),
  ("default/environment.d/10-kestrel-fcitx.conf", "/usr/lib/environment.d/10-kestrel-fcitx.conf", "environment.d/fcitx.conf"),
  ("default/fontconfig/conf.avail/50-kestrel.conf", "/usr/share/fontconfig/conf.avail/50-kestrel.conf", "fontconfig/fonts.conf"),
  ("default/xdg-terminal-exec/hyprland-xdg-terminals.list", "/usr/share/xdg-terminal-exec/hyprland-xdg-terminals.list", "xdg-terminals.list"),
  ("default/applications/mimeapps.list", "/usr/share/applications/mimeapps.list", "mimeapps.list"),
  ("etc/fastfetch/config.jsonc", "/etc/fastfetch/config.jsonc", "fastfetch/config.jsonc"),
  ("default/systemd/user/bt-agent.service", "/usr/lib/systemd/user/bt-agent.service", "systemd/user/bt-agent.service"),
  ("default/systemd/user/kestrel-sleep-lock.service", "/usr/lib/systemd/user/kestrel-sleep-lock.service", "systemd/user/kestrel-sleep-lock.service"),
  ("default/systemd/user/kestrel-recover-internal-monitor.service", "/usr/lib/systemd/user/kestrel-recover-internal-monitor.service", "systemd/user/kestrel-recover-internal-monitor.service"),
  ("default/systemd/user/kestrel-tailscale-receive.service", "/usr/lib/systemd/user/kestrel-tailscale-receive.service", "systemd/user/kestrel-tailscale-receive.service"),
  ("default/systemd/user/kestrel-fcitx5.service", "/usr/lib/systemd/user/kestrel-fcitx5.service", "systemd/user/kestrel-fcitx5.service"),
  ("default/systemd/user/kestrel-crash-watch.service", "/usr/lib/systemd/user/kestrel-crash-watch.service", "systemd/user/kestrel-crash-watch.service"),
  ("default/systemd/zram-generator.conf.d/90-kestrel.conf", "/usr/lib/systemd/zram-generator.conf.d/90-kestrel.conf", "systemd/zram-generator.conf.d/90-kestrel.conf"),
  ("default/systemd/system/plocate-updatedb.service.d/10-kestrel.conf", "/usr/lib/systemd/system/plocate-updatedb.service.d/10-kestrel.conf", "systemd/system/plocate-updatedb.service.d/10-kestrel.conf"),
  ("default/fonts/kestrel/kestrel.ttf", "/usr/share/fonts/kestrel/kestrel.ttf", "kestrel.ttf"),
  ("default/snapper/root", "/etc/snapper/config-templates/kestrel", "snapper/root"),
]

for source, destination, legacy in package_defaults:
  if not (root / source).exists():
    errors.append(f"missing package default source: {source}")
  if (root / "config" / legacy).exists():
    errors.append(f"legacy path still in config/: {legacy}")
  if destination and (source not in pkgbuild or destination not in pkgbuild):
    errors.append(f"PKGBUILD does not explicitly install {source} -> {destination}")

alpm_hooks = [
  "95-kestrel-snapshot.hook",
  "10-kestrel-hyprland-reload-pause.hook",
  "90-kestrel-hyprland-reload-resume.hook",
]
for hook in alpm_hooks:
  source = f"default/libalpm/hooks/{hook}"
  destination = f"/usr/share/libalpm/hooks/{hook}"
  if not (root / source).exists():
    errors.append(f"missing package default source: {source}")
  if source not in kestrel_pkgbuild or destination not in kestrel_pkgbuild:
    errors.append(f"kestrel PKGBUILD does not install {source} -> {destination}")

if errors:
  print("\n".join(errors), file=sys.stderr)
  sys.exit(1)
PY
pass "package-owned defaults live outside config"

grep -F 'dofile((os.getenv("KESTREL_PATH") or "/usr/share/kestrel") .. "/default/hypr/bootstrap.lua")' "$ROOT/config/hypr/hyprland.lua" >/dev/null
grep -F 'require("default.hypr.kestrel")' "$ROOT/config/hypr/hyprland.lua" >/dev/null
grep -F 'package.path = home' "$ROOT/default/hypr/bootstrap.lua" >/dev/null
grep -F '/.local/state/?.lua;' "$ROOT/default/hypr/bootstrap.lua" >/dev/null
pass "Hyprland user entrypoint keeps package and state path bootstrap in defaults"

KESTREL_PATH="$ROOT" lua <<'LUA'
package.loaded["default.hypr.kestrel"] = true
package.loaded["default.hypr.require_optional"] = true
package.loaded["hypr.looknfeel"] = true
package.loaded["kestrel.current.theme.hyprland"] = true
package.loaded["unrelated.module"] = true

dofile(os.getenv("KESTREL_PATH") .. "/default/hypr/bootstrap.lua")

assert(package.loaded["default.hypr.kestrel"] == nil)
assert(package.loaded["default.hypr.require_optional"] == nil)
assert(package.loaded["hypr.looknfeel"] == nil)
assert(package.loaded["kestrel.current.theme.hyprland"] == nil)
assert(package.loaded["unrelated.module"] == true)
LUA
pass "Hyprland bootstrap reloads cached Kestrel config modules"

TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/home/.config/kestrel"

ipc_mock_bin="$TMPDIR/ipc-mock"
mkdir -p "$ipc_mock_bin"
cat >"$ipc_mock_bin/kestrel-shell" <<'SH'
#!/bin/bash
set -euo pipefail

mkdir -p "$HOME/.local/state/kestrel"
printf '%s\n' "$*" >>"$HOME/.local/state/kestrel/shell-ipc-calls"
printf 'ok\n'
SH
chmod +x "$ipc_mock_bin/kestrel-shell"
export PATH="$ipc_mock_bin:$PATH"

cat >"$TMPDIR/home/.config/kestrel/shell.json" <<'JSON'
{
  "version": 1,
  "bar": {
    "layout": {
      "left": [{ "id": "kestrel.menu" }, { "id": "kestrel.workspaces" }, { "id": "kestrel.active-window" }],
      "center": [{ "id": "kestrel.clock" }, { "id": "kestrel.weather" }, { "id": "kestrel.elsewhen" }, { "id": "kestrel.tailscale" }],
      "right": [{ "id": "kestrel.tray" }, { "id": "kestrel.microphone" }, { "id": "kestrel.bluetooth" }]
    }
  },
  "plugins": []
}
JSON

mkdir -p "$TMPDIR/home/.config/kestrel/plugins/local.demo-bar"
cat >"$TMPDIR/home/.config/kestrel/plugins/local.demo-bar/manifest.json" <<'JSON'
{
  "schemaVersion": 1,
  "id": "local.demo-bar",
  "name": "Demo bar",
  "version": "1.0.0",
  "author": "Test",
  "description": "Replacement bar for config tests",
  "kinds": ["bar"],
  "entryPoints": { "bar": "Bar.qml" }
}
JSON
touch "$TMPDIR/home/.config/kestrel/plugins/local.demo-bar/Bar.qml"

if HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar use local.nonexistent-bar 2>/dev/null; then
  fail "bar use accepted an unknown bar option"
fi
pass "bar use rejects an unknown bar option"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar use local.demo-bar
jq -e '.bar.id == "local.demo-bar"' "$TMPDIR/home/.config/kestrel/shell.json" >/dev/null
pass "shell config selects a bar option"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar reset
jq -e '.bar.id == null' "$TMPDIR/home/.config/kestrel/shell.json" >/dev/null
pass "shell config resets to built-in bar option"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar move kestrel.active-window right
grep -Fqx 'shell moveBarWidget kestrel.active-window {"section":"right"}' \
  "$TMPDIR/home/.local/state/kestrel/shell-ipc-calls"
pass "bar move accepts a positional target section"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar move kestrel.active-window left
grep -Fqx 'shell moveBarWidget kestrel.active-window {"section":"left"}' \
  "$TMPDIR/home/.local/state/kestrel/shell-ipc-calls"
pass "bar move can restore a widget with positional syntax"

if HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar move kestrel.active-window left --section right 2>/dev/null; then
  fail "bar move accepted positional and flagged target sections"
fi
pass "bar move rejects conflicting target section syntax"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar position bottom
jq -e '
  .bar.position == "bottom" and
  .plugins == []
' "$TMPDIR/home/.config/kestrel/shell.json" >/dev/null
pass "shell config sets bar position"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar transparent true
jq -e '
  .bar.transparent == true and
  .bar.position == "bottom" and
  .plugins == []
' "$TMPDIR/home/.config/kestrel/shell.json" >/dev/null
pass "shell config sets bar transparency"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar transparent toggle
jq -e '.bar.transparent == false' "$TMPDIR/home/.config/kestrel/shell.json" >/dev/null
pass "shell config toggles bar transparency"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar set kestrel.bluetooth enabled false --json
grep -Fqx 'shell setBarWidget kestrel.bluetooth enabled false {}' \
  "$TMPDIR/home/.local/state/kestrel/shell-ipc-calls"
pass "bar set accepts false JSON values"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar set kestrel.bluetooth optional null --json
grep -Fqx 'shell setBarWidget kestrel.bluetooth optional null {}' \
  "$TMPDIR/home/.local/state/kestrel/shell-ipc-calls"
pass "bar set accepts null JSON values"

if HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar set kestrel.bluetooth broken '{' --json 2>/dev/null; then
  fail "bar set accepted malformed JSON"
fi
pass "bar set rejects malformed JSON"

if HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" kestrel-bar set kestrel.bluetooth broken 'false null' --json 2>/dev/null; then
  fail "bar set accepted multiple JSON values"
fi
pass "bar set rejects multiple JSON values"

mock_bin="$TMPDIR/mock-bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/kestrel-refresh-config" <<'SH'
#!/bin/bash
set -euo pipefail

relative_path="${1:-}"
[[ -n $relative_path ]] || exit 1
mkdir -p "$HOME/.config/$(dirname "$relative_path")"
cp "$KESTREL_PATH/config/$relative_path" "$HOME/.config/$relative_path"
SH

cat >"$mock_bin/kestrel-restart-shell" <<'SH'
#!/bin/bash
set -euo pipefail

mkdir -p "$HOME/.local/state/kestrel"
touch "$HOME/.local/state/kestrel/restart-shell-called"
SH

cat >"$mock_bin/kestrel-shell" <<'SH'
#!/bin/bash
[[ ${KESTREL_TEST_SHELL_DOWN:-0} == "1" ]] && exit 1
printf 'ok\n'
SH

cat >"$mock_bin/kestrel-installed-service-dropbox" <<'SH'
#!/bin/bash
set -euo pipefail

[[ ${KESTREL_TEST_DROPBOX:-0} == "1" ]]
SH

cat >"$mock_bin/kestrel-installed-service-tailscale" <<'SH'
#!/bin/bash
set -euo pipefail

[[ ${KESTREL_TEST_TAILSCALE:-0} == "1" ]]
SH

chmod +x "$mock_bin"/*
mock_path="$mock_bin:$ROOT/bin:$PATH"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" PATH="$mock_path" KESTREL_TEST_DROPBOX=0 KESTREL_TEST_TAILSCALE=0 kestrel-bar defaults
jq -e --slurpfile defaults "$ROOT/config/kestrel/shell.json" '
  .bar == $defaults[0].bar and
  .plugins == []
' "$TMPDIR/home/.config/kestrel/shell.json" >/dev/null
pass "bar defaults restores the stock bar"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" PATH="$mock_path" KESTREL_TEST_DROPBOX=1 KESTREL_TEST_TAILSCALE=1 kestrel-bar defaults
jq -e '
  def ids: map(.id // .);
  (.bar.layout.right | ids) as $right |
  ($right | index("kestrel.tray")) as $tray |
  ($right | index("kestrel.tailscale") == $tray + 1) and
  ($right | index("kestrel.dropbox") == $tray + 2) and
  (.bar.layout.center | ids | index("kestrel.tailscale") == null)
' "$TMPDIR/home/.config/kestrel/shell.json" >/dev/null
pass "bar defaults places plugins for running optional services"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" PATH="$mock_path" \
  KESTREL_TEST_SHELL_DOWN=1 KESTREL_TEST_DROPBOX=1 KESTREL_TEST_TAILSCALE=1 \
  kestrel-bar defaults
jq -e '
  def ids: map(.id // .);
  (.bar.layout.right | ids) as $right |
  ($right | index("kestrel.tray")) as $tray |
  ($right | index("kestrel.tailscale") == $tray + 1) and
  ($right | index("kestrel.dropbox") == $tray + 2) and
  (.bar.layout.center | ids | index("kestrel.tailscale") == null)
' "$TMPDIR/home/.config/kestrel/shell.json" >/dev/null
pass "bar defaults places service widgets without a running shell"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" PATH="$mock_path" KESTREL_TEST_DROPBOX=0 KESTREL_TEST_TAILSCALE=0 kestrel-refresh-shell
jq -e '
  def ids: map(.id // .);
  ([.bar.layout.left, .bar.layout.center, .bar.layout.right] | map(ids) | add) as $all |
  ($all | index("kestrel.dropbox") == null) and
  ($all | index("kestrel.tailscale") == null)
' "$TMPDIR/home/.config/kestrel/shell.json" >/dev/null
pass "shell refresh keeps optional service widgets absent when services are unavailable"

HOME="$TMPDIR/home" KESTREL_PATH="$ROOT" PATH="$mock_path" KESTREL_TEST_DROPBOX=1 KESTREL_TEST_TAILSCALE=1 kestrel-refresh-shell
jq -e '
  def ids: map(.id // .);
  (.bar.layout.right | ids) as $right |
  ($right | index("kestrel.tray")) as $tray |
  ($right | index("kestrel.tailscale") == $tray + 1) and
  ($right | index("kestrel.dropbox") == $tray + 2) and
  (.bar.layout.center | ids | index("kestrel.tailscale") == null)
' "$TMPDIR/home/.config/kestrel/shell.json" >/dev/null
[[ -f $TMPDIR/home/.local/state/kestrel/restart-shell-called ]] || fail "shell refresh restarts shell"
pass "shell refresh places optional service widgets when services are available"

