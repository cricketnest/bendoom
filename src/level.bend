# The map: E1M1's lumps read into trees indexed by number, the player 1
# start, and Doom's tables. Data, so the sim takes it by copy: geometry
# is a parameter of every sim function, never part of the state. The
# NODES, SEGS and SSECTORS lumps are read for the sector under a point,
# which Doom's collision starts from.
import Base
import ./vec.bend as V
import ./bytes.bend as B
import ./wad.bend as W
import ./fixed.bend as F
import ./angle.bend as A
import ./tables.bend as T

type Level.Lines is Data:
  Lines{count: U32, v1: V.Vec, v2: V.Vec, flags: V.Vec, side0: V.Vec, side1: V.Vec}

# The BSP: a node's partition line, its two children (a subsector when
# bit 15 is set), and the way from a subsector to its sector: its first
# seg's linedef and side.
type Level.Bsp is Data:
  Bsp{root: U32, x: V.Vec, y: V.Vec, dx: V.Vec, dy: V.Vec, c0: V.Vec,
    c1: V.Vec, ssfirst: V.Vec, segline: V.Vec, segside: V.Vec}

# The lump's 16-bit words as read: the origin (in map units here, fixed
# in Doom), the size, then the cell offsets and the line lists.
type Level.Blockmap is Data:
  Blockmap{words: V.Vec, ox: U32, oy: U32, cols: U32, rows: U32}

type Level.Start is Data:
  Start{x: U32, y: U32, angle: U32}

type Level is Data:
  Level{lines: Level.Lines, sector: V.Vec, vx: V.Vec, vy: V.Vec,
    floor: V.Vec, ceil: V.Vec, bsp: Level.Bsp, blockmap: Level.Blockmap,
    start: Level.Start, sine: V.Vec, tanto: V.Vec}

# A line as the sim sees it: its ends in fixed point, its flags, and the
# sectors on its two sides (65535 for none).
type Level.Line is Data:
  Line{x1: U32, y1: U32, x2: U32, y2: U32, flags: U32, front: U32, back: U32}

def Level.none() -> U32:
  65535

# Loading
# -------

# One field of every record of a lump: count records of stride bytes,
# the field at off.
type Level.Req is Data:
  Req{off: U32, count: U32, stride: U32}

def Level.fields.go(offs: List<&2, U32>, +pos: U32, +count: U32, +stride: U32) ->
  List<&2, Level.Req>:
  match offs:
    case []:
      []
    case o <> rest:
      Req{(pos + o : U32), count, stride} <> Level.fields.go(rest, pos, count, stride)

def Level.fields(ps: U32 & U32, +stride: U32, offs: List<&2, U32>) ->
  List<&2, Level.Req>:
  (pos, size) = ps
  Level.fields.go(offs, pos, (size / stride : U32), stride)

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

# Every field the level keeps, in the order Level.pack takes them.
def Level.reqs(+map: List<&2, W.Wad.Lump>) -> List<&2, Level.Req>:
  List.concat(&2, Level.Req, [
    Level.fields(Level.lump(map, "THINGS"), 10, [0, 2, 4, 6]),
    Level.fields(Level.lump(map, "LINEDEFS"), 14, [0, 2, 4, 10, 12]),
    Level.fields(Level.lump(map, "SIDEDEFS"), 30, [28]),
    Level.fields(Level.lump(map, "VERTEXES"), 4, [0, 2]),
    Level.fields(Level.lump(map, "SEGS"), 12, [6, 8]),
    Level.fields(Level.lump(map, "SSECTORS"), 4, [2]),
    Level.fields(Level.lump(map, "NODES"), 28, [0, 2, 4, 6, 24, 26]),
    Level.fields(Level.lump(map, "SECTORS"), 26, [0, 2]),
    Level.fields(Level.lump(map, "BLOCKMAP"), 2, [0])])

def Level.reads.join(vs: List<&2, V.Vec>, q: Array<U32> & V.Vec) ->
  Array<U32> & List<&2, V.Vec>:
  (a, v) = q
  (a, v <> vs)

