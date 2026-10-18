echo "Enable IRQ thread and timer latency tuning"

# Kernel plan C2.3: `threadirqs` turns device IRQ handlers into threads so rtirq
# can raise the priority of the audio, input and GPU ones; `rcu_nocbs=all`
# moves RCU callbacks off the housekeeping CPUs; the watchdog knobs drop the
# periodic NMI/lockup timers. The packaged etc/ files and enable-services.sh
# carry this for fresh installs; this brings an existing install to the same
# state. Every step is idempotent.

defaults_conf="${KESTREL_LIMINE_DEFAULTS_CONF:-/etc/limine-entry-tool.d/kestrel-defaults.conf}"
rtirq_conf="${KESTREL_RTIRQ_CONF:-/etc/rtirq.conf}"
running_cmdline="${KESTREL_RUNNING_CMDLINE:-/proc/cmdline}"
rebuild_marker="${KESTREL_RTIRQ_REBUILD_MARKER:-/var/lib/kestrel/migrations/1792300000}"
payload="${KESTREL_PATH:-/usr/share/kestrel}"

params=(threadirqs rcu_nocbs=all nowatchdog nmi_watchdog=0)

# 1. Kernel command line. Append only the parameters the file does not already
#    carry, so a re-run never duplicates them.
if [[ -f $defaults_conf ]]; then
  missing=()
  for param in "${params[@]}"; do
    grep -qw -- "$param" "$defaults_conf" || missing+=("$param")
  done
  if ((${#missing[@]})); then
    printf 'KERNEL_CMDLINE[default]+=" %s"\n' "${missing[*]}" |
      sudo tee -a "$defaults_conf" >/dev/null
  fi
fi

# 2. rtirq (Arch extra): install it, enable the units, and deploy Kestrel's
#    /etc/rtirq.conf so the GPU IRQ threads are covered too.
if command -v pacman >/dev/null && ! pacman -Qi rtirq >/dev/null 2>&1; then
  sudo pacman -S --noconfirm --ask 4 rtirq
fi
if command -v systemctl >/dev/null; then
  sudo systemctl enable rtirq.service rtirq-resume.service >/dev/null 2>&1 || true
fi
if [[ -r $payload/etc/rtirq.conf ]]; then
  sudo install -Dm644 "$payload/etc/rtirq.conf" "$rtirq_conf"
fi

# 3. Rebuild the installed boot entries once so the new command line is baked
#    in. The running kernel keeps its old command line until reboot, so a
#    machine-wide marker records the rebuild: another user's run must not repeat
#    it, while a missing marker still retries an interrupted one.
if command -v limine-mkinitcpio >/dev/null && [[ ! -e $rebuild_marker ]]; then
  booted=""
  [[ -r $running_cmdline ]] && booted=$(<"$running_cmdline")
  unmet=()
  for param in "${params[@]}"; do
    [[ " $booted " == *" $param "* ]] || unmet+=("$param")
  done
  if ((${#unmet[@]})); then
    echo "The booted kernel is missing ${unmet[*]}; rebuilding the boot image"
    sudo limine-mkinitcpio
  fi
  sudo install -Dm644 /dev/null "$rebuild_marker"
fi

command -v kestrel-state >/dev/null && kestrel-state set reboot-required || true
