#!/usr/bin/env bash
# Screenshots the game's window through niri, which composites Xwayland
# windows the X root never shows. Runs the binary (default: the flake's
# result), waits for the window, optionally holds keys, and prints the
# PNG's path.
#
#   tools/screenshot.sh [binary] [seconds-to-wait] [xdotool keys...]
#   tools/screenshot.sh result/bin/bendoom 2 Right Right Up
#
# Keys need xdotool (nix shell nixpkgs#xdotool) and go to the X window;
# each is held for half a second.
set -euo pipefail
unset LD_LIBRARY_PATH
bin=${1:-result/bin/bendoom}
wait=${2:-2}
shift $(( $# < 2 ? $# : 2 ))
export DISPLAY=${DISPLAY:-:1}
timeout $(( wait + ${#@} + 4 )) "$bin" &
sleep "$wait"
id=$(niri msg windows | grep -B1 'Title: "Bendoom"' | grep -o 'Window ID [0-9]*' | grep -o '[0-9]*')
if [ $# -gt 0 ]; then
  win=$(xdotool search --name Bendoom | head -1)
  for key in "$@"; do
    xdotool keydown --window "$win" "$key"
    sleep 0.5
    xdotool keyup --window "$win" "$key"
  done
  sleep 0.3
fi
niri msg action screenshot-window --id "$id" --write-to-disk true >/dev/null
sleep 0.5
ls -t ~/Pictures/Screenshots/*.png | head -1
wait || true
