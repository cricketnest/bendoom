#!/usr/bin/env nu
# Diffs a frame of ours against vanilla's after the same commands from
# the same place. Writes a copy of the IWAD whose E1M1 has player 1
# start at x, y facing angle, the records --things names rewritten and
# its other things as they are, and the command script as a vanilla
# demo (tools/demo.nu), then a tic whose buttons press pause
# (BT_SPECIAL with BTS_PAUSE), then a minute of idle tics. Chocolate
# Doom plays the demo in real time in a scratch directory, at screen
# size 10, on a headless X server of its own; a paused game runs no
# playsim tic but keeps reading the demo, so the tail holds the frame of
# the script's last tic for a minute, and one paletted screenshot is
# taken inside it. A shot counts once it shows the pause graphic. It is
# compared with the frame tools/frame.bend dumps from the same copy
# after the same script, over all 200 rows but for the pause graphic and
# the box the marine's face covers: the status bar's ticker runs on
# while the playsim is paused, so the face keeps changing under the
# screenshot. The report counts that box separately, as `face`, which is
# 0 only where the face holds still under the pause, as the dead one
# does. The default script idles 20 tics, past the pistol's rise.
# Both games wake a monster that sees the player on the same tic, but
# vanilla's chases from that tic and Bendoom's stands until milestone
# 6's ticket 16, so a place compares the two only while no monster has
# seen the player.
#
# The tint is outside the comparison. ST_doPaletteStuff leaves
# I_VideoBuffer alone and only sets the hardware palette, and
# V_ScreenShot hands WritePCXfile the start of the PLAYPAL lump, so a
# screenshot's 768 bytes of palette are PLAYPAL's first whatever the
# view is tinted with. The report says so as `shot_plain`, names the
# palette the dump's first line carries as `palette`, and compares the
# indices under it, which the tint never moves.
#
# Needs chocolate-doom, Xvfb and xdotool (all in the dev shell) and the
# frame dump built. A script is runs a space apart, each
# "count,forward,side,turn,buttons" (tools/demo.nu):
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

# The 768 bytes of palette a screenshot carries, after its 0x0c marker.
def pcx-palette []: binary -> string {
  let pcx = $in
  $pcx | bytes at (($pcx | bytes length) - 768).. | encode hex | str lowercase
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
def vanilla [iwad: binary, name: string, script: binary, tics: int, pause: table<at: int, colour: string>, dir: path]: nothing -> record<indices: list<string>, palette: string> {
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
      if ($file | path exists) {
        let pcx = open --raw $file
        {indices: ($pcx | pcx-indices), palette: ($pcx | pcx-palette)}
      } else { {indices: [], palette: ""} }
    } | where {|shot| ($shot.indices | is-not-empty) and ($pause | all {|p| ($shot.indices | get $p.at) == $p.colour }) } | first 1
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
  script: string = "20,0,0,0,0"            # the commands, runs of "count,forward,side,turn,buttons"
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
  let dump = with-env {BENDOOM_IWAD: ($dir | path join $name), FRAME: $"($x) ($y) ($angle)", SCRIPT: $script} { ^$frame }
    | lines
  let ours = $dump | skip 1
    | each {|row| $row | str replace --all --regex '(..)' '$1 ' | str trim | split row ' ' } | flatten
  let playpal = $bytes | lumps | where name == "PLAYPAL" | last | get pos
  let box = face-box $bytes
  let masked = ($pause | get at) ++ $box
  let off = 0..<(200 * 320) | where {|i| ($shot.indices | get $i) != ($ours | get $i) }
  let differing = $off | where $it not-in $masked
  if not $keep { rm --recursive $dir }
  {
    place: $"($x) ($y) ($angle)"
    script: $script
    differing: ($differing | length)
    face: ($off | where $it in $box | length)
    masked: ($masked | uniq | where $it < 200 * 320 | length)
    palette: ($"0x($dump | first)" | into int)
    shot_plain: ($shot.palette == ($bytes | bytes at $playpal..($playpal + 767) | encode hex | str lowercase))
    first: ($differing | first 5 | each {|i| {x: ($i mod 320), y: ($i // 320), vanilla: ($shot.indices | get $i), ours: ($ours | get $i)} })
    scratch: (if $keep { $dir } else { null })
  }
}
