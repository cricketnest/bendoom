# E1M1 as tables, for working out expected values before the code answers:
# the lump directory, the map's lines, sides, sectors and vertices, and
# the events of its song.
#
#   nu -c 'source tools/wad.nu; open --raw $env.BENDOOM_IWAD | linedefs | where special != 0'
#   nu -c 'source tools/wad.nu; open --raw $env.BENDOOM_IWAD | song-events | song-counts'

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

# The lump of a name after the E1M1 marker.
def map-lump [name: string]: binary -> record<name: string, pos: int, size: int> {
  let all = $in | lumps | enumerate | flatten
  let marker = $all | where name == "E1M1" | first | get index
  $all | where index > $marker and name == $name | first | select name pos size
}

def word [at: int, --signed]: binary -> int {
  let two = $in | bytes at $at..($at + 1)
  if $signed { $two | into int --endian little --signed } else { $two | into int --endian little }
}

def name8 [at: int]: binary -> string {
  $in | bytes at $at..($at + 7) | decode utf-8 | str trim --char (char nul)
}

def linedefs []: binary -> table {
  let wad = $in
  let l = $wad | map-lump LINEDEFS
  0..<($l.size // 14) | each {|i| let at = $l.pos + $i * 14
    {i: $i, v1: ($wad | word $at), v2: ($wad | word ($at + 2)), flags: ($wad | word ($at + 4)), special: ($wad | word ($at + 6)),
      tag: ($wad | word ($at + 8)), front: ($wad | word ($at + 10)), back: ($wad | word ($at + 12))} }
}

def sidedefs []: binary -> table {
  let wad = $in
  let l = $wad | map-lump SIDEDEFS
  0..<($l.size // 30) | each {|i| let at = $l.pos + $i * 30
    {i: $i, xoff: ($wad | word $at --signed), yoff: ($wad | word ($at + 2) --signed), top: ($wad | name8 ($at + 4)),
      bottom: ($wad | name8 ($at + 12)), mid: ($wad | name8 ($at + 20)), sector: ($wad | word ($at + 28))} }
}

def sectordefs []: binary -> table {
  let wad = $in
  let l = $wad | map-lump SECTORS
  0..<($l.size // 26) | each {|i| let at = $l.pos + $i * 26
    {i: $i, floor: ($wad | word $at --signed), ceil: ($wad | word ($at + 2) --signed), floorpic: ($wad | name8 ($at + 4)),
      ceilpic: ($wad | name8 ($at + 12)), light: ($wad | word ($at + 20)), special: ($wad | word ($at + 22)), tag: ($wad | word ($at + 24))} }
}

