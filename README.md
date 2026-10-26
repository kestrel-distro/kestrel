# Kestrel

<p align="center">
  <img src="logo.svg" alt="Kestrel" width="160">
</p>

Kestrel is a Linux distribution built on Arch Linux. It provides a complete, preconfigured desktop: the Hyprland tiling compositor, the Quickshell desktop shell, and a curated set of applications and command-line tools. It is maintained by Emiliano Gandini Outeda.

Kestrel makes the default choices for you. The compositor, the shell, the terminal, the editor, the browser, and the themes are selected and configured so that the system is usable immediately after installation. It is intended for users who work primarily from the keyboard and are comfortable editing configuration files.

## What is in the box

- **Hyprland** for window management and **Quickshell** for the desktop: a top bar, an application launcher, notifications, an on-screen display, a screensaver, and the rest of the shell, theme-aware and scriptable throughout.
- **Desktop applications**: Neovim, Chromium, Obsidian, LibreOffice, Kdenlive, OBS Studio, and a Winamp-style music player.
- **The `kestrel` CLI**: a single entry point (`kestrel <group> <command>`) over the commands in `bin/`, covering theming, screenshots, packaging, hardware, and system configuration.
- **Rolling updates on Arch**, with an automatic Btrfs snapshot before every upgrade and rollback from the boot menu.
- **Agentic tooling** installed through `mise`, so AI coding agents are versioned and on `PATH` like any other tool.

## Installing

Install Kestrel from the [Kestrel live ISO](https://github.com/emiliano-go/kestrel-iso). The image boots into a full Kestrel desktop rather than a text installer. From the Super + D menu, **Install Kestrel** writes the running system to the selected disk.

The installer copies the live system, so the installed machine matches the one you tested. There is no separate installation path to diverge from the running image, and no package repository is contacted during the install. Disk encryption is enabled by default; the same installer can install without encryption, install into free space alongside another operating system, or prepare the machine for a different owner and defer account creation to first boot.

## Updating

Kestrel is a rolling release and tracks Arch directly. Update with `sudo pacman -Syu`, and an AUR helper such as `yay -Sua` for AUR packages. There is no `kestrel update` command and no release channels: the system is the Arch base it was installed from, plus what Arch and the AUR provide.

A post-transaction hook records a recovery snapshot after every upgrade (`default/snapper/root` keeps the two most recent). To roll back, select a snapshot in Limine and run `kestrel-snapshot restore`.

## Documentation

[`manual/`](manual/) is the end-user manual, and its authoritative source. Start with [Welcome to Kestrel!](manual/01-welcome-to-kestrel.md).

## Repository layout

- `bin/` the `kestrel-*` commands that are placed on `PATH`.
- `config/` defaults copied into `~/.config/` for new users.
- `default/` system integration: systemd units, libalpm hooks, Limine, snapper, Plymouth, SDDM, and related files.
- `etc/` the `/etc` drop-ins Kestrel owns outright.
- `install/` the install and finalize scripts the ISO runs against a target.
- `shell/` the Quickshell desktop.
- `themes/` the themes.
- `brand/` the logo source and the generator for the derived brand assets.
- `manual/`, `test/` as described above.

## The manual

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

## License

Kestrel is released under the MIT License. See [LICENSE](LICENSE).
