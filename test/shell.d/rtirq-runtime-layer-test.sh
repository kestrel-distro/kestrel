#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

migration="$ROOT/migrations/1792300000.sh"
test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

# Stub the root-facing commands: `sudo` drops through to the real tool (which
# then resolves to the stub of the same name earlier in PATH), everything else
# is a no-op so the migration's file edits are what the test observes.
stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin"
cat >"$stub_bin/sudo" <<'EOF'
#!/bin/sh
exec "$@"
EOF
chmod +x "$stub_bin/sudo"
for cmd in pacman systemctl limine-mkinitcpio kestrel-state; do
  printf '#!/bin/sh\nexit 0\n' >"$stub_bin/$cmd"
  chmod +x "$stub_bin/$cmd"
done

defaults_conf="$test_tmp/kestrel-defaults.conf"
rtirq_conf="$test_tmp/rtirq.conf"
marker="$test_tmp/marker"
cmdline="$test_tmp/cmdline"

# The pre-migration state: the old command line carries initramfs_async only.
printf '%s\n' 'KERNEL_CMDLINE[default]+=" initramfs_async=0"' >"$defaults_conf"
printf '%s\n' 'quiet splash' >"$cmdline"

run_migration() {
  PATH="$stub_bin:$PATH" \
    HOME="$test_tmp/home" \
    KESTREL_PATH="$ROOT" \
    KESTREL_LIMINE_DEFAULTS_CONF="$defaults_conf" \
    KESTREL_RTIRQ_CONF="$rtirq_conf" \
    KESTREL_RTIRQ_REBUILD_MARKER="$marker" \
    KESTREL_RUNNING_CMDLINE="$cmdline" \
    bash -euo pipefail "$migration" >/dev/null
}

run_migration
run_migration

grep -Fq 'threadirqs rcu_nocbs=all nowatchdog nmi_watchdog=0' "$defaults_conf" ||
  fail "the migration appends the IRQ and timer parameters"
[[ $(grep -c 'threadirqs' "$defaults_conf") == 1 ]] ||
  fail "the migration appends the parameters only once across two runs"
pass "the migration appends the kernel command line parameters idempotently"

[[ -f $rtirq_conf ]] || fail "the migration deploys /etc/rtirq.conf"
grep -qw amdgpu "$rtirq_conf" || fail "the deployed rtirq.conf covers the GPU IRQ threads"
grep -qw nvidia "$rtirq_conf" || fail "the deployed rtirq.conf covers the NVIDIA IRQ threads"
pass "the migration deploys the Kestrel rtirq configuration"

[[ -e $marker ]] || fail "the migration records the boot-image rebuild marker"
pass "the migration records that the boot image was rebuilt"
