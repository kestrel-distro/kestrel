#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

template="$ROOT/default/snapper/root"
limine_defaults="$ROOT/etc/limine-entry-tool.d/kestrel-defaults.conf"
limine_notify_autostart="$ROOT/config/autostart/limine-snapper-notify.desktop"

grep -Fx 'NUMBER_CLEANUP="yes"' "$template" >/dev/null
grep -Fx 'NUMBER_LIMIT="5"' "$template" >/dev/null
grep -Fx 'TIMELINE_CREATE="no"' "$template" >/dev/null
! grep -Eq '^TIMELINE_(CLEANUP|LIMIT_)' "$template" || fail "Snapper template keeps timeline cleanup details out of the default config"
grep -Fx 'MAX_SNAPSHOT_ENTRIES=6' "$limine_defaults" >/dev/null || fail "Limine allows for a snapshot created before Snapper cleanup"
pass "Snapper and Limine retain update snapshots without a transient limit mismatch"

grep -Fx '[Desktop Entry]' "$limine_notify_autostart" >/dev/null
grep -Fx 'Hidden=true' "$limine_notify_autostart" >/dev/null
pass "Limine Snapper warning notifier is disabled by default"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

fake_bin="$test_tmp/bin"
mkdir -p "$fake_bin"

cat >"$fake_bin/snapper" <<'STUB'
#!/bin/bash
printf 'snapper %s\n' "$*" >>"$TEST_LOG"
STUB
chmod +x "$fake_bin/snapper"

cat >"$fake_bin/systemctl" <<'STUB'
#!/bin/bash
printf 'systemctl %s\n' "$*" >>"$TEST_LOG"
STUB
chmod +x "$fake_bin/systemctl"

: >"$test_tmp/calls.log"

TEST_LOG="$test_tmp/calls.log" \
PATH="$fake_bin:$PATH" \
KESTREL_SNAPPER_CONFIGURE_TEST=1 \
KESTREL_PATH="$ROOT" \
KESTREL_SNAPPER_CONFIG_PATH="$test_tmp/etc/snapper/configs/root" \
KESTREL_SNAPPER_CONF_PATH="$test_tmp/etc/conf.d/snapper" \
  bash -euo pipefail "$ROOT/install/config/snapper.sh" >/dev/null

cmp -s "$template" "$test_tmp/etc/snapper/configs/root" || fail "snapshot configure installs the Kestrel Snapper template"
grep -Fx 'SNAPPER_CONFIGS="root"' "$test_tmp/etc/conf.d/snapper" >/dev/null || fail "snapshot configure writes /etc/conf.d/snapper"
grep -Fx 'systemctl disable --now snapper-timeline.timer' "$test_tmp/calls.log" >/dev/null || fail "snapshot configure disables timeline snapshots"
grep -Fx 'systemctl enable --now snapper-cleanup.timer limine-snapper-sync.service' "$test_tmp/calls.log" >/dev/null || fail "snapshot configure enables cleanup and Limine snapshot sync"
pass "snapshot configure normalizes Snapper policy and services"

setup_system="$ROOT/bin/kestrel-apply-system"
grep -F 'config/all.sh' "$setup_system" >/dev/null ||
  fail "system setup runs the config phase"
grep -F 'config/snapper.sh' "$ROOT/install/config/all.sh" >/dev/null ||
  fail "config phase normalizes Snapper"
pass "system setup normalizes Snapper during fresh installs"

# Checkouts differ per machine, so allow an explicit pointer at the sibling repo.
# Accepts either the kestrel-pkgs checkout or its pkgbuilds/ directory.
find_kestrel_pks_root() {
  local candidate
  for candidate in \
    ${KESTREL_PKGS_PATH:+"$KESTREL_PKGS_PATH/pkgbuilds" "$KESTREL_PKGS_PATH"} \
    "$ROOT/../kestrel-pkgs/pkgbuilds" \
    "$ROOT/../kestrel/kestrel-pkgs/pkgbuilds" \
    "$ROOT/../../kestrel-pkgs/pkgbuilds" \
    "$ROOT/../emiliano-go/kestrel-pkgs/pkgbuilds" \
    "$ROOT/../../emiliano-go/kestrel-pkgs/pkgbuilds" \
    "$HOME/Work/emiliano-go/kestrel-pkgs/pkgbuilds"; do
    if [[ -d $candidate ]]; then
      cd "$candidate" && pwd
      return 0
    fi
  done
  return 1
}