def Level.reads.cons(req: Level.Req, p: Array<U32> & List<&2, V.Vec>) ->
  Array<U32> & List<&2, V.Vec>:
  Req{off, +count, stride} = req
  (a, vs) = p
  Level.reads.join(vs, B.Bytes.vec(U32.to_nat(count), count, a, off, stride))

# The requests are read last to first, so the trees come out in order.
def Level.reads(reqs: List<&2, Level.Req>, a: Array<U32>) ->
  Array<U32> & List<&2, V.Vec>:
  match reqs:
    case []:
      (a, [])
    case r <> rest:
      Level.reads.cons(r, Level.reads(rest, a))

def Level.start.go(k: Nat, +tx: V.Vec, +ty: V.Vec, +ta: V.Vec, +tt: V.Vec,
  +i: U32, hit: Bool) -> Level.Start:
  match k hit:
    case _ True{}:
      Start{F.Fixed.of_map(V.Vec.get(tx, i)), F.Fixed.of_map(V.Vec.get(ty, i)),
        A.Angle.of_thing(V.Vec.get(ta, i))}
    case 0n _:
      Start{0, 0, 0}
    case 1n+j False{}:
      Level.start.go(j, tx, ty, ta, tt, (i + 1 : U32),
        U32.is_eq(V.Vec.get(tt, (i + 1 : U32)), 1))

# The first thing of type 1: player 1's start.
def Level.start(count: U32, tx: V.Vec, ty: V.Vec, ta: V.Vec, +tt: V.Vec) ->
  Level.Start:
  Level.start.go(U32.to_nat(count), tx, ty, ta, tt, 0, U32.is_eq(V.Vec.get(tt, 0), 1))

def Level.count.fin(stride: U32, ps: U32 & U32) -> U32:
  (pos, size) = ps
  (size / stride : U32)

def Level.count(+map: List<&2, W.Wad.Lump>, +name: String, stride: U32) -> U32:
  Level.count.fin(stride, Level.lump(map, name))

def Level.blockmap(+bm: V.Vec) -> Level.Blockmap:
  Blockmap{bm, F.Fixed.of_map(V.Vec.get(bm, 0)), F.Fixed.of_map(V.Vec.get(bm, 1)),
    V.Vec.get(bm, 2), V.Vec.get(bm, 3)}

def Level.pack.go(a: Array<U32>, +map: List<&2, W.Wad.Lump>, vs: List<&2, V.Vec>) ->
  Array<U32> & Level:
  match vs:
    case [tx, ty, ta, tt, lv1, lv2, lf, ls0, ls1, ssec, vx, vy, sl, sd, ssf, nx,
      ny, ndx, ndy, nc0, nc1, sf, sc, bm]:
      (a, Level{Lines{Level.count(map, "LINEDEFS", 14), lv1, lv2, lf, ls0, ls1}, ssec, V.Vec.fixed(vx), V.Vec.fixed(vy),
        V.Vec.fixed(sf), V.Vec.fixed(sc),
        Bsp{(Level.count(map, "NODES", 28) - 1 : U32), V.Vec.fixed(nx), V.Vec.fixed(ny),
          V.Vec.fixed(ndx), V.Vec.fixed(ndy), nc0, nc1, ssf, sl, sd},
        Level.blockmap(bm), Level.start(Level.count(map, "THINGS", 10), tx, ty, ta, tt),
        V.Vec.of_list(T.Tables.finesine(), 10240),
        V.Vec.of_list(T.Tables.tantoangle(), 2049)})
    case _:
      (a, Level{Lines{0, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}}, V.Leaf{0}, V.Leaf{0},
        V.Leaf{0}, V.Leaf{0}, V.Leaf{0},
        Bsp{0, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}},
        Blockmap{V.Leaf{0}, 0, 0, 0, 0}, Start{0, 0, 0}, V.Leaf{0}, V.Leaf{0}})