def vertexes []: binary -> table {
  let wad = $in
  let l = $wad | map-lump VERTEXES
  0..<($l.size // 4) | each {|i| {i: $i, x: ($wad | word ($l.pos + $i * 4) --signed), y: ($wad | word ($l.pos + $i * 4 + 2) --signed)} }
}

# A channel event's name, by its status's high nibble from 0x80.
const channel_kinds = [off on touch controller program pressure bend]

# mus2mid.c's controller_map.
const mus_controllers = [0 32 1 7 10 11 91 93 64 67 120 123 126 127 121]

def bytes-list []: binary -> list<int> {
  $in | chunks 1 | each { into int }
}

# A MUS lump's events as mus2mid.c converts them to one MIDI track: MUS
# channel 15 on MIDI's 9, the others on MIDI channels in the order of
# their first use, skipping 9, each sent an all-notes-off at that first
# use; the last velocity kept a channel; a group's delay before the next.
def mus-events []: binary -> table {
  let lump = $in
  let b = $lump | bytes at ($lump | word 6).. | bytes-list
  mut i = 0
  mut delta = 0
  mut chans = []
  mut vels = 0..15 | each { 127 }
  mut out = []
  loop {
    let d = $b | get $i
    $i += 1
    let c = $d | bits and 15
    mut ch = 9
    if $c != 15 {
      let at = $chans | enumerate | where item == $c | get index.0?
      let n = if $at == null { $chans | length } else { $at }
      $ch = if $n >= 9 { $n + 1 } else { $n }
      if $at == null {
        $chans = $chans | append $c
        $out = $out | append {delta: $delta kind: controller ch: $ch p1: 123 p2: 0}
        $delta = 0
      }
    }
    let op = $d | bits and 0x70
    if $op == 0x60 {
      $out = $out | append {delta: $delta kind: end ch: null p1: null p2: null}
      break
    }
    let x = $b | get $i
    $i += 1
    let event = if $op == 0x00 {
      {kind: off p1: ($x | bits and 127) p2: 0}
    } else if $op == 0x10 {
      if ($x | bits and 128) != 0 {
        $vels = $vels | update $ch (($b | get $i) | bits and 127)
        $i += 1
      }
      {kind: on p1: ($x | bits and 127) p2: ($vels | get $ch)}
    } else if $op == 0x20 {
      {kind: bend p1: (($x | bits and 1) * 64) p2: ($x | bits shr 1)}
    } else if $op == 0x30 and $x >= 10 and $x <= 14 {
      {kind: controller p1: ($mus_controllers | get $x) p2: 0}
    } else if $op == 0x40 and $x <= 9 {
      let v = $b | get $i
      $i += 1
      if $x == 0 { {kind: program p1: ($v | bits and 127) p2: 0} } else {
        {kind: controller p1: ($mus_controllers | get $x) p2: ([$v 127] | math min)}
      }
    } else {
      error make {msg: $"mus2mid.c refuses descriptor ($d) at score byte ($i - 2)"}
    }
    $out = $out | append ({delta: $delta ch: $ch} | merge $event)
    $delta = 0
    if ($d | bits and 128) != 0 {
      mut more = true
      while $more {
        let t = $b | get $i
        $i += 1
        $delta = $delta * 128 + ($t | bits and 127)
        $more = $t >= 128
      }
    }
  }
  $out | each { insert track 0 }
}

# A MIDI lump's events as midifile.c reads them: each track from after
# its header to its end-of-track, a data byte in a status's place
# repeating the last status.
def midi-events []: binary -> table {
  let lump = $in
  let b = $lump | bytes-list
  let tracks = $lump | bytes at 10..11 | into int --endian big
  mut pos = 14
  mut out = []
  for track in 0..<$tracks {
    $pos += 8
    mut status = 0
    mut done = false
    while not $done {
      mut delta = 0
      mut more = true
      while $more {
        let t = $b | get $pos
        $pos += 1
        $delta = $delta * 128 + ($t | bits and 127)
        $more = $t >= 128
      }
      if ($b | get $pos) >= 128 {
        $status = $b | get $pos
        $pos += 1
      }
      mut event: any = {kind: other ch: null p1: null p2: null}
      if $status == 0xFF or $status == 0xF0 or $status == 0xF7 {
        let meta = if $status == 0xFF { $pos += 1; $b | get ($pos - 1) } else { null }
        mut n = 0
        mut more = true
        while $more {
          let t = $b | get $pos
          $pos += 1
          $n = $n * 128 + ($t | bits and 127)
          $more = $t >= 128
        }
        if $meta == 0x2F {
          $event.kind = "end"
          $done = true
        } else if $meta == 0x51 and $n == 3 {
          $event.kind = "tempo"
          $event.p1 = $lump | bytes at $pos..($pos + 2) | into int --endian big
        }
        $pos += $n
      } else {
        $event = {
          kind: ($channel_kinds | get (($status | bits shr 4) - 8))
          ch: ($status | bits and 15)
          p1: ($b | get $pos)
          p2: (if ($status | bits and 0xE0) == 0xC0 { 0 } else { $b | get ($pos + 1) })
        }
        $pos += if ($status | bits and 0xE0) == 0xC0 { 1 } else { 2 }
      }
      $out = $out | append ({track: $track delta: $delta} | merge $event)
    }
  }
  $out
}

# E1M1's song as the events Chocolate Doom's player reads, a row each.
def song-events []: binary -> table {
  let wad = $in
  let l = $wad | lumps | where name == "D_E1M1" | first
  let song = $wad | bytes at $l.pos..<($l.pos + $l.size)
  if ($song | bytes at 0..3) == 0x[4D55531A] { $song | mus-events } else { $song | midi-events }
}

# The song's length in ticks, its longest track's, and its events by
# kind, in the order tests/music.bend prints them.
def song-counts []: table -> string {
  let events = $in
  let ticks = $events | group-by track | values | each { get delta | math sum } | math max
  let counts = $channel_kinds | append [tempo end other] | each {|k| $"($k) ($events | where kind == $k | length)" }
  $"song ticks ($ticks) events ($events | length) ($counts | str join ' ')"
}
