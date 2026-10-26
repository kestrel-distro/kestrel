# Security

Kestrel takes security extremely seriously. This is meant to be an operating system that you can use to do _Real Work_ in the _Real World_. Where losing a laptop can't lead to a security emergency. So here's what we do:

1. *Full-disk encryption is mandatory*: This is the most important step to securing the physical protection of your data. If your computer is lost or stolen, the data is fully encrypted using standard LUKS (Linux Unified Key Setup).
2. *Firewall is enabled by default*: All incoming traffic is blocked by default except for port 53317 for [LocalSend](https://localsend.org/). Even ssh is off until you turn it on via _Setup > Security > SSHD_, which opens port 22 (rate limited against brute force) as part of the setup. We even lock down Docker access using the [ufw-docker](https://github.com/chaifeng/ufw-docker) setup to prevent that your containers are accidentally exposed to the world.
3. *Arch always have the latest updates*: Arch, the underlying distro that Kestrel is built on, is a rolling distribution. This means that any security vulnerability that's discovered and patched in any package is quickly available for install using `sudo pacman -Syu`. You're always running the latest, most secure versions of everything that way.
4. *Kestrel maintains its own packages and mirror*: Kestrel only relies on packages from Arch's own core/extra/multilib repositories and its own Kestrel Package Repository by default. You can install software directly from AUR, but the base install doesn't, only a few optional installs, like the third-party browsers, pull from the AUR.
5. *Cloudflare protects us from DDoS*: All the Kestrel distribution infrastructure, the ISOs, the Kestrel packages, the Arch mirror, is protected behind Cloudflare's formidable DDoS shield and hosted on their CDN. This provides superb availability.

## Changing your passwords

You have two passwords on an encrypted install: the one that unlocks the drive at boot, and the one you log in and `sudo` with. Both can be changed from a terminal: run `kestrel-drive-password` for the drive password, and `passwd` for your login password. Changing the drive password asks for the current one first, so have it handy.

## Passing on a machine you've already used

If you're handing your machine over to someone else, you don't have to reinstall it. Run _Setup > Reset Computer_ in the Kestrel menu, type `reset` to confirm, and reboot. That wipes every user account and everything in `/home`, throws away all the packages and system changes you made since installation, and clears the machine's identity, network connections, host keys, and all. What comes back up is the setup wizard from the first boot, ready for its new owner to enter their own name, password, and encryption password.

It works by restoring the baseline snapshot the installer takes, so it's only available on machines installed from the Kestrel ISO. And on a drive without encryption, a reset is deletion rather than a secure erase, so if the data was sensitive, do a fresh install instead.

## Passwordless sudo

Sometimes you want `sudo` to stop asking, most often when an AI agent is doing a long stretch of system work for you. _Setup > Security > Passwordless Sudo_ asks how long to allow access: **15 minutes**, **1 Hour**, **1 Day**, or **Permanently**. A red warning icon appears beside the other menu bar indicators while access is active. Click it or run the command again to turn access off. You can also pass your own number of minutes (from 1 to 1440) with `kestrel-sudo-passwordless 30`, or use `kestrel-sudo-passwordless permanent`.

Timed access expires automatically, including immediately after resuming from a suspend that crossed the deadline. Restarting the computer ends it early. Permanent access survives reboots and stays enabled until you disable it.

Updating or removing Kestrel's settings package ends any temporary grant before its expiry support changes. If the command reports an authorization or cleanup error, resolve it before trying to enable another grant; an error does not mean passwordless access is inactive.

Be clear-eyed about this one: while it's on, anything running as your user can do anything as root without being asked. That's the whole point, and it's also the whole risk.

## Signing Keys

The public key for all ISO signatures and Kestrel repo package is `F759D6D49B0A395AB922414A5CC3B4C50D37E793` ([verify at keys.openpgp.org](https://keys.openpgp.org/search?q=F759D6D49B0A395AB922414A5CC3B4C50D37E793)). The `kestrel/kestrel-keyring` package contains this as well and will be used to rollout any potential updates seamlessly.

You can find the signature for any ISO release alongside the image, with `.sig` appended to the file name.
