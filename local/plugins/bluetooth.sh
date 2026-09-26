#!/bin/sh

# Native Bluetooth item (mirrors the "Control Centre,Bluetooth" menu bar item).
#
# This fork has no bluetooth event (available: wifi_change, brightness_change,
# media_change, volume_change, power_source_change, ...) and blueutil is not
# installed, so this polls `system_profiler SPBluetoothDataType` (~0.3s).
# Keep the item's update_freq at 15 or higher.

INFO="$(system_profiler SPBluetoothDataType 2>/dev/null)"

# "Bluetooth Controller:" block, indent 10.
POWER="$(printf '%s\n' "$INFO" | awk '/^          State:/ { print $2; exit }')"

if [ "$POWER" != "On" ]; then
  sketchybar --set "$NAME" icon=󰂲 label.drawing=off
  exit 0
fi

# Section headers sit at indent 6 ("Connected:" / "Not Connected:"), the
# device names belonging to them one level deeper at indent 10. The whole
# "Connected:" section is absent when nothing is connected.
DEVICE="$(printf '%s\n' "$INFO" | awk '
  /^      Connected:/ { conn = 1; next }
  /^      [A-Z]/     { conn = 0 }
  conn && /^          [^ ]/ {
    name = $0
    sub(/^ +/, "", name)
    sub(/:$/, "", name)
    print name
    exit
  }')"

if [ -n "$DEVICE" ]; then
  sketchybar --set "$NAME" icon=󰂱 label="$DEVICE" label.drawing=on
else
  sketchybar --set "$NAME" icon=󰂯 label.drawing=off
fi
