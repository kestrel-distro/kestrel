#!/bin/bash

set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command kestrel-hint

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  [[ "$(kestrel-hint supported 2>/dev/null || true)" == "yes" ]] ||
    fail "the running kernel supports the Kestrel hint ABI"

  kestrel-hint set self 1 || fail "the hint can be set on a task"
  [[ "$(kestrel-hint get self 2>/dev/null || true)" == "1" ]] ||
    fail "the hint reads back after being set"
  kestrel-hint set self 0 || true

  systemctl --user is-active kestrel-slices.service >/dev/null 2>&1 ||
    fail "kestrel-slices.service is active"
  systemctl --user is-active kestrel-broker.service >/dev/null 2>&1 ||
    fail "kestrel-broker.service is active"

  base="/sys/fs/cgroup/user.slice/user-$(id -u).slice"
  found=0
  for d in "$base"/user@*.service; do
    [[ -d $d/kestrel.slice ]] && { found=1; break; }
  done
  (( found )) || fail "the kestrel.slice hierarchy exists"
else
  skip "bridge validity needs a live Hyprland session"
fi
