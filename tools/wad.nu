# E1M1 as tables, for working out expected values before the code answers:
# the lump directory, and the map's lines, sides, sectors and vertices.
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
