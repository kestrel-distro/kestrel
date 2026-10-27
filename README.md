# Kestrel

<p align="center">
  <img src="logo.svg" alt="Kestrel" width="160">
</p>

Kestrel is a standalone Linux distribution built on Arch. It ships one shaped
desktop — Hyprland, Quickshell, foot and fish — and a kernel bridge that lets
the compositor, the terminal and the apps talk to the scheduler in one
vocabulary.

Kestrel makes the default choices for you. The compositor, shell, terminal,
editor, browser and themes are selected and configured so the system is usable
immediately after installation. It is intended for people who work from the
keyboard and are comfortable editing configuration files.

## The scheduling bridge

Most distributions give the desktop a scheduler and leave it at that. Kestrel
adds a per-task hint path:

- **Kernel:** `linux-kestrel` appends `sched_ext_hint` to `struct sched_attr`.
  Userspace sets it with `sched_setattr(2)` and `SCHED_FLAG_KESTREL_HINT`
  (`1ULL << 40`), value `0..1024`.
- **Userspace:** `libkestrel-hint` / `kestrel-hint` set and read the hint.
- **Broker:** `kestrel-broker` places the compositor, terminals, browser and
  background work in the `kestrel-desktop`, `kestrel-term`, `kestrel-browser`
  and `kestrel-background` cgroups.
- **Scheduler:** `scx_kestrel` (an `scx_layered` fork) reads the hint through
  `scx_bpf_task_hint()` and applies its baked layer set, selectable through
  `scx_loader`/`scxctl`.

`scx_bpfland` remains the default in the live session; `kestrel-bench` runs the
A/B that decides whether `scx_kestrel` replaces it.

## What is in the box

- **Hyprland** for window management and **Quickshell** for the desktop: top
  bar, launcher, notifications, OSD, screensaver, theme-aware and scriptable
  throughout.
- **foot** as the terminal, one shared server in the `kestrel-term` slice, with
  a per-window palette so terminals opened after a theme switch match. **fish**
  is the login shell; scripts stay bash.
- **Desktop applications**: Neovim, Zen (Chromium fallback), Obsidian,
  LibreOffice, Kdenlive, OBS Studio, and a Winamp-style music player.
- **The `kestrel` CLI**: one entry point (`kestrel <group> <command>`) over
  `bin/`, covering themes, screenshots, packaging, hardware and system
  configuration.
- **Rolling updates on Arch**, with an automatic Btrfs snapshot before every
  upgrade and rollback from the boot menu.
- **Agentic tooling** installed through `mise`, so AI coding agents are
  versioned and on `PATH` like any other tool.
- **`kestrel-bench`**, the dev-only VM bench for the hint bridge, the scheduler
  A/B, foot worker counts and peak memory of the shipped apps.

## Installing

