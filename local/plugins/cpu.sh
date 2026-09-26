#!/bin/sh

# Native CPU widget. This replaces the "CPU" widget Stats draws into the menu
# bar, which this fork's `topmost=on` bar covers.

# `top -l 1` reports an average since boot, so it is useless at a 2s refresh.
# Summing per-process %cpu is instantaneous and cheap; dividing by the core
# count normalises it to 0-100%, the same scale Activity Monitor uses for its
# total and the same scale Stats shows in its menu bar widget.
CORES="$(sysctl -n hw.ncpu)"
LOAD="$(ps -A -o %cpu= | awk -v c="$CORES" '{ s += $1 } END { printf "%.0f", s / c }')"

sketchybar --set "$NAME" icon=󰻠 label="${LOAD}%"
