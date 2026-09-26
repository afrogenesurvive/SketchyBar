#!/bin/sh

# Native "Now Playing" item.
#
# `media_change` is a feature of THIS FORK (src/media.m): the private
# MediaRemote framework notifies on any track/play-state change and the script
# receives $INFO as JSON, e.g.
#   {"state":"playing","title":"...","album":"...","artist":"...","app":"..."}
#
# The script hides the item whenever there is no active track, so it behaves
# like the native Now Playing menu bar item (which only appears when active).

if [ "$SENDER" != "media_change" ] || [ -z "$INFO" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

PARSED="$(printf '%s' "$INFO" | /usr/bin/python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)
title = d.get("title") or ""
if not title:
    sys.exit(1)
artist = d.get("artist") or ""
print("%s\t%s\t%s" % (d.get("state", "paused"), artist, title))
')" || { sketchybar --set "$NAME" drawing=off; exit 0; }

STATE="$(printf '%s' "$PARSED" | cut -f1)"
ARTIST="$(printf '%s' "$PARSED" | cut -f2)"
TITLE="$(printf '%s' "$PARSED" | cut -f3)"

if [ "$STATE" = "playing" ]; then
  ICON="󰏤"
else
  ICON="󰐊"
fi

if [ -n "$ARTIST" ]; then
  sketchybar --set "$NAME" drawing=on icon="$ICON" label="$ARTIST - $TITLE"
else
  sketchybar --set "$NAME" drawing=on icon="$ICON" label="$TITLE"
fi
