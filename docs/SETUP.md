# Local setup (building this fork from source)

How this fork is built, installed and run on macOS, plus the AeroSpace workspace integration.
Upstream installation via `brew install sketchybar` is deliberately *not* used here so the fork's
own binary is what runs.

Verified 2026-09-25 on macOS 26.6.2 (build 25G83), Xcode 26 / Apple clang 21, Apple Silicon.

## 1. Build

```bash
make          # universal binary: builds x86_64, then arm64, then lipo-joins them
make arm64    # arm64 only, roughly half the time
```

The artifact is `bin/sketchybar` (gitignored). Other targets: `debug`, `asan`, `leak`, `clean`.

The makefile links private frameworks (`SkyLight`, `DisplayServices`, `MediaRemote`) from
`/System/Library/PrivateFrameworks`; the source has explicit `macOS 26.0` availability branches, so
the current macOS release is supported.

## 2. Install the binary

```bash
mkdir -p ~/.local/bin
cp bin/sketchybar ~/.local/bin/sketchybar
```

Why `~/.local/bin`:

- `/usr/local/bin` requires `sudo`.
- `/opt/homebrew/bin` is owned by Homebrew and would collide with a future `brew install sketchybar`.

The binary **must keep the name `sketchybar`**: `main()` derives the config directory name from
`basename(argv[0])`, so `foo` would make it look for `~/.config/foo/sketchybarrc`.

