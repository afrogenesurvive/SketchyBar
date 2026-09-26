#!/bin/sh

# Click handler for the Wi-Fi item.
#
# `networksetup -setairportpower` accepts only "on" or "off" (there is no
# "toggle"), so the current state has to be read first. Toggling Wi-Fi power
# needs no admin rights and no TCC grant.

INTERFACE=en0

if networksetup -getairportpower "$INTERFACE" 2>/dev/null | grep -q 'On$'; then
  networksetup -setairportpower "$INTERFACE" off
else
  networksetup -setairportpower "$INTERFACE" on
fi

# Re-runs every item script, which refreshes this item via wifi.sh.
sketchybar --update