def Level.pack(+map: List<&2, W.Wad.Lump>, p: Array<U32> & List<&2, V.Vec>) ->
  Array<U32> & Level:
  (a, vs) = p
  Level.pack.go(a, map, vs)

# The level from the WAD's bytes and directory.
def Level.load(p: Array<U32> & List<&2, W.Wad.Lump>) -> Array<U32> & Level:
  (a, +lumps) = p
  +map = Level.map(lumps)
  Level.pack(map, Level.reads(Level.reqs(map), a))

# Lookups
# -------

def Level.side.sector(+l: Level, +side: U32) -> U32:
  Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
  Bool.pick(U32, U32.is_eq(side, Level.none()), Level.none(), V.Vec.get(sector, side))

def Level.line(+l: Level, +i: U32) -> Level.Line:
  Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
  Lines{count, v1, v2, flags, side0, side1} = lines
  +a = V.Vec.get(v1, i)
  +b = V.Vec.get(v2, i)
  Line{V.Vec.get(vx, a), V.Vec.get(vy, a), V.Vec.get(vx, b), V.Vec.get(vy, b),
    V.Vec.get(flags, i), Level.side.sector(l, V.Vec.get(side0, i)),
    Level.side.sector(l, V.Vec.get(side1, i))}

def Level.line_count(+l: Level) -> U32:
  Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
  Lines{count, v1, v2, flags, side0, side1} = lines
  count

def Level.floor(+l: Level, s: U32) -> U32:
  Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
  V.Vec.get(floor, s)

def Level.ceil(+l: Level, s: U32) -> U32:
  Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
  V.Vec.get(ceil, s)

def Level.sine(+l: Level) -> V.Vec:
  Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
  sine

def Level.tanto(+l: Level) -> V.Vec:
  Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
  tanto

def Level.start_of(+l: Level) -> Level.Start:
  Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
  start

def Level.blockmap_of(+l: Level) -> Level.Blockmap:
  Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
  blockmap

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

def Level.child(+bsp: Level.Bsp, +n: U32, +x: U32, +y: U32) -> U32:
  Bsp{root, nx, ny, ndx, ndy, c0, c1, ssfirst, segline, segside} = bsp
  Bool.pick(U32, Level.node_side(x, y, V.Vec.get(nx, n), V.Vec.get(ny, n),
    V.Vec.get(ndx, n), V.Vec.get(ndy, n)), V.Vec.get(c1, n), V.Vec.get(c0, n))

def Level.is_leaf(+n: U32) -> Bool:
  U32.is_ge(n, 32768)

# A subsector's sector: through its first seg's linedef and side.
def Level.leaf_sector(+l: Level, +ss: U32) -> U32:
  Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
  Lines{count, v1, v2, flags, side0, side1} = lines
  Bsp{root, nx, ny, ndx, ndy, c0, c1, ssfirst, segline, segside} = bsp
  +seg = V.Vec.get(ssfirst, ss)
  +line = V.Vec.get(segline, seg)
  V.Vec.get(sector, Bool.pick(U32, U32.is_zero(V.Vec.get(segside, seg)),
    V.Vec.get(side0, line), V.Vec.get(side1, line)))

def Level.descend(fuel: Nat, leaf: Bool, +l: Level, +x: U32, +y: U32, +n: U32) -> U32:
  match fuel leaf:
    case _ True{}:
      Level.leaf_sector(l, (n .&. 32767 : U32))
    case 0n _:
      0
    case 1n+f False{}:
      Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
      +m = Level.child(bsp, n, x, y)
      Level.descend(f, Level.is_leaf(m), l, x, y, m)

# Doom's R_PointInSubsector, then the subsector's sector.
def Level.sector_at(+l: Level, +x: U32, +y: U32) -> U32:
  Level{lines, sector, vx, vy, floor, ceil, bsp, blockmap, start, sine, tanto} = l
  Bsp{+root, nx, ny, ndx, ndy, c0, c1, ssfirst, segline, segside} = bsp
  Level.descend(U32.to_nat((root + 1 : U32)), Level.is_leaf(root), l, x, y, root)
