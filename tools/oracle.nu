#!/usr/bin/env nu
# Diffs a frame of ours against vanilla's after the same commands from
# the same place. Writes a copy of the IWAD whose E1M1 has player 1
# start at x, y facing angle, the records --things names rewritten and
# its other things as they are, and the command script as a vanilla
# demo (tools/demo.nu) with no monsters, so none spawns, then a tic
# whose buttons press pause (BT_SPECIAL with BTS_PAUSE), then a minute
# of idle tics. Chocolate Doom plays the demo in real time in a scratch
# directory, at screen size 10, on a headless X server of its own; a
# paused game runs no playsim tic but keeps reading the demo, so the
# tail holds the frame of the script's last tic for a minute, and one
# paletted screenshot is taken inside it. A shot counts once it shows
# the pause graphic. It is compared with the frame
# tools/frame.bend dumps from the same copy after the same script,
# outside the status bar rows and the pause graphic. The default script
# idles 20 tics, past the pistol's rise.
#
# --tally compares the tally the exit leads to instead. Its script takes
# the exit and then idles long enough for WI_updateStats to settle,
# after which the screen stands still until a press, so no pause tic is
# written: its buttons byte carries BT_ATTACK, which WI_checkForAccelerate
# would read as that press. A shot counts once it shows "Finished!"
# where WI_drawLF puts it, all 200 rows are compared, and the ten
# animations of WIMAP0 are masked, since they keep turning on the
# wall clock while the shot is taken.
#
# Needs chocolate-doom, Xvfb and xdotool (all in the dev shell) and the
# frame dump built. A script is runs a space apart, each
# "count,forward,side,turn,use" in a demo's units:
#
#   bend tools/frame.bend -o frame
#   tools/oracle.nu -416 256 0
#   tools/oracle.nu -416 256 0 "20,0,0,0,0 34,50,0,0,0" --frame ./frame --keep
#   tools/oracle.nu 832 384 90 "40,25,0,0,0 1,0,0,0,1" --things "35,2035,800,528"
#   tools/oracle.nu -224 1340 90 "5,0,0,0,0 1,0,0,0,1 1,0,0,96,0 12,25,0,0,0 1,0,0,224,0 20,25,0,0,0 10,0,0,0,0 1,0,0,0,1 250,0,0,0,0" --tally

source demo.nu

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

# A patch's size and where its offsets put it when drawn at x, y.
def patch-box [wad: binary, name: string, x: int, y: int]: nothing -> list<int> {
  let patch = $wad | lumps | where name == $name | last | get pos
  let width = $wad | bytes at $patch..($patch + 1) | into int --endian little
  let height = $wad | bytes at ($patch + 2)..($patch + 3) | into int --endian little
  let left = $x - ($wad | bytes at ($patch + 4)..($patch + 5) | into int --endian little --signed)
  let top = $y - ($wad | bytes at ($patch + 6)..($patch + 7) | into int --endian little --signed)
  0..<$height | each {|r| 0..<$width | each {|c| (($top + $r) * 320 + $left + $c) } } | flatten
}

# wi_stuff.c's epsd0animinfo: where each of WIMAP0's ten animations is
# drawn, three frames apiece.
const anims = [[224 104] [184 160] [112 136] [72 112] [88 96] [64 48] [192 40] [136 16] [80 16] [64 24]]

# Every pixel those animations can cover, which the tally's comparison
# leaves out.
def anim-boxes [wad: binary]: nothing -> list<int> {
  $anims | enumerate | each {|a|
    0..<3 | each {|i| patch-box $wad $"WIA00($a.index)0($i)" ($a.item | get 0) ($a.item | get 1) }
  } | flatten | flatten | uniq
}

