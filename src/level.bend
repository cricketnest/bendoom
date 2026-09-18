# The map: E1M1's lumps read into trees, the player 1 start, and Doom's
# tables. Data, so the sim and the renderer take it by copy: geometry is
# a parameter of every function, never part of the state. Each lump is
# one tree of its 16-bit words, record after record, indexed by record
# number times the words kept of a record, plus the field.
import Base
import ./vec.bend as V
import ./bytes.bend as B
import ./wad.bend as W
import ./fixed.bend as F
import ./angle.bend as A
import ./tables.bend as T

# The lump's 16-bit words as read: the origin (in map units here, fixed
# in Doom), the size, then the cell offsets and the line lists.
type Level.Blockmap is Data:
  Blockmap{words: V.Vec, ox: U32, oy: U32, cols: U32, rows: U32}

type Level.Start is Data:
  Start{x: U32, y: U32, angle: U32}

# The words kept of a record: a line's two vertices, flags and two
# sides; a side's two offsets and sector; a sector's floor, ceiling and
# light; a vertex's x and y; a seg's two vertices, angle, line, side and
# offset; a subsector's seg count and first seg; a node's partition (x,
# y, dx, dy), right box, left box (each top, bottom, left, right) and
# two children (a subsector when bit 15 is set). The names are the
# sides' top, bottom and middle textures and the sectors' floor and
# ceiling flats, as the lumps spell them.
type Level is Data:
  Level{lines: V.Vec, nlines: U32, sides: V.Vec, sectors: V.Vec, verts: V.Vec, segs: V.Vec,
    subs: V.Vec, nodes: V.Vec, root: U32, blockmap: Level.Blockmap, start: Level.Start,
    texnames: List<&2, String>, flatnames: List<&2, String>, sine: V.Vec, tanto: V.Vec}

# A line as the sim sees it: its ends in fixed point, its flags, and the
# sectors on its two sides (65535 for none).
type Level.Line is Data:
  Line{x1: U32, y1: U32, x2: U32, y2: U32, flags: U32, front: U32, back: U32}

# A seg as the renderer sees it: its ends, the lump's angle and offset
# as stored, its line's flags, its side, and the sectors before and
# behind it (65535 for none: a line not flagged two-sided has no back).
type Level.Seg is Data:
  Seg{x1: U32, y1: U32, x2: U32, y2: U32, angle: U32, offset: U32, flags: U32, side: U32,
    front: U32, back: U32}

type Level.Sub is Data:
  Sub{count: U32, first: U32}

type Level.Box is Data:
  Box{top: U32, bottom: U32, left: U32, right: U32}

type Level.Sector is Data:
  Sector{floor: U32, ceil: U32, light: U32}

type Level.Side is Data:
  Side{xoff: U32, yoff: U32, sector: U32}

def Level.none() -> U32:
  65535

# Loading
# -------

def Level.lump.at(m: Maybe<&2, W.Wad.Lump>) -> U32 & U32:
  match m:
    case None{}:
      (0, 0)
    case Some{l}:
      W.Lump{pos, size, name} = l
      (pos, size)

def Level.lump.get(lumps: List<&2, W.Wad.Lump>, i: Maybe<Nat>) -> U32 & U32:
  match i:
    case None{}:
      (0, 0)
    case Some{k}:
      Level.lump.at(List.get(&2, W.Wad.Lump, lumps, k))

# The position and size of the first lump called name in the map's
# lumps.
def Level.lump(+map: List<&2, W.Wad.Lump>, +name: String) -> U32 & U32:
  Level.lump.get(map, W.Wad.index(name, map))

def Level.map.drop(lumps: List<&2, W.Wad.Lump>, i: Maybe<Nat>) ->
  List<&2, W.Wad.Lump>:
  match i:
    case None{}:
      []
    case Some{k}:
      List.drop(&2, W.Wad.Lump, lumps, k)

# The lumps from the E1M1 marker on, so Freedoom's first map loads the
# same way.
def Level.map(+lumps: List<&2, W.Wad.Lump>) -> List<&2, W.Wad.Lump>:
  Level.map.drop(lumps, W.Wad.index("E1M1", lumps))

