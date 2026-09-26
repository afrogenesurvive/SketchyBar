# local/ — my live sketchybar + AeroSpace configuration

These files are **copies**. They are not read by anything at runtime; they exist so the
configuration I actually use is version-controlled alongside the fork it needs.

| Copy here | Lives at | Deployed with |
| --- | --- | --- |
| `sketchybarrc` | `~/.config/sketchybar/sketchybarrc` | `cp local/sketchybarrc ~/.config/sketchybar/` |
| `plugins/*.sh` | `~/.config/sketchybar/plugins/` | `cp local/plugins/*.sh ~/.config/sketchybar/plugins/` |
| `aerospace.toml` | `~/.aerospace.toml` | `cp local/aerospace.toml ~/.aerospace.toml` |

**`~/.config` is the source of truth.** Edit there, then copy back here. Do not edit here and
expect the bar to change.

## Why the repo's own `sketchybarrc` and `plugins/` are not used

Those are the pristine upstream demo, kept unmodified so `git pull upstream master` stays
conflict-free (see `docs/SETUP.md`). My config is a separate, personal layer on top of the
fork, which is what this directory records.

## What is in here beyond the stock demo

- **AeroSpace workspace indicators** — `space.1..10` items driven by the custom
  `aerospace_workspace_change` event that `~/.aerospace.toml` fires from its
  `exec-on-workspace-change` callback. Replaces the demo's Mission Control `--add space`
  items, which cannot track AeroSpace workspaces (AeroSpace emulates workspaces by parking
  windows in an off-screen "attic"; it does not drive native Spaces).
- **`native_bar_toggle.sh` + the `native_bar` item** — cycles the bar's `y_offset` through
  `0 → 14 → 33` so the native macOS menu-bar strip can actually be reached. The bar is
  `topmost=on` and 40pt tall and sketchybar never passes a click through, so while it
  covers the strip every real status item is invisible *and* unclickable.
- **Click actions** for volume / battery / bluetooth / cpu / ram / disk / clock, with the
  Settings pane identifiers read from each extension's `Info.plist` rather than guessed.
- **Native clones** of the status items (`wifi`, `bluetooth`, `cpu`, `ram`, `disk`) because
  aliases were not usable: `--add alias` needs Screen Recording and cannot forward a click
  (there is no `CGEventPost` anywhere in sketchybar).

## Fork-only facts this config depends on

- `--bar show_in_fullscreen=on` is required on this machine — almost every space is a macOS
  native fullscreen space (type 4) and `src/bar_manager.c` parks the bar when `show_in_fullscreen`
  is off, which makes every item invisible and unclickable.
- After changing `show_in_fullscreen`, run `sketchybar --trigger space_change` or the bar
  will not re-lay-out.
- `--reorder` silently drops items; use `--move`.

## Deploying after a pull

```sh
cp local/sketchybarrc  ~/.config/sketchybar/
cp local/plugins/*.sh  ~/.config/sketchybar/plugins/
cp local/aerospace.toml ~/.aerospace.toml
chmod +x ~/.config/sketchybar/plugins/*.sh
aerospace reload-config
sketchybar --reload
```