pkgs_root=$(find_kestrel_pks_root) || fail "kestrel-pkgs checkout is available for packaging coverage"
settings_pkgbuild="$pkgs_root/kestrel-settings-dev/PKGBUILD"
kestrel_pkgbuild="$pkgs_root/kestrel-dev/PKGBUILD"

grep -F 'cp -a default/. "$pkgdir/usr/share/kestrel/default/"' "$settings_pkgbuild" >/dev/null || fail "kestrel-settings package bundles default/"
grep -F 'install -Dm644 default/snapper/root \' "$settings_pkgbuild" >/dev/null || fail "kestrel-settings package installs Snapper template source"
grep -F '"$pkgdir/etc/snapper/config-templates/kestrel"' "$settings_pkgbuild" >/dev/null || fail "kestrel-settings package installs Snapper template destination"
grep -F "'snapper'" "$kestrel_pkgbuild" >/dev/null || fail "kestrel package depends on snapper"
grep -F "'limine-snapper-sync'" "$kestrel_pkgbuild" >/dev/null || fail "kestrel package depends on limine-snapper-sync"
grep -F 'cp -a install "$pkgdir/usr/share/kestrel/"' "$kestrel_pkgbuild" >/dev/null || fail "kestrel package bundles install scripts"
! grep -F 'cp -a migrations ' "$kestrel_pkgbuild" >/dev/null || fail "kestrel package no longer bundles migrations"
pass "kestrel-pkgs packages Snapper template and setup coverage"

# Same per-machine checkout problem as kestrel-pkgs; KESTREL_ISO_PATH points at it.
find_kestrel_iso_root() {
  local candidate
  for candidate in \
    ${KESTREL_ISO_PATH:+"$KESTREL_ISO_PATH"} \
    "$ROOT/../kestrel-iso" \
    "$ROOT/../kestrel/kestrel-iso" \
    "$ROOT/../../kestrel-iso" \
    "$ROOT/../emiliano-go/kestrel-iso" \
    "$ROOT/../../emiliano-go/kestrel-iso" \
    "$HOME/Work/emiliano-go/kestrel-iso"; do
    if [[ -d $candidate ]]; then
      cd "$candidate" && pwd
      return 0
    fi
  done
  return 1
}

iso_root=$(find_kestrel_iso_root) || fail "kestrel-iso checkout is available for installer coverage"
configurator="$iso_root/configs/airootfs/root/configurator"
phases="$iso_root/configs/airootfs/usr/share/kestrel-iso/orchestrator/phases_impl.py"
manifest="$iso_root/manifests/fresh-4-semantic.json"

! grep -F 'snapshot_config' "$configurator" >/dev/null || fail "ISO does not ask archinstall to create Snapper timeline config"

# The phases/manifest assertions cover the newer ISO orchestrator structure.
# Skip them when the checkout predates that layout.
if [[ -f $phases && -f $manifest ]]; then
  ! grep -F '_configure_snapper_root' "$phases" >/dev/null || fail "ISO does not duplicate Kestrel Snapper setup"
  grep -F 'run_system_finalizer' "$phases" >/dev/null || fail "ISO runs packaged system setup"
  grep -F '/etc/systemd/system/timers.target.wants/snapper-cleanup.timer' "$manifest" >/dev/null || fail "fresh ISO manifest has snapper-cleanup timer enabled"
  ! grep -F '/etc/systemd/system/timers.target.wants/snapper-timeline.timer' "$manifest" >/dev/null || fail "fresh ISO manifest does not enable snapper timeline timer"
fi
pass "kestrel-iso delegates Snapper setup to packaged system setup"
