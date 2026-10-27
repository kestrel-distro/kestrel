#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

packaged_defaults="$ROOT/etc/limine-entry-tool.d/kestrel-defaults.conf"

grep -Fq 'KERNEL_CMDLINE[default]+=" initramfs_async=0"' "$packaged_defaults" ||
  fail "the packaged Limine defaults still unpack the initramfs synchronously"
pass "packaged Limine defaults keep Plymouth alive at the LUKS prompt"

if grep -qE 'initcall_debug|rcu_nocbs|systemd\.log_level=debug' "$packaged_defaults"; then
  fail "installed Limine defaults carry no bring-up or offload cmdline"
fi
pass "installed Limine defaults carry no bring-up or offload cmdline"

grep -Fxq 'BOOT_ORDER="linux, linux-lts, *, *fallback, Snapshots"' "$packaged_defaults" ||
  fail "packaged Limine defaults prefer the exact Kestrel kernel, then fallbacks and snapshots"
pass "packaged Limine defaults prefer the exact Kestrel kernel, then fallbacks and snapshots"
