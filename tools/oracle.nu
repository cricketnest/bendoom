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
# tools/frame.bend dumps from the same copy after the same script, over
# all 200 rows but for the pause graphic and the box the marine's face
# covers: the status bar's ticker runs on while the playsim is paused,
# so the face keeps changing under the screenshot. The default script
# idles 20 tics, past the pistol's rise.
#
# Needs chocolate-doom, Xvfb and xdotool (all in the dev shell) and the
# frame dump built. A script is runs a space apart, each
# "count,forward,side,turn,use" in a demo's units:
#
#   bend tools/frame.bend -o frame
#   tools/oracle.nu -416 256 0
#   tools/oracle.nu -416 256 0 "20,0,0,0,0 34,50,0,0,0" --frame ./frame --keep
#   tools/oracle.nu 832 384 90 "40,25,0,0,0 1,0,0,0,1" --things "35,2035,800,528"

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

# Every frame pixel the marine's face can cover: the box around the
# places ST_loadGraphics' 42 face patches take at the face widget's
# ST_FACESX and ST_FACESY, each less its own offsets.
def face-box [wad: binary]: nothing -> list<int> {
  let names = ((0..4 | each {|i| [$"STFST($i)0", $"STFST($i)1", $"STFST($i)2", $"STFTR($i)0", $"STFTL($i)0",
    $"STFOUCH($i)", $"STFEVL($i)", $"STFKILL($i)"] } | flatten) ++ ["STFGOD0", "STFDEAD0"])
  let boxes = $names | each {|n|
    let found = $wad | lumps | where name == $n
    if ($found | is-empty) { null } else {
      let patch = $found | last | get pos
      let left = 143 - ($wad | bytes at ($patch + 4)..($patch + 5) | into int --endian little --signed)
      let top = 168 - ($wad | bytes at ($patch + 6)..($patch + 7) | into int --endian little --signed)
      {left: $left, top: $top
       right: ($left + ($wad | bytes at $patch..($patch + 1) | into int --endian little) - 1)
       bottom: ($top + ($wad | bytes at ($patch + 2)..($patch + 3) | into int --endian little) - 1)}
    }
  } | compact
  let top = $boxes | get top | math min
  let bottom = $boxes | get bottom | math max
  let left = $boxes | get left | math min
  let right = $boxes | get right | math max
  $top..$bottom | each {|row| $left..$right | each {|col| $row * 320 + $col } } | flatten
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
# messages off; the extra config binds F1, scancode 59, to the
# screenshot, since -devparm, which binds it too, writes its frame-rate
# dots over the bar's last row.
def vanilla [iwad: binary, name: string, script: binary, tics: int, pause: table<at: int, colour: string>, dir: path]: nothing -> list<string> {
  $iwad | save --force ($dir | path join $name)
  $script | save --force ($dir | path join script.lmp)
  "screenblocks 10\nshow_messages 0\n" | save --force ($dir | path join default.cfg)
  "key_menu_screenshot 59\n" | save --force ($dir | path join extra.cfg)
  let server = job spawn { ^Xvfb -displayfd 1 -screen 0 1024x768x24 o> ($dir | path join display) }
  sleep 1sec
  let display = $":(open --raw ($dir | path join display) | str trim)"
  let game = job spawn {
    cd $dir
    with-env {HOME: $dir, DISPLAY: $display} {
      ^chocolate-doom -iwad $name -playdemo script -config default.cfg -extraconfig extra.cfg -window -nosound | ignore
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
  --things: string = ""                    # records to rewrite, each "record,type,x,y", facing 0
  --frame: path = ./frame                  # the frame dump, built from tools/frame.bend
  --keep                                   # keep the scratch directory
]: nothing -> record {
  hide-env --ignore-errors LD_LIBRARY_PATH
  let wad = $wad | default $env.BENDOOM_IWAD
  let bytes = open --raw $wad
  let runs = $script | runs
  let tics = $runs | get tics | math sum
  let pause = patch-pixels $bytes M_PAUSE 126 4
  let dir = mktemp --directory
  let name = $wad | path basename
  let paused = $runs | append [{tics: 1, bytes: 0x[00 00 00 81]} {tics: 2100, bytes: 0x[00 00 00 00]}] | demo
  let shot = vanilla ($bytes | placed $x $y $angle $things) $name $paused $tics $pause $dir
  let ours = with-env {BENDOOM_IWAD: ($dir | path join $name), FRAME: $"($x) ($y) ($angle)", SCRIPT: $script} { ^$frame }
    | lines | each {|row| $row | str replace --all --regex '(..)' '$1 ' | str trim | split row ' ' } | flatten
  let masked = ($pause | get at) ++ (face-box $bytes)
  let differing = 0..<(200 * 320) | where {|i| ($shot | get $i) != ($ours | get $i) } | where $it not-in $masked
  if not $keep { rm --recursive $dir }
  {
    place: $"($x) ($y) ($angle)"
    script: $script
    differing: ($differing | length)
    masked: ($masked | uniq | where $it < 200 * 320 | length)
    first: ($differing | first 5 | each {|i| {x: ($i mod 320), y: ($i // 320), vanilla: ($shot | get $i), ours: ($ours | get $i)} })
    scratch: (if $keep { $dir } else { null })
  }
}
