#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

packages="$ROOT/install/kestrel-base.packages"
cups_browsed_conf="$ROOT/etc/cups/cups-browsed.conf"
cups_files_conf="$ROOT/etc/cups/cups-files.conf"
sysusers_conf="$ROOT/etc/sysusers.d/kestrel-cups-browsed.conf"
service_dropin="$ROOT/etc/systemd/system/cups-browsed.service.d/10-kestrel.conf"

# Only discovery goes. Everything else printing needs stays, or this stops
# being a removal of one daemon and becomes a removal of printing.
grep -qxF cups "$packages" || fail "CUPS itself remains in the base package set"
grep -qxF cups-filters "$packages" || fail "the CUPS filters remain in the base package set"
grep -qxF system-config-printer "$packages" || fail "Print Settings remains in the base package set"
grep -qxF cups-pk-helper "$packages" || fail "Polkit printer administration is installed"
! grep -qxF cups-pdf "$packages" || fail "the root CUPS-PDF backend is removed"

# Automatic discovery is temporarily out of the default install while it is
# reworked. The hardened configuration below stays as the baseline discovery
# comes back onto.
! grep -qxF cups-browsed "$packages" || fail "automatic printer discovery is out of the base package set"
! grep -q 'cups-browsed' "$ROOT/install/config/enable-services.sh" ||
  fail "a fresh install does not enable a discovery service it no longer installs"
pass "the base install keeps CUPS and Polkit administration, without automatic discovery"

# CUPS still ships /etc/cups/cups-files.conf, so its authorization override is
# applied after the ISO installs that package. cups-browsed is absent, so the
# installer must not write any of its package-owned configuration.
post_install_pacman="$ROOT/install/post-install/pacman.sh"

! grep -q 'cups-cups-browsed.conf' "$post_install_pacman" ||
  fail "a fresh install does not write configuration for absent printer discovery"
grep -q 'cups-cups-files.conf && -f /etc/cups/cups-files.conf' "$post_install_pacman" ||
  fail "the CUPS authorization override waits for the file it replaces"

pass "the fresh install applies CUPS hardening without writing discovery configuration"

grep -qxF 'CacheDir /var/cache/cups-browsed' "$cups_browsed_conf" ||
  fail "cups-browsed keeps state outside the print-filter cache"
grep -qxF 'CreateIPPPrinterQueues Driverless' "$cups_browsed_conf" ||
  fail "automatic queues are limited to driverless IPP printers"
grep -qxF 'CreateRemoteCUPSPrinterQueues No' "$cups_browsed_conf" ||
  fail "remote CUPS queues are not created automatically"
! grep -q 'CreateRemotePrinters' "$cups_browsed_conf" ||
  fail "the unsupported CreateRemotePrinters directive is gone"

pass "cups-browsed uses explicit supported discovery policy and an isolated cache"

grep -qxF 'SystemGroup cups-browsed sys root' "$cups_files_conf" ||
  fail "only the printer discovery account receives passwordless CUPS administration"
grep -qxF 'PeerCred on' "$cups_files_conf" ||
  fail "the packaged CUPS policy enables peer credentials"
[[ $(grep -ciE '^[[:space:]]*SystemGroup[[:space:]]' "$cups_files_conf") == 1 ]] ||
  fail "the packaged CUPS policy has one SystemGroup directive"
[[ $(grep -ciE '^[[:space:]]*PeerCred[[:space:]]' "$cups_files_conf") == 1 ]] ||
  fail "the packaged CUPS policy has one PeerCred directive"
[[ ! -e $ROOT/install/config/printing.sh ]] ||
  fail "printing policy is not rewritten by an install script"
! grep -q 'config/printing.sh' "$ROOT/install/config/all.sh" ||
  fail "install never invokes a printing rewrite script"

pass "CUPS authorization ships as a canonical package override"

grep -qxF 'u cups-browsed - "CUPS printer discovery" / -' "$sysusers_conf" ||
  fail "a locked cups-browsed system account is declared"

for setting in \
  'User=cups-browsed' \
  'Group=cups-browsed' \
  'CacheDirectory=cups-browsed' \
  'CacheDirectoryMode=0750' \
  'UMask=0027' \
  'NoNewPrivileges=yes' \
  'ProtectSystem=strict' \
  'ProtectHome=yes' \
  'PrivateTmp=yes' \
  'RestrictSUIDSGID=yes'; do
  grep -qxF "$setting" "$service_dropin" ||
    fail "cups-browsed service hardening includes $setting"
done

! grep -q '^\(Ambient\|CapabilityBoundingSet\).*CAP_NET_BIND_SERVICE' "$service_dropin" ||
  fail "cups-browsed is not granted an unverified network capability"

pass "cups-browsed runs as its confined service account without added capabilities"

