#!/bin/sh

# Open the LIVE sketchybar config in an editor, straight from the bar.
# Bound to the `chevron` item's click_script in sketchybarrc:
#   left  click -> open the rc in an editor (hotload applies it on save)
#   right click -> reveal the config directory in Finder
#
# $BUTTON is the string "left" | "right" | "other" (src/misc/helpers.h
# get_type_description), NOT the numeric button code -- never compare it to
# numbers. The numeric code is only available inside $INFO as button_code.
#
# The config that matters is the live one under ~/.config. The repo's
# sketchybarrc/plugins are the pristine upstream demo and are never read at
# runtime; ~/.config/sketchybar is the source of truth (the repo keeps a copy
# under local/ for version control only).
#
# CONFIG_DIR is exported by the binary into the rc, not into plugins (the rc
# runs in a forked child), so the path is spelled out here.

CONFIG_DIR="$HOME/.config/sketchybar"
RC="$CONFIG_DIR/sketchybarrc"

if [ "$BUTTON" = "right" ]; then
  open "$CONFIG_DIR"
  exit 0
fi

if [ -d "/Applications/Visual Studio Code.app" ]; then
  open -a "Visual Studio Code" "$RC"
elif [ -d "/Applications/Sublime Text.app" ]; then
  open -a "Sublime Text" "$RC"
else
  open -t "$RC"      # fall back to the default text editor
fi