# WI_drawLF's "Finished!", centred under the level's name: the pixels
# that say the tally is showing its counts.
def finished [wad: binary]: nothing -> table<at: int, colour: string> {
  let name = $wad | lumps | where name == "WILV00" | last | get pos
  let f = $wad | lumps | where name == "WIF" | last | get pos
  let height = $wad | bytes at ($name + 2)..($name + 3) | into int --endian little
  let width = $wad | bytes at $f..($f + 1) | into int --endian little
  patch-pixels $wad WIF ((320 - $width) // 2) (2 + 5 * $height // 4)
}

# Chocolate Doom's frame after the demo's script, paused. It can only
# take a screenshot while it runs, so it runs on an X server of its own
# with no screen, Xvfb, where nothing shows on the desktop and no window
# takes the focus; the server picks its display number and writes it
# out, so runs side by side never share one. Once the script has had
# its time, xdotool presses the screenshot key until a shot shows the
# patch that tells the frame is the one wanted whole: the pause graphic
# the pause froze, or the tally's "Finished!". The config
# sets screen size 10, the full 320 by 168 view over the status bar that
# Bendoom draws (Doom's default 9 borders a 288 by 144 view), and turns
# messages off.
def vanilla [iwad: binary, name: string, script: binary, tics: int, told: table<at: int, colour: string>, dir: path]: nothing -> list<string> {
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
    } | where {|shot| ($shot | is-not-empty) and ($told | all {|p| ($shot | get $p.at) == $p.colour }) } | first 1
  } } finally {
    job kill $game
    job kill $server
  }
  if ($shot | is-empty) { error make {msg: "no screenshot showed the patch asked for"} }
  $shot | first
}

def main [
  x: int                                   # the start's x, in map units
  y: int                                   # the start's y
  angle: int                               # its facing in degrees, a multiple of 45
  script: string = "20,0,0,0,0"            # the commands, runs of "count,forward,side,turn,use"
  --wad: path                              # the IWAD (default $env.BENDOOM_IWAD)
  --things: string = ""                    # records to rewrite, each "record,type,x,y", facing 0
  --frame: path = ./frame                  # the frame dump, built from tools/frame.bend
  --tally                                  # the script takes the exit: compare the tally, all 200 rows
  --keep                                   # keep the scratch directory
]: nothing -> record {
  hide-env --ignore-errors LD_LIBRARY_PATH
  let wad = $wad | default $env.BENDOOM_IWAD
  let bytes = open --raw $wad
  let runs = $script | runs
  let tics = $runs | get tics | math sum
  let rows = if $tally { 200 } else { 168 }
  let told = if $tally { finished $bytes } else { patch-pixels $bytes M_PAUSE 126 4 }
  let masked = if $tally { anim-boxes $bytes } else { $told | get at }
  let dir = mktemp --directory
  let name = $wad | path basename
  let tail = if $tally { [{tics: 2100, bytes: 0x[00 00 00 00]}] } else {
    [{tics: 1, bytes: 0x[00 00 00 81]} {tics: 2100, bytes: 0x[00 00 00 00]}] }
  let shot = vanilla ($bytes | placed $x $y $angle $things) $name ($runs | append $tail | demo) $tics $told $dir
  let ours = with-env {BENDOOM_IWAD: ($dir | path join $name), FRAME: $"($x) ($y) ($angle)", SCRIPT: $script} { ^$frame }
    | lines | each {|row| $row | str replace --all --regex '(..)' '$1 ' | str trim | split row ' ' } | flatten
  let differing = 0..<($rows * 320) | where {|i| ($shot | get $i) != ($ours | get $i) } | where $it not-in $masked
  if not $keep { rm --recursive $dir }
  {
    place: $"($x) ($y) ($angle)"
    script: $script
    differing: ($differing | length)
    masked: ($masked | uniq | where $it < $rows * 320 | length)
    first: ($differing | first 5 | each {|i| {x: ($i mod 320), y: ($i // 320), vanilla: ($shot | get $i), ours: ($ours | get $i)} })
    scratch: (if $keep { $dir } else { null })
  }
}
