#!/bin/bash

set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command Hyprland

config="$HOME/.config/hypr/hyprland.lua"
[[ -f $config ]] || fail "the shipped Hyprland config exists: $config"

out="$(Hyprland --verify-config -c "$config" 2>&1 || true)"
if grep -q 'config ok' <<<"$out"; then
  pass "the shipped Hyprland config parses on the installed compositor"
else
  printf '%s\n' "$out" >&2
  fail "the shipped Hyprland config parses on the installed compositor"
fi
