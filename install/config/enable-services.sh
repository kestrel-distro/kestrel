# Enable services only. Installs are followed by reboot, so don't start/reload
# daemons mid-install. UFW and hardware-gated services stay in their own scripts.
systemctl enable cups.socket
systemctl enable avahi-daemon.service
systemctl enable linux-modules-cleanup.service
systemctl enable docker.socket
systemctl enable systemd-resolved.service
systemctl enable NetworkManager.service
# Don't let network-online.target hold up graphical.target waiting for
# DHCP/Wi-Fi association. Nothing in the session needs to block on the network.
# Mirrors the systemd-networkd-wait-online mask in install/hardware/network.sh.
systemctl mask NetworkManager-wait-online.service
systemctl enable power-profiles-daemon.service
systemctl enable sddm.service
# Kill one runaway app scope instead of letting reclaim thrashing take the
# whole session down. [Install] pulls in systemd-oomd.socket via Also=, which
# is what the user manager reports app.slice candidacy over.
systemctl enable systemd-oomd.service
systemctl enable systemd-timesyncd.service

# Performance: sched_ext scheduler (scx_loader starts scx_bpfland; switch with
# `kestrel scx`), DAMON proactive reclaim, and ananicy-cpp niceness rules.
# Each unit is inert on kernels or hardware that can't support it.
systemctl enable scx_loader.service
systemctl enable kestrel-damon-reclaim.service
systemctl enable ananicy-cpp.service

# IRQ and timer: `threadirqs` on the kernel command line turns device IRQ
# handlers into threads, and rtirq raises the priority of the audio, input and
# GPU ones so they preempt ordinary work. Both units are inert when threadirqs
# is not set (there are no IRQ threads to raise). See C2.3 of the kernel plan.
systemctl enable rtirq.service
systemctl enable rtirq-resume.service

# Default optimizations: keep the SSD trimmed, watch disk health, refresh the
# Arch mirror list, and scrub Btrfs where the root filesystem is Btrfs.
systemctl enable fstrim.timer
systemctl enable smartd.service
systemctl enable reflector.timer
if [[ $(findmnt -no FSTYPE /) == "btrfs" ]]; then
  systemctl enable btrfs-scrub@-.timer
fi
