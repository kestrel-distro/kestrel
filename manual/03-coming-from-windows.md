# Coming From Windows

If you've spent years on Windows, your fingers know a hundred things your brain has forgotten it ever learned. This chapter is the translation layer: where those instincts go in Kestrel. The features themselves are covered in depth elsewhere; this is just the map.

### Super is the center of everything

All the muscle memory you've built around the Windows key transfers to one key: Super. It is the anchor for nearly every hotkey in Kestrel.

Your Start-menu reflex becomes `Super + Space`. That opens the Kestrel menu, which launches apps, changes settings, installs software, captures the screen, and just about everything else. Start typing to filter. There's also a dedicated apps-only menu on `Super + Alt + Space`. See [navigation](04-navigation.md).

### There's no dock and no desktop icons

Nothing to click to launch things, no icons to arrange on the desktop. Apps start from a hotkey (`Super + Return` for the terminal, `Super + Shift + Return` for the browser, and `Super + K` for a list of everything that's mapped) or from the menu. The one persistent piece of UI is [the top bar](05-the-top-bar.md), which covers what the taskbar, system tray, and Action Center did for you before, and nearly every widget on it does something on left, right, and middle click.

### Windows place themselves

The biggest mindset shift: you don't drag windows around or snap them to screen halves. Open a window and it takes the whole screen. Open a second and they split it. You never fish a window out from under another one, because windows don't overlap.

When you genuinely need a floating window, `Super + T` toggles the active one out of the tiling (and back). But give the tiling a real chance first; it's the heart of the whole thing. [Navigation](04-navigation.md) walks you through it.

Workspaces will feel familiar: they're Windows virtual desktops, except you'll actually use them, because `Super + 1/2/3/4` jumps straight to one and `Super + Shift + 1/2/3/4` sends the active window there. No animation delay, just instant jumps. This means that you might not even need multiple monitors, if you were used to that before.

### Copy and paste just work

On Windows you had Ctrl + C everywhere, except the terminal, where it kills your program. Kestrel gives you `Super + C`, `Super + X`, and `Super + V`, and they work everywhere, including the terminal. No separate reflex to learn for the shell.

Your Win + V clipboard history lives on `Super + Ctrl + V`, and it holds images as well as text. See [unified clipboard & history](08-unified-clipboard-history.md).

### The translation table

| You reach for | In Kestrel |
| ------------- | ---------- |
| Start menu | `Super + Space`, the Kestrel menu |
| Win + Shift + S | `Print Screen`, see [screenshots & recording](12-screenshots-recording.md) |
| Action Center | Notification history on `Super + Shift + Alt + ,` |
| System Restore | Automatic [system snapshots](47-system-snapshots.md) on every update |
| Downloading an installer | _Install_ in the menu, or `kestrel pkg add`, see [other packages](29-other-packages.md) |
| Control Panel | _Setup_ in the menu, which edits plain config files, see [dotfiles](31-dotfiles.md) |

### Some things really are different

A lot of settings live in text files you edit, not panels you click through. That sounds primitive until you realize it means every tweak can be seen, copied to your next machine, and put in version control. The _Setup_ menu drops you straight into the right file and restarts whatever needs restarting when you're done.

Updates come through one command, `sudo pacman -Syu`, that updates every package on the system, taking a snapshot first. No per-app updaters nagging you at random. See [updates](30-updates.md).

Software comes from a package manager, not from downloaded installers.

And when you close a window, the app actually quits. `Super + W` means gone.

### Give it two weeks

The instincts transfer faster than you'd think. Skim the [hotkeys](07-hotkeys.md) chapter once, and whenever you blank on a binding, hit `Super + K`; it shows you all of them. That's the only hotkey you actually have to memorize.
