#!/usr/bin/env bash
set -euo pipefail

scratch=$(mktemp -d)
display_pid=
game_pid=
capture_pid=
sink_module=
cleanup() {
  if [ -n "$game_pid" ]; then kill "$game_pid" 2>/dev/null || true; fi
  if [ -n "$display_pid" ]; then kill "$display_pid" 2>/dev/null || true; fi
  if [ -n "$capture_pid" ]; then kill "$capture_pid" 2>/dev/null || true; fi
  if [ -n "$sink_module" ]; then pactl unload-module "$sink_module"; fi
  rm -r -- "$scratch"
}
trap cleanup EXIT
mkdir "$scratch/game"
tar -xzf "$1" -C "$scratch/game"
printf 'pcm.!default { type null }\n' > "$scratch/alsa.conf"
case "${BENDOOM_SMOKE_AUDIO:-null}" in
  pulse|pipewire)
    sink_name=bendoom_smoke_$$
    sink_module=$(pactl load-module module-null-sink sink_name="$sink_name" rate=44100 channels=2)
    if [ "$BENDOOM_SMOKE_AUDIO" = pipewire ]; then
      printf 'pcm.!default { type pipewire playback_node "%s" }\n' "$sink_name" > "$scratch/alsa.conf"
    else
      printf 'pcm.!default { type pulse device "%s" }\n' "$sink_name" > "$scratch/alsa.conf"
    fi
    parec --device="$sink_name.monitor" --raw --format=s16le --rate=44100 --channels=2 --latency-msec=10 > "$scratch/audio.raw" &
    capture_pid=$!
    ;;
  null) ;;
  *) echo 'BENDOOM_SMOKE_AUDIO must be null, pulse or pipewire.' >&2; exit 1 ;;
esac
Xvfb -displayfd 3 -screen 0 1280x960x24 3>"$scratch/display" >"$scratch/xvfb.log" 2>&1 &
display_pid=$!
for ((attempt = 0; attempt < 100; attempt++)); do
  [ -s "$scratch/display" ] && break
  sleep .1
done
DISPLAY=":$(cat "$scratch/display")"
export DISPLAY
unset WAYLAND_DISPLAY BENDOOM_IWAD BENDOOM_MUSIC BENDOOM_SOUNDS ALSA_PLUGIN_DIR
bwrap --ro-bind / / --dev-bind /dev /dev --proc /proc --tmpfs /nix \
  --bind "$scratch" "$scratch" --die-with-parent \
  --setenv ALSA_CONFIG_PATH "$scratch/alsa.conf" \
  --setenv RECORD "$scratch/run.lmp" \
  "$scratch/game/bendoom" >"$scratch/game.log" 2>&1 &
game_pid=$!
window=
for ((attempt = 0; attempt < 200; attempt++)); do
  window=$(xdotool search --onlyvisible --name '^Bendoom$' 2>/dev/null | head -1) || true
  [ -n "$window" ] && break
  if ! kill -0 "$game_pid" 2>/dev/null; then cat "$scratch/game.log"; exit 1; fi
  sleep .1
done
[ -n "$window" ] || { cat "$scratch/game.log"; exit 1; }
xdotool windowfocus --sync "$window"
xdotool keydown --window "$window" Up
sleep 1
xdotool keyup --window "$window" Up
xdotool key --window "$window" Escape
wait "$game_pid"
game_pid=
if [ -n "$capture_pid" ]; then
  kill "$capture_pid"
  wait "$capture_pid" || true
  capture_pid=
  if ! od -An -tu2 "$scratch/audio.raw" | awk '{ for (i = 1; i <= NF; i++) if ($i + 0 != 0) heard = 1 } END { exit !heard }'; then
    cat "$scratch/game.log"
    echo "No audio reached the private sink ($(wc -c < "$scratch/audio.raw") bytes captured)." >&2
    exit 1
  fi
  echo "PASS ${BENDOOM_SMOKE_AUDIO} audio: nonzero PCM from the private sink"
fi
bytes=$(wc -c < "$scratch/run.lmp")
first=$(od -An -tu1 -N1 "$scratch/run.lmp" | tr -d ' ')
last=$(tail -c 1 "$scratch/run.lmp" | od -An -tu1 | tr -d ' ')
[ "$first" = 109 ] && [ "$last" = 128 ] && [ "$bytes" -gt 14 ] && [ "$(( (bytes - 14) % 4 ))" = 0 ]
echo "PASS without /nix: window, assets, movement, recording and clean exit ($bytes demo bytes)"
