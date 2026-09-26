#!/bin/sh

# Native RAM widget, replacing the "RAM" widget Stats draws into the menu bar.
#
# "Used" is the same quantity Activity Monitor calls Memory Used: active +
# wired + compressed pages.

PAGE="$(pagesize)"
TOTAL="$(sysctl -n hw.memsize)"

VM="$(vm_stat)"

ACTIVE="$(printf '%s\n' "$VM" | awk '/Pages active/      { gsub(/\./, ""); print $3 }')"
WIRED="$(printf '%s\n'  "$VM" | awk '/Pages wired down/  { gsub(/\./, ""); print $4 }')"
COMPRESSED="$(printf '%s\n' "$VM" | awk '/occupied by compressor/ { gsub(/\./, ""); print $5 }')"

USED=$(( (ACTIVE + WIRED + COMPRESSED) * PAGE ))
PERCENT=$(( USED * 100 / TOTAL ))

sketchybar --set "$NAME" icon=󰍛 label="${PERCENT}%"