# The offsets of the given fields in every record of a lump.
def Level.fields(ps: U32 & U32, +stride: U32, fields: List<&2, U32>) -> List<&2, U32>:
  (pos, size) = ps
  B.Bytes.fields(U32.to_nat((size / stride : U32)), pos, stride, fields)

# Every word the level keeps, lump by lump in the order Level.pack
# takes them.
def Level.plan(+map: List<&2, W.Wad.Lump>) -> List<&2, List<&2, U32>>:
  [Level.fields(Level.lump(map, "THINGS"), 10, [0, 2, 4, 6]),
    Level.fields(Level.lump(map, "LINEDEFS"), 14, [0, 2, 4, 10, 12]),
    Level.fields(Level.lump(map, "SIDEDEFS"), 30, [0, 2, 28]),
    Level.fields(Level.lump(map, "VERTEXES"), 4, [0, 2]),
    Level.fields(Level.lump(map, "SEGS"), 12, [0, 2, 4, 6, 8, 10]),
    Level.fields(Level.lump(map, "SSECTORS"), 4, [0, 2]),
    Level.fields(Level.lump(map, "NODES"), 28, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26]),
    Level.fields(Level.lump(map, "SECTORS"), 26, [0, 2, 20]),
    Level.fields(Level.lump(map, "BLOCKMAP"), 2, [0])]

def Level.vecs(lists: List<&2, List<&2, U32>>) -> List<&2, V.Vec>:
  match lists:
    case []:
      []
    case +words <> rest:
      V.Vec.of_list(words, U32.from_nat(List.length(&2, U32, words))) <> Level.vecs(rest)

def Level.start.go(k: Nat, +things: V.Vec, +i: U32, hit: Bool) -> Level.Start:
  match k hit:
    case _ True{}:
      Start{F.Fixed.of_map(V.Vec.get(things, (i * 4 : U32))),
        F.Fixed.of_map(V.Vec.get(things, (i * 4 + 1 : U32))),
        A.Angle.of_thing(V.Vec.get(things, (i * 4 + 2 : U32)))}
    case 0n _:
      Start{0, 0, 0}
    case 1n+j False{}:
      Level.start.go(j, things, (i + 1 : U32), U32.is_eq(V.Vec.get(things, (i * 4 + 7 : U32)), 1))

# The first thing of type 1: player 1's start.
def Level.start(count: U32, +things: V.Vec) -> Level.Start:
  Level.start.go(U32.to_nat(count), things, 0, U32.is_eq(V.Vec.get(things, 3), 1))

def Level.count.fin(stride: U32, ps: U32 & U32) -> U32:
  (pos, size) = ps
  (size / stride : U32)

def Level.count(+map: List<&2, W.Wad.Lump>, +name: String, stride: U32) -> U32:
  Level.count.fin(stride, Level.lump(map, name))

def Level.blockmap(+bm: V.Vec) -> Level.Blockmap:
  Blockmap{bm, F.Fixed.of_map(V.Vec.get(bm, 0)), F.Fixed.of_map(V.Vec.get(bm, 1)),
    V.Vec.get(bm, 2), V.Vec.get(bm, 3)}

# One sector with no lines, its floor and ceiling as given in map units,
# and Doom's tables: the level of the closed laws, and what a malformed
# WAD loads as. A Leaf answers every index, so one is a whole lump of
# zeros; root 32768 is subsector 0.
def Level.room(floor: U32, ceil: U32) -> Level:
  Level{V.Leaf{0}, 0, V.Leaf{0}, V.Vec.of_list([floor, ceil, 0], 3), V.Leaf{0}, V.Leaf{0},
    V.Leaf{0}, V.Leaf{0}, 32768, Blockmap{V.Leaf{0}, 0, 0, 0, 0}, Start{0, 0, 0}, [], [],
    V.Vec.of_list(T.Tables.finesine(), 10240), V.Vec.of_list(T.Tables.tantoangle(), 2049)}

def Level.pack.go(+map: List<&2, W.Wad.Lump>, vs: List<&2, V.Vec>, texnames: List<&2, String>,
  flatnames: List<&2, String>) -> Level:
  match vs:
    case [things, lines, sides, verts, segs, subs, nodes, sectors, bm]:
      Level{lines, Level.count(map, "LINEDEFS", 14), sides, sectors, verts, segs, subs, nodes,
        (Level.count(map, "NODES", 28) - 1 : U32), Level.blockmap(bm),
        Level.start(Level.count(map, "THINGS", 10), things), texnames, flatnames,
        V.Vec.of_list(T.Tables.finesine(), 10240), V.Vec.of_list(T.Tables.tantoangle(), 2049)}
    case _:
      Level.room(0, 0)

