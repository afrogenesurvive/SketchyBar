#!/bin/sh

# Highlights the focused AeroSpace workspace item.
# Referenced from sketchybarrc as:
#   script="$CONFIG_DIR/plugins/aerospace.sh <workspace-name>"
# FOCUSED_WORKSPACE is injected by the exec-on-workspace-change callback in ~/.aerospace.toml:
#   sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE
# The very first run comes from "sketchybar --update" (no FOCUSED_WORKSPACE set yet),
# so fall back to asking the AeroSpace CLI which workspace is focused.

if [ -z "$FOCUSED_WORKSPACE" ]; then
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)
fi

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set "$NAME" background.drawing=on
else
  sketchybar --set "$NAME" background.drawing=off
fi
