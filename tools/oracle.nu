#!/usr/bin/env nu
# Diffs a frame of ours against vanilla's after the same commands from
# the same place. Writes a copy of the IWAD whose E1M1 has one thing, a
# player 1 start at x, y facing angle, and the command script as a
# vanilla demo: version 109, no monsters, four bytes a tic, then a tic
# whose buttons press pause, then a minute of idle tics, then the end
# marker. Chocolate
# Doom plays the demo in real time in a scratch directory, at screen
# size 10, on a headless X server of its own; a paused game runs no
# playsim tic but keeps reading the demo, so the tail holds the frame of
# the script's last tic for a minute, and one paletted screenshot is
# taken inside it. A shot counts once it shows the pause graphic. It is
# compared with the frame tools/frame.bend dumps after the same script,
# outside the status bar rows, the pause graphic, and the pistol: at
# rest where a script that never moves leaves it, widened by the bob's
# 16 units to either side and below for one that moves. The pistol
# rises for the level's first 16 tics, so a script is at least 18; the
# default idles 20.
#
# Needs chocolate-doom, Xvfb and xdotool (all in the dev shell) and the
# frame dump built. A script is runs a space apart, each
# "count,forward,side,turn,use" in a demo's units:
#
#   bend tools/frame.bend -o frame
#   tools/oracle.nu -416 256 0
#   tools/oracle.nu -416 256 0 "20,0,0,0,0 34,50,0,0,0" --frame ./frame --keep

source wad.nu

# An integer's low bytes, little-endian.
def le [width: int]: int -> binary {
  $in | into binary | bytes at 0..<$width
}

# The IWAD with E1M1's things one player 1 start on every skill: the
# thing added after the directory, and the THINGS entry's position and
# size pointed at it. A whole IWAD and not a PWAD, since Doom refuses
# -file with the shareware one.
def start-iwad [wad: binary, x: int, y: int, angle: int]: nothing -> binary {
  let all = $wad | lumps | enumerate | flatten
  let marker = $all | where name == "E1M1" | first | get index
  let map = $all | where index > $marker | first 10
  let things = $map | where name == "THINGS" | first
  let entry = ($wad | bytes at 8..11 | into int --endian little) + $things.index * 16
  let thing = [($x | le 2) ($y | le 2) ($angle | le 2) (1 | le 2) (7 | le 2)] | bytes collect
  [($wad | bytes at 0..<$entry) ($wad | bytes length | le 4) (10 | le 4) ($wad | bytes at ($entry + 8)..) $thing]
  | bytes collect
}

# A script's runs: how many tics, and the four bytes a demo keeps of the
# tic's command (G_ReadDemoTiccmd: forward, side, the turn's high byte,
# the buttons, where use is bit 1).
def runs []: string -> table<tics: int, bytes: binary> {
  $in | split row ' ' | each {|run|
    let f = $run | split row ',' | into int
    {tics: $f.0, bytes: ([($f.1 | le 1) ($f.2 | le 1) ($f.3 | le 1) ($f.4 * 2 | le 1)] | bytes collect)}
  }
}

# The script as a version 109 demo: the 13-byte header (skill 1, E1M1,
# no deathmatch, respawn or fast, no monsters, console player 0, player
# 1 alone in the game), the tics, a tic pressing pause (BT_SPECIAL with
# BTS_PAUSE), 2100 idle tics, and the 0x80 that ends a demo.
def demo []: table<tics: int, bytes: binary> -> binary {
  let tics = $in | each {|run| 0..<$run.tics | each { $run.bytes } } | flatten
  [0x[6d 00 01 01 00 00 00 01 00 01 00 00 00]]
  | append $tics
  | append 0x[00 00 00 81]
  | append (0..<2100 | each { 0x[00 00 00 00] })
  | append 0x[80]
  | bytes collect
}

# The palette indices of a Chocolate Doom screenshot, row by row. It
# writes every byte of 0xc0 and over as 0xc1 then the byte, and no other
# runs, so dropping each marker left to right decodes it.
def pcx-indices []: binary -> list<string> {
  let pcx = $in
  $pcx | bytes at 128..<(($pcx | bytes length) - 769) | encode hex | str lowercase
  | str replace --all --regex '(..)' '$1 '
  | str replace --all --regex 'c1 (..)' '$1'
  | str trim | split row ' '
}

# The posts of the patch column whose first is at the offset piped in:
# each one's first row in the patch, its length, and where its pixels
# start, up to the column's 255.
def posts [wad: binary]: int -> table<delta: int, length: int, pixels: int> {
  let first = $in
  generate {|at|
    let delta = $wad | bytes at $at..$at | into int
    if $delta != 255 {
      let length = $wad | bytes at ($at + 1)..($at + 1) | into int
      {out: {delta: $delta, length: $length, pixels: ($at + 3)}, next: ($at + $length + 4)}
    }
  } $first
}

# The pixels a patch covers when drawn at x, y, its offsets taken off as
# V_DrawPatch takes them: each one's frame index and colour.
def patch-pixels [wad: binary, name: string, x: int, y: int]: nothing -> table<at: int, colour: string> {
  let patch = $wad | lumps | where name == $name | last | get pos
  let width = $wad | bytes at $patch..($patch + 1) | into int --endian little
  let left = $x - ($wad | bytes at ($patch + 4)..($patch + 5) | into int --endian little --signed)
  let top = $y - ($wad | bytes at ($patch + 6)..($patch + 7) | into int --endian little --signed)
  0..<$width | each {|c|
    $patch + ($wad | bytes at ($patch + 8 + $c * 4)..($patch + 11 + $c * 4) | into int --endian little)
    | posts $wad
    | each {|post| 0..<$post.length | each {|k| {
        at: (($top + $post.delta + $k) * 320 + $left + $c)
        colour: ($wad | bytes at ($post.pixels + $k)..($post.pixels + $k) | encode hex | str lowercase)
      } } }
  } | flatten | flatten
}