Install Kestrel from the [live ISO](https://github.com/kestrel-distro/iso). The
image boots a full Kestrel desktop rather than a text installer. From the
Super+D menu, **Install Kestrel** writes the running system to the selected
disk.

The installer copies the live system, so the installed machine is the one you
tested. There is no separate installation path to drift from it, and no package
repository is contacted during the install. Encryption is the default; the same
wizard can install without it, install into free space alongside another OS, or
prepare the machine for a different owner and defer account creation to first
boot. The live image boots the Kestrel kernel.

## Updating

Kestrel is rolling and tracks Arch directly. Update with `sudo pacman -Syu` and
an AUR helper such as `yay -Sua` for AUR packages. There is no `kestrel update`
command and no release channels: the system is the Arch base it was installed
from plus what Arch, the AUR and `[kestrel]` provide.

A post-transaction hook records a recovery snapshot after every upgrade
(`default/snapper/root` keeps the two most recent). To roll back, select a
snapshot in Limine and run `kestrel-snapshot restore`.

## Measuring

Run `kestrel-bench` inside the VM. It checks `kestrel-hint supported`, exercises
set/get, verifies the broker and foot placement, runs a 3× `scx_bpfland` vs
`scx_kestrel` A/B, measures the foot worker matrix, and samples peak PSS for
Hyprland, Quickshell, foot, footclient and the other shipped processes. Results
land under `~/.cache/kestrel/vm-logs/bench-*` on the host.

## Repository layout

- `bin/` the `kestrel-*` commands placed on `PATH`.
- `config/` defaults copied into `~/.config/` for new users (Hyprland, foot,
  fish, fastfetch, btop, tmux, ...).
- `default/` system integration: systemd units, libalpm hooks, Limine, snapper,
  Plymouth, SDDM, `default/themed/` templates, and related files.
- `etc/` the `/etc` drop-ins Kestrel owns outright.
- `install/` the install and finalize scripts the ISO runs against a target.
- `shell/` the Quickshell desktop.
- `themes/` the themes.
- `brand/` the logo source and the generator for derived brand assets.
- `packaging/` the source packages built from this repository
  (`libkestrel-hint`, `kestrel-broker`).
- `manual/`, `test/` the end-user manual and the VM test suites.

## Documentation

[`manual/`](manual/) is the end-user manual and its authoritative source. Start
with [Welcome to Kestrel!](manual/01-welcome-to-kestrel.md).
Maintainer documentation is in
[`kestrel-distro/docs`](https://github.com/kestrel-distro/docs).

**The Basics**

- [Welcome to Kestrel!](manual/01-welcome-to-kestrel.md)
- [Getting Started](manual/02-getting-started.md)
- [Coming From Windows](manual/03-coming-from-windows.md)
- [Navigation](manual/04-navigation.md)
- [The top bar](manual/05-the-top-bar.md)
- [Themes](manual/06-themes.md)
- [Hotkeys](manual/07-hotkeys.md)
- [Unified Clipboard & History](manual/08-unified-clipboard-history.md)
- [Reminders](manual/09-reminders.md)
- [Notices](manual/10-notices.md)
- [Text Extraction & Dictation](manual/11-text-extraction-dictation.md)
- [Screenshots & Recording](manual/12-screenshots-recording.md)
- [Toggles, idle & screensaver](manual/13-toggles-idle-screensaver.md)
- [Kestrel CLI](manual/14-kestrel-cli.md)

**The Applications**

- [Terminal](manual/15-terminal.md)
- [Neovim](manual/16-neovim.md)
- [AI](manual/17-ai.md)
- [Development Tools](manual/18-development-tools.md)
- [Shell Tools](manual/19-shell-tools.md)
- [Shell Functions](manual/20-shell-functions.md)
- [TUIs](manual/21-tuis.md)
- [GUIs](manual/22-guis.md)
- [Browsers](manual/23-browsers.md)
- [Commercial apps/services](manual/24-commercial-apps-services.md)
- [Web Apps](manual/25-web-apps.md)
- [Gaming](manual/26-gaming.md)
- [Filling out PDFs](manual/27-filling-out-pdfs.md)
- [Windows VM](manual/28-windows-vm.md)
- [Other Packages](manual/29-other-packages.md)

**Configuration**

- [Updates](manual/30-updates.md)
- [Dotfiles](manual/31-dotfiles.md)
- [Shell plugins](manual/32-shell-plugins.md)
- [Monitors](manual/33-monitors.md)
- [Keyboard, Mouse, Trackpad](manual/34-keyboard-mouse-trackpad.md)
- [Networking](manual/35-networking.md)
- [System sleep](manual/36-system-sleep.md)
- [Hardware authentication](manual/37-hardware-authentication.md)
- [Fonts](manual/38-fonts.md)
- [Backgrounds](manual/39-backgrounds.md)
- [Prompt](manual/40-prompt.md)
- [Branding](manual/41-branding.md)
- [Common tweaks](manual/42-common-tweaks.md)
- [Making your own theme](manual/43-making-your-own-theme.md)

**The Rest**

- [Troubleshooting](manual/45-troubleshooting.md)
- [FAQ](manual/46-faq.md)
- [System snapshots](manual/47-system-snapshots.md)
- [Security](manual/48-security.md)
- [Kestrel on...](manual/49-kestrel-on.md)
- [Dual Boot Install](manual/50-dual-boot-install.md)
- [Unattended Installs](manual/51-unattended-installs.md)
- [Portable vault](manual/52-portable-vault.md)

## Related repositories

- [`iso`](https://github.com/kestrel-distro/iso) — live image and installer.
- [`kernel`](https://github.com/kestrel-distro/kernel) — `linux-kestrel`.
- [`desktop`](https://github.com/kestrel-distro/desktop) — desktop library
  closure and metapackage.
- [`foot`](https://github.com/kestrel-distro/foot),
  [`hyprland`](https://github.com/kestrel-distro/hyprland),
  [`quickshell`](https://github.com/kestrel-distro/quickshell) — the lean
  desktop sources.
- [`scx`](https://github.com/kestrel-distro/scx),
  [`scx-loader`](https://github.com/kestrel-distro/scx-loader) — the scheduler
  and its loader.
- [`packages`](https://github.com/kestrel-distro/packages),
  [`docs`](https://github.com/kestrel-distro/docs).

## License

Kestrel is released under the MIT License. See [LICENSE](LICENSE).