`~/.local/bin` has to be on `PATH` (`~/.zshrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Re-install after a rebuild:

```bash
make && cp bin/sketchybar ~/.local/bin/sketchybar && launchctl kickstart -k gui/$(id -u)/com.afrogenesurvive.sketchybar
```

## 3. Configuration

The live config lives in `~/.config/sketchybar` — the standard location, auto-discovered, so no
`--config` flag is needed. Full lookup order:

1. `$XDG_CONFIG_HOME/sketchybar/sketchybarrc`
2. `~/.config/sketchybar/sketchybarrc`
3. `~/.sketchybarrc`

| Path | Role |
| --- | --- |
| `~/.config/sketchybar/sketchybarrc` | the config script, run on start and on hotload |
| `~/.config/sketchybar/plugins/*.sh` | item scripts and click scripts |

Seed it from this repo:

```bash
mkdir -p ~/.config/sketchybar/plugins
cp sketchybarrc ~/.config/sketchybar/sketchybarrc
cp plugins/*.sh ~/.config/sketchybar/plugins/
chmod +x ~/.config/sketchybar/sketchybarrc ~/.config/sketchybar/plugins/*.sh
```

Details worth knowing:

- The config is executed as `/usr/bin/env sh -c <path>`, and `$CONFIG_DIR` is exported to it
  (that is why the rc uses `$CONFIG_DIR/plugins/...`). No shebang is needed, and `+x` is added
  automatically if missing.
- Scripts and click scripts run the same way, with the environment of the bar process plus the
  variables listed in section 7. They must be executable, but are not re-parsed on reload — the
  script *body* is read fresh on every invocation.
- Absolute paths are required inside plugins; relative paths are not resolved against the config dir.
- The repo copy in `sketchybarrc` / `plugins/` is the pristine upstream demo. Local edits belong in
  `~/.config/sketchybar` only, which keeps `git pull upstream master` conflict-free.

### Hotload

The live `sketchybarrc` starts with:

```bash
sketchybar --hotload true
```

The config directory is watched via FSEvents, so saving the file reloads the bar in about a second
(rate limited to roughly one reload per second). Verified by changing `height=40` to `height=41`:
`--query bar` reported the new value with the process id unchanged.

## 4. Fonts

The demo config asks for `icon.font="Hack Nerd Font:Bold:17.0"`:

```bash
brew install --cask font-hack-nerd-font
```

Without it, Nerd Font glyphs render as empty boxes. A font from any path can be registered with
`sketchybar --load-font <file.ttf>`, and `icon.font` / `label.font` accept any installed family.

## 5. Running

Foreground — start here when debugging, because every script's stdout and stderr appear in the
terminal:

```bash
sketchybar
```

Background, logging to a file:

```bash
mkdir -p ~/Library/Logs
nohup sketchybar >> ~/Library/Logs/sketchybar.log 2>&1 &
```

### Autostart (LaunchAgent)

`~/Library/LaunchAgents/com.afrogenesurvive.sketchybar.plist`:

- `ProgramArguments` -> `/Users/michaelgrandison/.local/bin/sketchybar`
- `RunAtLoad` + `KeepAlive` true, `ThrottleInterval` 10
- `LimitLoadToSessionType` -> `Aqua`
- `EnvironmentVariables` -> `HOME`, `USER`, `PATH` (including `~/.local/bin` and `/opt/homebrew/bin`)
- `StandardOutPath` / `StandardErrorPath` -> `/Users/michaelgrandison/Library/Logs/sketchybar.log`

launchd does not expand `~`, and agent processes do not inherit a login shell's environment, so all
three variables are set explicitly. `sketchybar` aborts without `USER`, and it looks up its config
through `HOME`; `PATH` is what lets the rc and plugins resolve `sketchybar` and `aerospace`.

A LaunchAgent (per-user, GUI session) is required — `main()` refuses to run as root, so a
LaunchDaemon is not an option.

Control it:

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.afrogenesurvive.sketchybar.plist  # load + start
launchctl bootout   gui/$(id -u)/com.afrogenesurvive.sketchybar                                # stop + unload
launchctl kickstart -k gui/$(id -u)/com.afrogenesurvive.sketchybar                             # restart
launchctl print     gui/$(id -u)/com.afrogenesurvive.sketchybar | head -20                     # status
plutil -lint ~/Library/LaunchAgents/com.afrogenesurvive.sketchybar.plist                       # validate edits
```

Only one instance can run: an `fcntl` write lock is held on `/tmp/sketchybar_<USER>.lock`
(`/tmp/sketchybar_michaelgrandison.lock`). The lock is released by the kernel when the process dies,
so there is never a stale lock to clean up. Use `launchctl bootout` to stop the bar — a bare
`pkill -x sketchybar` is undone by `KeepAlive` within `ThrottleInterval` seconds.

## 6. AeroSpace integration

The demo config draws Mission Control `space` components and its `click_script` shells out to `yabai`.
With AeroSpace as the window manager those are replaced by one item per AeroSpace workspace. Three
pieces, and step 1 requires AeroSpace to be running (`aerospace list-workspaces --all` must return
workspace names, otherwise the loop adds no items).

**1. In `~/.config/sketchybar/sketchybarrc`**, delete the `SPACE_ICONS` / `--add space` block and add:

```bash
sketchybar --add event aerospace_workspace_change

for sid in $(aerospace list-workspaces --all); do
  sketchybar --add item space.$sid left \
             --subscribe space.$sid aerospace_workspace_change \
             --set space.$sid \
             background.color=0x40ffffff \
             background.corner_radius=5 \
             background.height=25 \
             background.drawing=off \
             label="$sid" \
             click_script="aerospace workspace $sid" \
             script="$CONFIG_DIR/plugins/aerospace.sh $sid"
done
```

Leave the chevron, `front_app`, `clock`, `volume`, `battery` items and the trailing
`sketchybar --update` untouched.

**2. `~/.config/sketchybar/plugins/aerospace.sh`** (already installed and executable) highlights the
focused workspace:

```bash
#!/bin/sh

if [ -z "$FOCUSED_WORKSPACE" ]; then
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)
fi

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set "$NAME" background.drawing=on
else
  sketchybar --set "$NAME" background.drawing=off
fi
```

The fallback matters because the first run is the rc's `sketchybar --update`, where
`FOCUSED_WORKSPACE` is not set yet.

**3. Merge into `~/.aerospace.toml`** (do *not* overwrite an existing config — only fall back to
copying `/Applications/AeroSpace.app/Contents/Resources/default-config.toml` when the file does not
exist at all):

```toml
exec-on-workspace-change = ['/bin/bash', '-c',
    '/Users/michaelgrandison/.local/bin/sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE'
]
```

The absolute path is required: AeroSpace's `exec-*` environment is
`PATH=/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}`, which does not include `~/.local/bin`.

Do not also set `after-startup-command = ['exec-and-forget sketchybar']` from the AeroSpace docs —
it duplicates the LaunchAgent. The lock makes a double start harmless, just noisy.

Apply with `aerospace reload-config`, then verify:

```bash
aerospace list-workspaces --all
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=2   # highlight should follow
```

## 7. Usage

### Commands

| Command | Purpose |
| --- | --- |
| `--bar <k>=<v> ...` | global bar properties (position, height, blur_radius, color, notch_width, ...) |
| `--default <k>=<v> ...` | defaults inherited by items created afterwards |
| `--add item <name> <left\|right\|center>` | add a regular item |
| `--set <name> <k>=<v> ...` | change an item property; `popup.*` configures its popup |
| `--reorder` / `--move <name> before\|after <ref>` / `--clone` / `--rename` / `--remove` | item plumbing |
| `--add space\|graph\|bracket\|alias\|slider ...` | special components (Mission Control spaces, graphs, grouped items, menu-bar app mirrors, sliders) |
| `--push <graph> <point> ...` | append data points to a graph |
| `--subscribe <name> <event> ...` | run an item's script on events |
| `--add event <name> [NSDistributedNotification]` | declare a custom event |
| `--trigger <event> [KEY=VALUE ...]` | fire it, injecting `KEY` into the script's environment |
| `--query bar\|<name>\|defaults\|events\|default_menu_items` | inspect current state |
| `--animate <linear\|quadratic\|tanh\|sin\|exp\|circ> <dur> ...` | animate bar/item properties |
| `--hotload <bool>` / `--reload [path]` | config watching / manual reload |
| `-c, --config <file>` / `--load-font <file>` | override the config path / register a font |

Commands can be chained into one invocation, which is what the rc does.

### Environment available to scripts

| Variable | Meaning |
| --- | --- |
| `NAME` | the item's name |
| `SENDER` | `routine` (from `update_freq`), `forced` (from `--update`), or the event name |
| `INFO` | event payload, e.g. the app name for `front_app_switched` |
| `BUTTON` | `left` / `right` / `other`, in click scripts |
| `MODIFIER` | comma-separated `shift,ctrl,alt,cmd,fn` or `none`, in click scripts |
| `SELECTED` | space components only: whether this space is focused |
| `CONFIG_DIR` | directory holding `sketchybarrc` |
| any `KEY=VALUE` from `--trigger` | e.g. `FOCUSED_WORKSPACE` |

Items poll with `update_freq=<seconds>` (clock 10, battery 120), or subscribe to events
(`--subscribe volume volume_change`). Event-driven items cost nothing while nothing changes.

## 8. Troubleshooting

**Every setting silently fails, `--query bar` shows defaults (height 25, `drawing: off`)**
The config runs, but `sketchybar` is not resolvable by the shell that runs it. Symptom in the log is
one `sketchybar: command not found` per line of the rc. The config is executed with the bar
process's own environment, so the directory holding the binary must be on `PATH` *of that process*.
Fix by starting the bar from a login shell, or by adding `PATH` to the LaunchAgent's
`EnvironmentVariables`. Note that exporting `PATH` from *inside* the rc does not help plugins, since
the rc runs in a child process and its environment does not flow back to the bar.

**`could not locate config file..`**
None of the three lookup paths in section 3 resolved. Check `echo $XDG_CONFIG_HOME`: if it is set to
a directory that has no `sketchybar/sketchybarrc`, the first lookup misses (it then falls back, so a
stale `$XDG_CONFIG_HOME` copy would win silently).

**`could not acquire lock-file... already running?`**
Another instance is alive. `pkill -x sketchybar`, or use `launchctl bootout` if it is managed by the
LaunchAgent.

**Icons render as empty boxes** — the Nerd Font is missing (section 4).

**`[!] Set: Item not found 'space.N'` in the log right after a hotload**
Benign and expected with `space` components: hotload rebuilds them, and the rc's trailing
`sketchybar --update` runs the space scripts before the components are re-instantiated. The items do
exist afterwards (`sketchybar --query space.1`). This disappears once the space block is replaced
with the AeroSpace items in section 6.

**A new plugin does nothing** — it must be executable (`chmod +x`) and referenced with an absolute
path (`$CONFIG_DIR/plugins/name.sh`).

**Nothing appears** — run `sketchybar` in the foreground and watch the terminal; script errors are
only visible there or in `~/Library/Logs/sketchybar.log` when started by the LaunchAgent.

## 9. Source reference

| Concern | Location |
| --- | --- |
| config lookup, `CONFIG_DIR`, `+x` chmod, hotload FSEvents | `src/hotload.c` |
| `sh -c` execution, chmod helper, root/executable checks | `src/misc/helpers.h` |
| script environment variables, click scripts | `src/bar_item.c` |
| `basename(argv[0])`, lockfile, startup sequence | `src/sketchybar.c` |
| CLI surface | `src/misc/help.h` |
| build targets and framework list | `makefile` |

Only this document is version controlled; the installed binary, `~/.config/sketchybar` and the
LaunchAgent are local machine state.