# The pixels the pistol may cover, as frame indices. Doom draws a weapon
# sprite at scale one, its left at column 1 and its top at row 32 of a
# 200-row screen whose centre row 100.5 sits on the view's 84, so row
# 15.5 of the view, first row drawn 16, less the sprite's offsets. The
# bob moves it up to 16 columns either way and up to 16 rows down.
def pistol-mask [wad: binary, bobbing: bool]: nothing -> list<int> {
  let reach = if $bobbing { 16 } else { 0 }
  patch-pixels $wad PISGA0 1 16 | get at | where $it < 168 * 320 | each {|at|
    (0 - $reach)..$reach | each {|dx| 0..$reach | each {|dy| $at + $dy * 320 + $dx } }
  } | flatten | flatten | uniq | where $it < 168 * 320
}

# Chocolate Doom's frame after the demo's script, paused. It can only
# take a screenshot while it runs, so it runs on an X server of its own
# with no screen, Xvfb, where nothing shows on the desktop and no window
# takes the focus; the server picks its display number and writes it
# out, so runs side by side never share one. Once the script has had
# its time, xdotool presses the screenshot key until a shot shows the
# pause graphic whole, which is the frame the pause froze. The config
# sets screen size 10, the full 320 by 168 view over the status bar that
# Bendoom draws (Doom's default 9 borders a 288 by 144 view), and turns
# messages off.
def vanilla [iwad: binary, name: string, script: binary, tics: int, pause: table<at: int, colour: string>, dir: path]: nothing -> list<string> {
  $iwad | save --force ($dir | path join $name)
  $script | save --force ($dir | path join script.lmp)
  "screenblocks 10\nshow_messages 0\n" | save --force ($dir | path join default.cfg)
  let server = job spawn { ^Xvfb -displayfd 1 -screen 0 1024x768x24 o> ($dir | path join display) }
  sleep 1sec
  let display = $":(open --raw ($dir | path join display) | str trim)"
  let game = job spawn {
    cd $dir
    with-env {HOME: $dir, DISPLAY: $display} {
      ^chocolate-doom -iwad $name -playdemo script -config default.cfg -devparm -window -nosound | ignore
    }
  }
  let shot = try { with-env {DISPLAY: $display} {
    let opened = 0..<150 | each {|_| sleep 200ms; ^xdotool search --name "Chocolate Doom" | complete | get stdout | lines }
      | where ($it | is-not-empty) | first 1 | flatten
    if ($opened | is-empty) { error make {msg: "Chocolate Doom's window did not open"} }
    sleep (($tics * 1000 / 35 | into int) * 1ms + 2sec)
    0..<40 | each {|n|
      let target = ^xdotool search --name "Chocolate Doom" | lines | last
      ^xdotool keydown --window $target F1
      sleep 30ms
      ^xdotool keyup --window $target F1
      sleep 400ms
      let file = $dir | path join $"DOOM($n | fill --alignment right --character '0' --width 2).pcx"
      if ($file | path exists) { open --raw $file | pcx-indices } else { [] }
    } | where {|shot| ($shot | is-not-empty) and ($pause | all {|p| ($shot | get $p.at) == $p.colour }) } | first 1
  } } finally {
    job kill $game
    job kill $server
  }
  if ($shot | is-empty) { error make {msg: "no screenshot showed the pause graphic"} }
  $shot | first
}

def main [
  x: int                                   # the start's x, in map units
  y: int                                   # the start's y
  angle: int                               # its facing in degrees, a multiple of 45
  script: string = "20,0,0,0,0"            # the commands, runs of "count,forward,side,turn,use"
  --wad: path                              # the IWAD (default $env.BENDOOM_IWAD)
  --frame: path = ./frame                  # the frame dump, built from tools/frame.bend
  --keep                                   # keep the scratch directory
]: nothing -> record {
  hide-env --ignore-errors LD_LIBRARY_PATH
  let wad = $wad | default $env.BENDOOM_IWAD
  let bytes = open --raw $wad
  let runs = $script | runs
  let tics = $runs | get tics | math sum
  if $tics < 18 { error make {msg: "the pistol is still rising before tic 18"} }
  let pause = patch-pixels $bytes M_PAUSE 126 4
  let dir = mktemp --directory
  let shot = vanilla (start-iwad $bytes $x $y $angle) ($wad | path basename) ($runs | demo) $tics $pause $dir
  let ours = with-env {BENDOOM_IWAD: $wad, FRAME: $"($x) ($y) ($angle)", SCRIPT: $script} { ^$frame }
    | lines | each {|row| $row | str replace --all --regex '(..)' '$1 ' | str trim | split row ' ' } | flatten
  let moves = $runs | any {|run| ($run.bytes | bytes at 0..1) != 0x[00 00] }
  let masked = pistol-mask $bytes $moves | append ($pause | get at)
  let differing = 0..<(168 * 320) | where {|i| ($shot | get $i) != ($ours | get $i) } | where $it not-in $masked
  if not $keep { rm --recursive $dir }
  {
    place: $"($x) ($y) ($angle)"
    script: $script
    differing: ($differing | length)
    masked: ($masked | uniq | where $it < 168 * 320 | length)
    first: ($differing | first 5 | each {|i| {x: ($i mod 320), y: ($i // 320), vanilla: ($shot | get $i), ours: ($ours | get $i)} })
    scratch: (if $keep { $dir } else { null })
  }
}
