#!/bin/sh

# Cycle the bar's vertical offset so the native macOS menu-bar strip can be
# reached. The bar is `topmost=on height=40`, so it normally covers the 33pt
# native strip completely, and sketchybar never passes a click through to what
# is underneath it -- so a native status item (Tailscale, Stats, Control
# Centre, Apple's own) is neither visible nor clickable until the bar moves
# down. Moving it down is the only thing that works: `--add alias` would only
# mirror the item as a captured image (it needs Screen Recording, and there is
# no CGEventPost anywhere in sketchybar, so an alias cannot forward a click).
#
#   0  -> covered (the default look)
#   32 -> a sliver: all but the bottom 1pt of the 33pt native strip is exposed
#   33 -> strip fully clear (the bar sits entirely below it)
#
# Why a sliver is enough: a status item's window spans the whole strip, so a
# click anywhere inside it activates the item. Verified on this machine -- with
# the bar at 14 or 33, a click at (927,5) opened a native status item popover at
# layer 101; with the bar at 0 the same click opened nothing.
#
# The current offset is read back from the bar rather than remembered in a
# state file, so the cycle stays correct across reloads and restarts.
#
# Called from three places:
#   sketchybarrc          script="$PLUGIN_DIR/native_bar_toggle.sh status"
#                         click_script="$PLUGIN_DIR/native_bar_toggle.sh"
#   ~/.aerospace.toml     alt-ctrl-n = 'exec-and-forget <this script>'

SB="$HOME/.local/bin/sketchybar"   # absolute: plugins inherit the bar process's PATH
STRIP=33                           # native menu-bar strip height on this machine
SLIVER=32                          # near-full reveal. 33 would drop the bar a
                                   # full strip-height down and it reads as
                                   # detached; 32 keeps it visually anchored to
                                   # the bottom edge of the native strip.

read_offset() {
  "$SB" --query bar | sed -n 's/.*"y_offset": *\([0-9-]*\).*/\1/p'
}

paint() {
  # ASCII labels on purpose: non-ASCII glyphs written into config files here
  # have silently landed as U+FFFD before.
  case "$1" in
    0)  "$SB" --set native_bar label="menu"    background.color=0x40ffffff ;;
    32) "$SB" --set native_bar label="menu 32" background.color=0x66ff9f0a ;;
    33) "$SB" --set native_bar label="menu 33" background.color=0x66ff453a ;;
  esac
}

cur=$(read_offset)

# `status`: re-sync the item's label after an rc reload. The offset itself
# survives a reload (the rc never sets y_offset), so only the label goes stale.
if [ "$1" = "status" ]; then
  paint "$cur"
  exit 0
fi

case "$cur" in
  0)  next=$SLIVER ;;
  32) next=$STRIP  ;;
  *)  next=0       ;;
esac

"$SB" --bar y_offset="$next"
paint "$next"