def Level.pack(+map: List<&2, W.Wad.Lump>, vs: List<&2, V.Vec>, texnames: List<&2, String>,
  p: Array<U32> & List<&2, String>) -> Array<U32> & Level:
  (a, flatnames) = p
  (a, Level.pack.go(map, vs, texnames, flatnames))

def Level.flats(+map: List<&2, W.Wad.Lump>, vs: List<&2, V.Vec>, p: Array<U32> & List<&2, String>) ->
  Array<U32> & Level:
  (a, texnames) = p
  Level.pack(map, vs, texnames, B.Bytes.each(~String, ~B.Bytes.name,
    Level.fields(Level.lump(map, "SECTORS"), 26, [4, 12]), a))

def Level.names(+map: List<&2, W.Wad.Lump>, p: Array<U32> & List<&2, List<&2, U32>>) ->
  Array<U32> & Level:
  (a, lists) = p
  Level.flats(map, Level.vecs(lists), B.Bytes.each(~String, ~B.Bytes.name,
    Level.fields(Level.lump(map, "SIDEDEFS"), 30, [4, 12, 20]), a))

# The level from the WAD's bytes and directory.
def Level.load(p: Array<U32> & List<&2, W.Wad.Lump>) -> Array<U32> & Level:
  (a, +lumps) = p
  +map = Level.map(lumps)
  Level.names(map, B.Bytes.lists(~U32, ~B.Bytes.u16, Level.plan(map), a))

# Lookups
# -------

# Field f of record i in a tree of n words a record.
def Level.word(v: V.Vec, i: U32, n: U32, f: U32) -> U32:
  V.Vec.get(v, (i * n + f : U32))

def Level.side.sector(+l: Level, +side: U32) -> U32:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  Bool.pick(U32, U32.is_eq(side, Level.none()), Level.none(), Level.word(sides, side, 3, 2))

def Level.vertex.x(+l: Level, v: U32) -> U32:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  F.Fixed.of_map(Level.word(verts, v, 2, 0))

def Level.vertex.y(+l: Level, v: U32) -> U32:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  F.Fixed.of_map(Level.word(verts, v, 2, 1))

