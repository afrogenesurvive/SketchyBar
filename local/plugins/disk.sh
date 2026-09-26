#!/bin/sh

# Native Disk widget, replacing the "Disk" widget Stats draws into the menu
# bar.
#
# Note the volume: on APFS, "/" is the sealed read-only system volume and
# reports only a few GB used, so the data volume is what is worth showing.

VOLUME=/System/Volumes/Data

PERCENT="$(df -k "$VOLUME" | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')"

if [ -z "$PERCENT" ]; then
  exit 0
fi

sketchybar --set "$NAME" icon=󰋊 label="${PERCENT}%"
