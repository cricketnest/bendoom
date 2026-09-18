#!/usr/bin/env nu
# Diffs a frame of ours against vanilla's at the same place. Writes a
# PWAD of E1M1 whose things are one player 1 start at x, y facing angle
# and whose sectors and lines have no specials (so no light blinks and
# no wall scrolls; Bendoom reads neither yet), runs Chocolate Doom on it
# in a scratch directory at screen size 10, waits for the pistol to
# finish rising, takes its paletted screenshot eight times about 0.2 s
# apart, and compares the first settled one with the frame tools/frame.bend dumps,
# outside the status bar rows and the pixels the resting pistol covers.
# Pixels that differ among Chocolate Doom's own shots are its animated
# textures and flats, which Bendoom does not animate yet, and are
# counted apart. An animation changes frame every 8 tics, 0.23 s, and
# none has more than four frames, so the shots see every frame of every
# cycle; Bendoom draws the first frame, which is one of them, so a pixel
# of an animated surface that differs from ours differs among the shots
# too, and none leaks into the count.
#
# Needs chocolate-doom and xdotool (both in the dev shell), niri, and
# the frame dump built:
#
#   bend tools/frame.bend -o frame
#   tools/oracle.nu -416 256 0
#   tools/oracle.nu 137 256 45 --frame ./frame --keep

# A WAD's directory.
def lumps []: binary -> table<name: string, pos: int, size: int> {
  let wad = $in
  let count = $wad | bytes at 4..7 | into int --endian little
  let dir = $wad | bytes at 8..11 | into int --endian little
  0..<$count | each {|i|
    let at = $dir + $i * 16
    {
      name: ($wad | bytes at ($at + 8)..($at + 15) | decode utf-8 | str trim --char (char nul))
      pos: ($wad | bytes at $at..($at + 3) | into int --endian little)
      size: ($wad | bytes at ($at + 4)..($at + 7) | into int --endian little)
    }
  }
}

# An integer's low bytes, little-endian.
def le [width: int]: int -> binary {
  $in | into binary | bytes at 0..<$width
}

# A PWAD of the given lumps.
def pwad []: table<name: string, data: binary> -> binary {
  let entries = $in
  let sizes = $entries | each {|e| $e.data | bytes length }
  let starts = $sizes | reduce --fold [12] {|size, acc| $acc | append (($acc | last) + $size) }
  let directory = $entries | enumerate | each {|e|
    [
      ($starts | get $e.index | le 4)
      ($sizes | get $e.index | le 4)
      ([($e.item.name | into binary) 0x[00 00 00 00 00 00 00 00]] | bytes collect | bytes at 0..<8)
    ] | bytes collect
  }
  [("PWAD" | into binary) ($entries | length | le 4) ($starts | last | le 4)]
  | append ($entries | get data)
  | append $directory
  | bytes collect
}

# A lump of fixed-size records with two bytes of each zeroed.
def zeroed [size: int, at: int]: binary -> binary {
  $in | chunks $size | each {|r| [($r | bytes at 0..<$at) 0x[00 00] ($r | bytes at ($at + 2)..)] | bytes collect } | bytes collect
}

# E1M1 with one thing, player 1's start on every skill, and no line or
# sector specials.
def start-map [wad: binary, x: int, y: int, angle: int]: nothing -> binary {
  let all = $wad | lumps
  let marker = $all | enumerate | where item.name == "E1M1" | first | get index
  let thing = [($x | le 2) ($y | le 2) ($angle | le 2) (1 | le 2) (7 | le 2)] | bytes collect
  $all | skip $marker | first 11 | each {|l|
    let data = if $l.size == 0 { 0x[] } else { $wad | bytes at $l.pos..<($l.pos + $l.size) }
    {
      name: $l.name
      data: (match $l.name {
        "THINGS" => $thing
        "LINEDEFS" => ($data | zeroed 14 6)
        "SECTORS" => ($data | zeroed 26 22)
        _ => $data
      })
    }
  } | pwad
}

# The palette indices of a Chocolate Doom screenshot, row by row, as
# hex pairs a space apart. It
# writes every byte of 0xc0 and over as 0xc1 then the byte, and no other
# runs, so dropping each marker left to right decodes it.
def pcx-indices []: binary -> string {
  let pcx = $in
  $pcx | bytes at 128..<(($pcx | bytes length) - 769) | encode hex | str lowercase
  | str replace --all --regex '(..)' '$1 '
  | str replace --all --regex 'c1 (..)' '$1'
  | str trim
}

