#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

for list in "$ROOT"/install/*.packages; do
  ! grep -qxF 'yt6801-dkms' "$list" || fail "package list still installs the vendor yt6801 driver: $list"
done
pass "no package list installs the vendor yt6801 driver"

script="$ROOT/install/hardware/fix-yt6801-ethernet-adapter.sh"
if grep -qvE '^[[:space:]]*(#|$)' "$script"; then
  fail "manual yt6801 setup must stay a no-op with the upstream dwmac-motorcomm driver on fresh installs"
fi
pass "manual yt6801 setup stays a no-op"