def Level.line(+l: Level, +i: U32) -> Level.Line:
  Level{+lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  +a = Level.word(lines, i, 5, 0)
  +b = Level.word(lines, i, 5, 1)
  Line{Level.vertex.x(l, a), Level.vertex.y(l, a), Level.vertex.x(l, b), Level.vertex.y(l, b),
    Level.word(lines, i, 5, 2), Level.side.sector(l, Level.word(lines, i, 5, 3)),
    Level.side.sector(l, Level.word(lines, i, 5, 4))}

def Level.line_count(+l: Level) -> U32:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  nlines

# A line's side number: 0 the right one, 1 the left.
def Level.line.side(+l: Level, line: U32, side: U32) -> U32:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  Level.word(lines, line, 5, (3 + side : U32))

# Doom's P_LoadSegs: the angle and offset as the lump stores them, the
# back sector only behind a line flagged two-sided.
def Level.seg(+l: Level, +i: U32) -> Level.Seg:
  Level{+lines, nlines, sides, sectors, verts, +segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  +a = Level.word(segs, i, 6, 0)
  +b = Level.word(segs, i, 6, 1)
  +line = Level.word(segs, i, 6, 3)
  +side = Level.word(segs, i, 6, 4)
  +flags = Level.word(lines, line, 5, 2)
  +front = Level.line.side(l, line, side)
  Seg{Level.vertex.x(l, a), Level.vertex.y(l, a), Level.vertex.x(l, b), Level.vertex.y(l, b),
    F.Fixed.of_map(Level.word(segs, i, 6, 2)), F.Fixed.of_map(Level.word(segs, i, 6, 5)), flags,
    front, Level.side.sector(l, front),
    Bool.pick(U32, U32.is_zero((flags .&. 4 : U32)), Level.none(),
      Level.side.sector(l, Level.line.side(l, line, (side .^. 1 : U32))))}

def Level.sub(+l: Level, +i: U32) -> Level.Sub:
  Level{lines, nlines, sides, sectors, verts, segs, +subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  Sub{Level.word(subs, i, 2, 0), Level.word(subs, i, 2, 1)}

# A node's bounding box on a side: 0 the right child's, 1 the left's.
def Level.box(+l: Level, +n: U32, +side: U32) -> Level.Box:
  Level{lines, nlines, sides, sectors, verts, segs, subs, +nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  Box{F.Fixed.of_map(Level.word(nodes, n, 14, (4 + side * 4 : U32))),
    F.Fixed.of_map(Level.word(nodes, n, 14, (5 + side * 4 : U32))),
    F.Fixed.of_map(Level.word(nodes, n, 14, (6 + side * 4 : U32))),
    F.Fixed.of_map(Level.word(nodes, n, 14, (7 + side * 4 : U32)))}

def Level.floor(+l: Level, s: U32) -> U32:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  F.Fixed.of_map(Level.word(sectors, s, 3, 0))

def Level.ceil(+l: Level, s: U32) -> U32:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  F.Fixed.of_map(Level.word(sectors, s, 3, 1))

def Level.sector(+l: Level, +s: U32) -> Level.Sector:
  Level{lines, nlines, sides, +sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  Sector{F.Fixed.of_map(Level.word(sectors, s, 3, 0)), F.Fixed.of_map(Level.word(sectors, s, 3, 1)),
    Level.word(sectors, s, 3, 2)}

def Level.sector.light(+l: Level, s: U32) -> U32:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  Level.word(sectors, s, 3, 2)

def Level.side(+l: Level, +i: U32) -> Level.Side:
  Level{lines, nlines, +sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  Side{F.Fixed.of_map(Level.word(sides, i, 3, 0)), F.Fixed.of_map(Level.word(sides, i, 3, 1)),
    Level.word(sides, i, 3, 2)}

def Level.texnames(+l: Level) -> List<&2, String>:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  texnames

def Level.flatnames(+l: Level) -> List<&2, String>:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  flatnames

# A side's top, bottom and middle texture names.
def Level.side_names(+l: Level, i: U32) -> List<&2, String>:
  List.take(&2, String, List.drop(&2, String, Level.texnames(l), U32.to_nat((i * 3 : U32))), 3n)

# A sector's floor and ceiling flat names.
def Level.flat_names(+l: Level, s: U32) -> List<&2, String>:
  List.take(&2, String, List.drop(&2, String, Level.flatnames(l), U32.to_nat((s * 2 : U32))), 2n)

def Level.sine(+l: Level) -> V.Vec:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  sine

def Level.tanto(+l: Level) -> V.Vec:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  tanto

def Level.start_of(+l: Level) -> Level.Start:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  start

def Level.blockmap_of(+l: Level) -> Level.Blockmap:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  blockmap

def Level.root(+l: Level) -> U32:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  root

# The lines listed in a blockmap cell (none outside the map): the words
# after the cell's offset, past its leading zero, up to the 65535.
def Level.cell.go(k: Nat, end: Bool, +words: V.Vec, +i: U32, +w: U32) ->
  List<&2, U32>:
  match k end:
    case _ True{}:
      []
    case 0n _:
      []
    case 1n+j False{}:
      +w2 = V.Vec.get(words, (i + 1 : U32))
      w <> Level.cell.go(j, U32.is_eq(w2, 65535), words, (i + 1 : U32), w2)

def Level.cell.list(inside: Bool, +words: V.Vec, +i: U32) -> List<&2, U32>:
  match inside:
    case False{}:
      []
    case True{}:
      +off = (V.Vec.get(words, i) + 1 : U32)
      +w = V.Vec.get(words, off)
      Level.cell.go(U32.to_nat(4096), U32.is_eq(w, 65535), words, off, w)

# Cell coordinates are signed: a negative one reads as a huge unsigned
# one, so the unsigned bound checks both ends.
def Level.cell.at(+bm: Level.Blockmap, +bx: U32, +by: U32) -> List<&2, U32>:
  Blockmap{words, ox, oy, +cols, +rows} = bm
  Level.cell.list(Bool.and(U32.is_lt(bx, cols), U32.is_lt(by, rows)), words,
    (4 + by * cols + bx : U32))

def Level.cell(+l: Level, bx: U32, by: U32) -> List<&2, U32>:
  Level.cell.at(Level.blockmap_of(l), bx, by)

# The sector under a point
# ------------------------

# Which side of a line through (x0, y0) along (dx, dy) a point is on,
# True for the back: an axis-aligned line is decided by one coordinate,
# any other by the caller's cross product. Doom's P_PointOnLineSide,
# P_PointOnDivlineSide and R_PointOnSide share this shape.
def Level.axis_side(+x: U32, +y: U32, +x0: U32, +y0: U32, +dx: U32, +dy: U32, slow: Bool) -> Bool:
  Bool.pick(Bool, U32.is_zero(dx),
    Bool.pick(Bool, F.Fixed.le(x, x0), F.Fixed.gt(dy, 0), F.Fixed.lt(dy, 0)),
    Bool.pick(Bool, U32.is_zero(dy),
      Bool.pick(Bool, F.Fixed.le(y, y0), F.Fixed.lt(dx, 0), F.Fixed.gt(dx, 0)), slow))

# Doom's R_PointOnSide: the cross product with the sign-bit shortcut and
# the halved multiply of the original.
def Level.node_side.slow(+x: U32, +y: U32, +dx: U32, +dy: U32) -> Bool:
  Bool.pick(Bool, U32.is_zero(((dy .^. dx .^. x .^. y) .&. 2147483648 : U32)),
    Bool.not(F.Fixed.lt(F.Fixed.mul(y, F.Fixed.sarn(dx, 16n)),
      F.Fixed.mul(F.Fixed.sarn(dy, 16n), x))),
    Bool.not(U32.is_zero(((dy .^. x) .&. 2147483648 : U32))))

def Level.node_side(+x: U32, +y: U32, +nx: U32, +ny: U32, +dx: U32, +dy: U32) -> Bool:
  Level.axis_side(x, y, nx, ny, dx, dy, Level.node_side.slow((x - nx : U32), (y - ny : U32), dx, dy))

# A node's child on the side of a point: 0 the right, 1 the left.
def Level.node.child(+l: Level, n: U32, side: U32) -> U32:
  Level{lines, nlines, sides, sectors, verts, segs, subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  Level.word(nodes, n, 14, (12 + side : U32))

# Doom's R_PointOnSide against node n: 1 on the back (left) side.
def Level.side_of(+l: Level, +n: U32, +x: U32, +y: U32) -> U32:
  Level{lines, nlines, sides, sectors, verts, segs, subs, +nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  Bool.to_u32(Level.node_side(x, y, F.Fixed.of_map(Level.word(nodes, n, 14, 0)),
    F.Fixed.of_map(Level.word(nodes, n, 14, 1)), F.Fixed.of_map(Level.word(nodes, n, 14, 2)),
    F.Fixed.of_map(Level.word(nodes, n, 14, 3))))

def Level.is_leaf(+n: U32) -> Bool:
  U32.is_ge(n, 32768)

# A subsector's sector: its first seg's front sector.
def Level.leaf_sector(+l: Level, ss: U32) -> U32:
  Level{lines, nlines, sides, sectors, verts, +segs, +subs, nodes, root, blockmap, start, texnames, flatnames, sine, tanto} = l
  +seg = Level.word(subs, ss, 2, 1)
  Level.side.sector(l, Level.line.side(l, Level.word(segs, seg, 6, 3), Level.word(segs, seg, 6, 4)))

def Level.descend(fuel: Nat, leaf: Bool, +l: Level, +x: U32, +y: U32, +n: U32) -> U32:
  match fuel leaf:
    case _ True{}:
      Level.leaf_sector(l, (n .&. 32767 : U32))
    case 0n _:
      0
    case 1n+f False{}:
      +m = Level.node.child(l, n, Level.side_of(l, n, x, y))
      Level.descend(f, Level.is_leaf(m), l, x, y, m)

# Doom's R_PointInSubsector, then the subsector's sector.
def Level.sector_at(+l: Level, +x: U32, +y: U32) -> U32:
  +root = Level.root(l)
  Level.descend(U32.to_nat((root + 1 : U32)), Level.is_leaf(root), l, x, y, root)