# The pixels the resting pistol covers, as frame indices: Doom draws a
# weapon sprite at scale one, its left at column 1 less its left offset,
# its top 100.5 rows above the view's centre row 84 and then 32 less its
# top offset below that: row 112.5 for an offset of -97, so the first
# row drawn is 113.
def pistol-mask [wad: binary]: nothing -> list<int> {
  let patch = $wad | lumps | where name == "PISGA0" | last | get pos
  let width = $wad | bytes at $patch..($patch + 1) | into int --endian little
  let left = $wad | bytes at ($patch + 4)..($patch + 5) | into int --endian little --signed
  let top = $wad | bytes at ($patch + 6)..($patch + 7) | into int --endian little --signed
  let first_row = 84 - 100 + 32 - $top
  0..<$width | each {|c|
    mut at = $patch + ($wad | bytes at ($patch + 8 + $c * 4)..($patch + 11 + $c * 4) | into int --endian little)
    mut pixels = []
    loop {
      let delta = $wad | bytes at $at..$at | into int
      if $delta == 255 { break }
      let length = $wad | bytes at ($at + 1)..($at + 1) | into int
      $pixels = $pixels | append (0..<$length | each {|k| ($first_row + $delta + $k) * 320 + 1 - $left + $c })
      $at = $at + $length + 4
    }
    $pixels
  } | flatten | where $it < 168 * 320
}

# The niri window whose title holds the text, once it opens.
def wait-window [title: string]: nothing -> record {
  let found = 0..<50
    | each {|_| sleep 200ms; niri msg --json windows | from json | where title =~ $title }
    | where ($it | is-not-empty) | first 1 | flatten
  if ($found | is-empty) { error make {msg: $"no window titled ($title) opened"} }
  $found | first
}

# Chocolate Doom's frame at the start the PWAD gives, eight times.
def vanilla [wad: path, map: binary, dir: path]: nothing -> list<string> {
  $map | save --force ($dir | path join start.wad)
  # Doom's default screen size 9 borders a 288 by 144 view; 10 is the
  # full 320 by 168 over the status bar, which is what Bendoom draws.
  # With messages off, no "screen shot" is written over the later shots.
  "screenblocks 10\nshow_messages 0\n" | save --force ($dir | path join default.cfg)
  let before = niri msg --json focused-window | from json
  job spawn {
    cd $dir
    with-env {HOME: $dir} {
      ^chocolate-doom -iwad $wad -file start.wad -config default.cfg -warp 1 1 -skill 1 -nomonsters -devparm -window -nosound | ignore
    }
  }
  let window = wait-window "Chocolate Doom"
  niri msg action focus-window --id $window.id
  sleep 4sec
  let target = ^xdotool search --name "Chocolate Doom" | lines | first
  # The first press after the focus change is swallowed, so F1 is
  # pressed until all eight shots exist.
  for _ in 0..<16 {
    if ($dir | path join DOOM07.pcx | path exists) { break }
    ^xdotool keydown --window $target F1
    sleep 30ms
    ^xdotool keyup --window $target F1
    sleep 140ms
  }
  kill $window.pid
  if $before != null { niri msg action focus-window --id $before.id }
  0..<8 | each {|n| open --raw ($dir | path join $"DOOM0($n).pcx") | pcx-indices }
}

# The left hundred columns of a frame's status bar rows.
def bar-left []: list<string> -> list<string> {
  $in | skip (168 * 320) | chunks 320 | each {|row| $row | first 100 } | flatten
}

def main [
  x: int                                   # the start's x, in map units
  y: int                                   # the start's y
  angle: int                               # its facing in degrees, a multiple of 45
  --wad: path                              # the IWAD (default $env.BENDOOM_IWAD)
  --frame: path = ./frame                  # the frame dump, built from tools/frame.bend
  --keep                                   # keep the scratch directory
]: nothing -> record {
  hide-env --ignore-errors LD_LIBRARY_PATH
  $env.DISPLAY = ($env.DISPLAY? | default ":1")
  let wad = $wad | default $env.BENDOOM_IWAD
  let bytes = open --raw $wad
  let dir = mktemp --directory
  # A shot taken while the screen wipe still ran shows it in the status
  # bar too, whose left hundred columns (the ammo and health, clear of
  # the face, which looks about) hold still afterwards: the shots before
  # they settle are dropped. Eight shots of a four-frame cycle repeat,
  # and the repeats are dropped.
  let taken = vanilla $wad (start-map $bytes $x $y $angle) $dir | each {|shot| $shot | split row ' ' }
  let settled = $taken | last | bar-left
  let shots = $taken | skip while {|shot| ($shot | bar-left) != $settled }
    | each {|shot| $shot | first (168 * 320) } | uniq
  let first = $shots | first
  let ours = with-env {BENDOOM_IWAD: $wad, FRAME: $"($x) ($y) ($angle)"} { ^$frame }
    | lines | each {|row| $row | str replace --all --regex '(..)' '$1 ' | str trim | split row ' ' } | flatten
  let masked = pistol-mask $bytes
  let animated = 0..<(168 * 320)
    | where {|i| $shots | skip 1 | any {|shot| ($shot | get $i) != ($first | get $i) } }
  let differing = 0..<(168 * 320) | where {|i| ($first | get $i) != ($ours | get $i) } | where $it not-in $masked
  if not $keep { rm --recursive $dir }
  {
    place: $"($x) ($y) ($angle)"
    differing: ($differing | where $it not-in $animated | length)
    animated: ($differing | where $it in $animated | length)
    pistol: ($masked | length)
    first: ($differing | where $it not-in $animated | first 5 | each {|i| {x: ($i mod 320), y: ($i // 320), vanilla: ($first | get $i), ours: ($ours | get $i)} })
    scratch: (if $keep { $dir } else { null })
  }
}
