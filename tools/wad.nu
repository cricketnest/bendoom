# E1M1 as tables, for working out expected values before the code answers:
# the lump directory, the map's lines, sides, sectors, vertices and
# things, and the sector under a point.
#
#   nu -c 'source tools/wad.nu; open --raw $env.BENDOOM_IWAD | linedefs | where special != 0'

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

def things []: binary -> table {
  let wad = $in
  let l = $wad | map-lump THINGS
  0..<($l.size // 10) | each {|i| let at = $l.pos + $i * 10
    {i: $i, x: ($wad | word $at --signed), y: ($wad | word ($at + 2) --signed), angle: ($wad | word ($at + 4)),
      type: ($wad | word ($at + 6)), options: ($wad | word ($at + 8))} }
}

# The map's BSP and what a subsector stands in, for sector-at.
def bsp []: binary -> record {
  let wad = $in
  let n = $wad | map-lump NODES
  let ss = $wad | map-lump SSECTORS
  let sg = $wad | map-lump SEGS
  let lines = $wad | linedefs
  let sides = $wad | sidedefs
  {
    nodes: (0..<($n.size // 28) | each {|i| let at = $n.pos + $i * 28
      {x: ($wad | word $at --signed), y: ($wad | word ($at + 2) --signed), dx: ($wad | word ($at + 4) --signed),
        dy: ($wad | word ($at + 6) --signed), right: ($wad | word ($at + 24)), left: ($wad | word ($at + 26))} })
    sectors: (0..<($ss.size // 4) | each {|i| let seg = $sg.pos + ($wad | word ($ss.pos + $i * 4 + 2)) * 12
      let line = $lines | get ($wad | word ($seg + 6))
      $sides | get (if ($wad | word ($seg + 8)) == 0 { $line.front } else { $line.back }) | get sector })
  }
}

# Doom's R_PointOnSide for a point in whole map units: 1 on the back.
def point-on-side [x: int, y: int, node: record]: nothing -> int {
  if $node.dx == 0 {
    if $x <= $node.x { $node.dy > 0 | into int } else { $node.dy < 0 | into int }
  } else if $node.dy == 0 {
    if $y <= $node.y { $node.dx < 0 | into int } else { $node.dx > 0 | into int }
  } else {
    let dx = $x - $node.x
    let dy = $y - $node.y
    if ([($node.dy < 0) ($node.dx < 0) ($dx < 0) ($dy < 0)] | where $it | length) mod 2 == 1 {
      if ($node.dy < 0) != ($dx < 0) { 1 } else { 0 }
    } else if $dy * $node.dx < $node.dy * $dx { 0 } else { 1 }
  }
}

# Doom's R_PointInSubsector, answered with the subsector's sector.
def sector-at [x: int, y: int]: record -> int {
  let bsp = $in
  mut n = ($bsp.nodes | length) - 1
  while $n < 32768 {
    let node = $bsp.nodes | get $n
    $n = if (point-on-side $x $y $node) == 1 { $node.left } else { $node.right }
  }
  $bsp.sectors | get ($n - 32768)
}
