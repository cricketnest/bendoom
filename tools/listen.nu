#!/usr/bin/env nu
# Records Chocolate Doom's music. Chocolate Doom plays E1M1 on the given
# IWAD with no monsters and no sound effects, at its default music
# settings, written to a scratch config: the OPL device, 44100 Hz,
# volume 8, no snd_dmxoption. SDL's dummy video driver draws nothing,
# and SDL's disk audio driver writes the music to a file in place of a
# sound card. The capture holds the given length of audio after the
# first note, at least two passes: Freedoom's song is about 130.6 s a
# pass, the shareware one 96.0 s. The report gives the capture's
# format, its frames, the lead (the frames before the first sample other
# than zero) and the frames whose left and right differ.
#
# The nixpkgs build runs on sdl2-compat over SDL3, whose disk driver
# reads SDL_AUDIO_DRIVER=disk, SDL_AUDIO_DISK_OUTPUT_FILE and
# SDL_AUDIO_DISK_TIMESCALE. SDL2's SDL_AUDIODRIVER and SDL_DISKAUDIOFILE
# work too, but SDL_DISKAUDIODELAY is ignored. The driver logs the
# format it writes, which the capture is checked against. Timescale 1
# keeps real time; 0 runs about 45 times faster, but the song's start
# then lands on another buffer, and I_OPL_PlaySong schedules the tracks
# without OPL_Lock, so the audio thread spinning beside it may start
# them apart. Chocolate Doom writes the song to $TMPDIR/doom.mid, so
# runs side by side each get their own.
#
# Needs chocolate-doom (in the dev shell):
#
#   tools/listen.nu
#   tools/listen.nu --wad doom1.wad --length 200sec --keep
#   tools/listen.nu compare a/music.raw b/music.raw

# The first frame of a capture with a sample other than zero, or null.
def lead []: binary -> any {
  $in | chunks 4 | enumerate | where ($it.item | into int) != 0 | first 1 | get index.0?
}

def main [
  --wad: path                   # the IWAD (default $env.BENDOOM_IWAD)
  --length: duration = 270sec   # audio to record after the first note
  --keep                        # keep the scratch directory and the capture
]: nothing -> record {
  hide-env --ignore-errors LD_LIBRARY_PATH
  let wad = $wad | default $env.BENDOOM_IWAD | path expand
  let frames = $length / 1sec * 44100 | into int
  let dir = mktemp --directory
  let capture = $dir | path join music.raw
  "snd_musicdevice 3\nmusic_volume 8\n" | save ($dir | path join default.cfg)
  "snd_samplerate 44100\nsnd_dmxoption \"\"\n" | save ($dir | path join chocolate-doom.cfg)
  let sdl = {
    HOME: $dir, TMPDIR: $dir, SDL_VIDEO_DRIVER: dummy, SDL_AUDIO_DRIVER: disk
    SDL_AUDIO_DISK_OUTPUT_FILE: $capture, SDL_AUDIO_DISK_TIMESCALE: 1
  }
  let game = job spawn {
    cd $dir
    with-env $sdl {
      ^chocolate-doom -iwad $wad -config default.cfg -extraconfig chocolate-doom.cfg -warp 1 1 -nomonsters -nosfx e> ($dir | path join stderr) | ignore
    }
  }
  try {
    loop {
      sleep 1sec
      if $game not-in (job list | get id) { error make {msg: "Chocolate Doom stopped"} }
      let bytes = if ($capture | path exists) { ls $capture | get 0.size | into int } else { 0 }
      let first = if $bytes > 0 { open --raw $capture | lead }
      if $first == null and $bytes > 10 * 44100 * 4 { error make {msg: "no note in the capture's first 10 s"} }
      if $first != null and $bytes >= ($first + $frames) * 4 { break }
    }
  } finally {
    job kill $game
  }
  let spec = open ($dir | path join stderr) | parse --regex 'format=(?<format>\w+) channels=(?<channels>\d+) freq=(?<freq>\d+)' | first
  if $spec != {format: S16LE, channels: "2", freq: "44100"} {
    error make {msg: $"the disk driver wrote ($spec.format), ($spec.channels) channels at ($spec.freq) Hz"}
  }
  let audio = open --raw $capture
  let report = {
    format: $"($spec.format), ($spec.channels) channels, ($spec.freq) Hz"
    frames: (($audio | bytes length) // 4)
    lead: ($audio | lead)
    sides_differ: ($audio | chunks 4 | where {|f| ($f | bytes at 0..1) != ($f | bytes at 2..3) } | length)
    capture: (if $keep { $capture } else { null })
  }
  if not $keep { rm --recursive $dir }
  $report
}

# A capture's 16-bit samples, left and right in turn.
def samples []: binary -> list<int> {
  $in | chunks 2 | each { into int --endian little --signed }
}

# A capture from its first note.
def from-lead []: binary -> binary {
  let audio = $in
  $audio | bytes at (($audio | lead) * 4)..
}

# Two captures from their first notes, over the shorter: how many
# samples differ and by how much at most, both sides counted.
def "main compare" [a: path, b: path]: nothing -> record {
  let a = open --raw $a | from-lead
  let b = open --raw $b | from-lead
  let end = [($a | bytes length) ($b | bytes length)] | math min | $in // 4 * 4
  let block = 4096
  let differences = seq 0 $block ($end - 1) | each {|at|
    let x = $a | bytes at $at..<([($at + $block) $end] | math min)
    let y = $b | bytes at $at..<([($at + $block) $end] | math min)
    if $x != $y { $x | samples | zip ($y | samples) | each {|p| $p.0 - $p.1 | math abs } | where $it != 0 }
  } | flatten
  {frames: ($end // 4), differing: ($differences | length), largest: ($differences | append 0 | math max)}
}
