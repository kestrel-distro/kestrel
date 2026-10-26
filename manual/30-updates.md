# Updates

Kestrel updates in place from the Arch repositories. Run `sudo pacman -Syu` in a
terminal (and an AUR helper such as `yay -Sua` for any AUR packages you have
installed).

Arch is a rolling distribution, so an update always brings the latest packages.
There are no channels to switch and no `kestrel update` command.

### Snapshots

After every upgrade Kestrel records a recovery snapshot automatically. Snapper
keeps the two most recent.

### Rolling back a bad update

If you have a problem after an update, restart and pick the snapshot from before
it in the Limine boot menu. Once booted into the snapshot, run
`kestrel-snapshot restore` (or click the notification) to roll `/` back. Your
`/home` is kept.

![bootloader](images/bootloader.webp)
