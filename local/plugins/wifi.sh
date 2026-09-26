#!/bin/sh

# Native Wi-Fi item (mirrors the "Control Centre,WiFi" menu bar item).
#
# State is derived only from sources that need NO TCC grant:
#   networksetup -getairportpower en0  -> "Wi-Fi Power (en0): On|Off"
#   ifconfig en0                       -> "status: active|inactive"
#
# The SSID itself is NOT available without Location Services authorisation:
# CoreWLAN returns nil for ssidData (which is what src/wifi.m reads) and
# `ipconfig getsummary en0` prints "<redacted>". So the fork's wifi_change
# event normally delivers an EMPTY $INFO, and this script must not depend on
# it. If the user ever grants Location Services to sketchybar, the SSID
# arrives in $INFO and is displayed.

INTERFACE=en0
ICON_COLOR=0xffffffff
DIM_COLOR=0xff888888

SSID="$INFO"
case "$SSID" in
  ""|"<redacted>") SSID="" ;;
esac

POWER="$(networksetup -getairportpower "$INTERFACE" 2>/dev/null | awk '{ print $NF }')"

if [ "$POWER" != "On" ]; then
  # Radio off.
  sketchybar --set "$NAME" icon=󰖪 icon.color=$ICON_COLOR label.drawing=off
  exit 0
fi

if ifconfig "$INTERFACE" 2>/dev/null | grep -q 'status: active'; then
  # Associated. Show the SSID only when it is genuinely readable.
  if [ -n "$SSID" ]; then
    sketchybar --set "$NAME" icon=󰖩 icon.color=$ICON_COLOR label="$SSID" label.drawing=on
  else
    sketchybar --set "$NAME" icon=󰖩 icon.color=$ICON_COLOR label.drawing=off
  fi
else
  # Radio on but not associated to any network: same glyph, dimmed.
  sketchybar --set "$NAME" icon=󰖩 icon.color=$DIM_COLOR label.drawing=off
fi
