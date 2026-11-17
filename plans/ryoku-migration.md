# Plan: Ryoku aesthetic, bar and launcher in Kestrel

Status: in progress. Revision 2 — decisions taken.

## decisions (settled)

1. **License: GPLv3.** Kestrel is relicensed to GPL-3.0 (see LICENSE, NOTICE).
   Ryoku code is copied, not reimplemented. Upstream MIT portions (Omarchy)
   remain attributed.
2. **Launcher: all Ryoku variants** (Main, Hero, Kairos, Spotlight, Python,
   OkShell), selectable, like Ryoku's `launcher.json variant`.
3. **Keybinds stay as they are.** The launcher is reached through the existing
   menu route/bar button; no user chord is moved.
4. **Bar: Ryoku's Orpheus liquid bar** (copied, not restyled), which means
   vendoring the `Ryoku.Blobs` C++ QML plugin and the Orpheus scene.
5. **Follow-wallpaper palette** (Ryoku's matugen flow) is in scope.
6. **No print shaders.** Kestrel keeps the compositor look it has; only
   gaps/blur/shadow/opacity follow the aesthetic.

## what is already landed

- `LICENSE` → GPLv3, `NOTICE` with Omarchy (MIT) and Ryoku (GPLv3)
  attribution, README updated.
- `shell/Ryoku/Ui/` — Ryoku's whole QML design system (`Ryoku.Ui`,
  `Ryoku.Ui.Singletons.Tokens`), importable from the shell because the shell
  dir is a QML import root. Pure QML, no build step.
- `shell/Commons/Tokens.qml` — the design vocabulary (paper, four-tier ink,
  bone/inverse pair, hairlines, tints, sun/alert, geometry, motion, `light`)
  resolved from `Commons.Color`/`Commons.Style`, registered as
  `qs.Commons.Tokens`. No second palette, and light themes invert correctly.
- `default/themed/shell.toml.tpl` `[font]` now accepts `display-family`,
  `mono-family`, `jp-family`; `Commons/Style.qml` parses them and exposes
  `Style.font.displayFamily/monoFamily/jpFamily`, falling back to the session
  font so a theme without fonts changes nothing.
- `themes/titan-black`, `themes/titan-light`: section overrides
  (`shell.menu.toml`, `shell.launcher.toml`, `shell.popups.toml`,
  `shell.hyprland.toml`) giving both Titan themes a flat steel hairline, a
  paper scrim and the accent on the chosen row. The palettes already shipped;
  these files make them full themes.

## remaining work, in order

### A. Tokens adoption in the shell (the aesthetic lands)
- [x] `Commons/Tokens.qml` bridge landed.
- [ ] Rewire `Commons/Style.qml` geometry/motion to Tokens (single source).
- [ ] Restyle `shell/Ui/*` and every plugin surface to hairline + inversion,
      radius from Tokens, no chrome gradients.
- [ ] Package fonts: Fraunces, Space Grotesk, SpaceMono Nerd Font,
      Noto Sans CJK JP; default `shell.json` sets them, themes may override
      via the new `[font]` keys.
- [ ] Tests: token resolution, light/dark inverse, theme validation for all 24
      themes; update border/colour source-assertion tests.

### B. Ryoku.Ui primitives in Kestrel surfaces
- [ ] Map Ryoku's kit components (`Btn`, `Field`, `Seg`, `Tabs`, `Chip`,
      `Keycap`, `DitherImage`, …) onto present Kestrel call sites where they
      replace a bespoke control; do not duplicate Kestrel's existing ones.
- [ ] Keep `qs.Ui`/`qs.Commons` as the API Kestrel plugins import; expose
      Ryoku tokens through them so plugins never import `Ryoku.Ui` directly
      (avoids a second design system in plugin code).

### C. Launcher (all variants)
- [x] Kestrel-native launcher (`shell/plugins/launcher/`, `kestrel.launcher`):
      paper card over the shared overlay window with exclusive keyboard focus;
      apps from the shell AppLibrary, an action catalogue, safe arithmetic and
      web search, routed by `=`, `?`, `/` prefixes; Super+Space, the
      `launcher default` shortcut and IPC all reach it.
- [ ] Port Ryoku's six visual variants (Main/Hero/Kairos/Spotlight/Python/
      OkShell) and its dispatcher/provider set once the service adapters exist.
- [ ] Vendor `modules/launcher` (variants + shared providers/singletons) and
      map its service dependencies onto Kestrel: `AppLibrary`, window list,
      clipboard, media, files, packages, web.
      Ryoku providers that shell out to `ryoku-cmd-*`/`ryoku-shell ipc` get a
      Kestrel adapter or ship disabled with a notice.
- [ ] Host it as a first-party `menu` plugin (`kestrel.launcher`) on
      `KeyboardPanel`, bound to the existing menu route; bar button keeps
      working.
- [ ] `config/kestrel/launcher.json` (`variant`, providers, hidden apps).
- [ ] Tests: variant selection, provider gating, key routing, summon/dismiss;
      acceptance in the VM.

### D. Orpheus bar (copy)
- [ ] Vendor `ryoku/shell/plugin` (`Ryoku.Blobs`, C++ QML plugin: BlobRect,
      BlobWave, BlobGroup, shaders) and add it to the ISO/package build.
- [ ] Vendor `modules/bar` + `barstyles/orpheus` and the shared bar services
      it reads (media, battery, workspaces, tray).
- [ ] Swap the default bar host to the Orpheus scene while keeping Kestrel's
      bar widget contract available for existing plugins.
- [ ] Port Kestrel-only widgets (agents, vault) into Orpheus' widget registry.
- [ ] Tests: layer namespaces, click targets, bar contract, acceptance
      screenshots.

### E. Follow-wallpaper palette
- [ ] Vendor matugen templates (`ryoku/shell/matugen`) and the palette writer;
      add a shell setting: named theme vs follow wallpaper.
- [ ] Emit the same `colors.json` + `shell.toml` so `Commons/Color.qml` needs
      no change; palette cross-fade like Tokens already does.
- [ ] Tests: palette file validation, fallback to the named theme on a missing
      or half-written palette.

### F. Docs / packaging / release
- [ ] Manual page for the design language and theme authoring.
- [ ] Packaging: fonts, Blobs plugin, matugen, launcher assets.
- [ ] VM shell + acceptance suites green; version bump + changelog.

## risks

- Orpheus depends on Ryoku's newer shell host and services; vendoring it is
  the largest single piece and cannot be validated until the C++ plugin builds
  in Kestrel's packaging.
- Two design systems in one tree: enforce that plugins consume `qs.Commons`
  only, with Tokens as the implementation behind it.
- Launcher providers must not silently no-op; a missing Kestrel equivalent is
  a visible "not available" row, never a dead entry.
