# The graphics E1M1 names, copied from the WAD into one linear array the
# draw threads, since a texel read through a copyable tree costs three
# hundred times one through an array (bench/lookup.bend). The array
# holds the frame and the draw's per-column scratch first, then the
# palette as RGB words, the colormaps, and the lumps: the flats the
# sectors name, then the patches of the textures the sides name, then
# the composed columns. Gfx is the directory into it: Data, so the draw
# takes it by copy. Every other flat and texture stays a name in the WAD.
import Base
import ./vec.bend as V
import ./bytes.bend as B
import ./wad.bend as W
import ./level.bend as L

# flats: a flat number's index in the array. pics: a sector's floor and
# ceiling flat numbers, two a sector. sky: the sky flat's number.
type Gfx is Data:
  Gfx{flats: V.Vec, pics: V.Vec, sky: U32}

# The frame: 320 by 200 palette indices, row by row.
def Gfx.frame() -> U32:
  0

# The draw's clip arrays, one slot a column.
def Gfx.ceilclip() -> U32:
  64000

def Gfx.floorclip() -> U32:
  64320

def Gfx.palette() -> U32:
  65536

def Gfx.colormap() -> U32:
  65792

def Gfx.lumps() -> U32:
  74496

def Gfx.none() -> U32:
  4294967295

# Names to numbers
# ----------------

# The names met so far with their numbers, the next number, and, newest
# first, each name's number and the names in number order.
type Gfx.Names is Data:
  Names{seen: Map<&2, U32>, next: U32, numbers: List<&2, U32>, distinct: List<&2, String>}

def Gfx.names.put(new: Bool, +name: String, k: U32, seen: Map<&2, U32>, +next: U32,
  numbers: List<&2, U32>, distinct: List<&2, String>) -> Gfx.Names:
  match new:
    case True{}:
      Names{Map.set(&2, U32, seen, name, next), (next + 1 : U32), next <> numbers, name <> distinct}
    case False{}:
      Names{seen, next, k <> numbers, distinct}

def Gfx.names.found(name: String, next: U32, numbers: List<&2, U32>, distinct: List<&2, String>,
  p: Map<&2, U32> & U32) -> Gfx.Names:
  (seen, +k) = p
  Gfx.names.put(U32.is_eq(k, Gfx.none()), name, k, seen, next, numbers, distinct)

def Gfx.names.add(+name: String, st: Gfx.Names) -> Gfx.Names:
  Names{seen, next, numbers, distinct} = st
  Gfx.names.found(name, next, numbers, distinct, Map.get(U32, Gfx.none(), seen, name))

# Each name numbered by its first appearance.
def Gfx.names(names: List<&2, String>, st: Gfx.Names) -> Gfx.Names:
  match names:
    case []:
      st
    case name <> rest:
      Gfx.names(rest, Gfx.names.add(name, st))

def Gfx.Names.numbers(n: Gfx.Names) -> List<&2, U32>:
  Names{seen, next, numbers, distinct} = n
  List.reverse(&2, U32, numbers)

def Gfx.Names.distinct(n: Gfx.Names) -> List<&2, String>:
  Names{seen, next, numbers, distinct} = n
  List.reverse(&2, String, distinct)

def Gfx.Names.count(n: Gfx.Names) -> U32:
  Names{seen, next, numbers, distinct} = n
  next

def Gfx.Names.number(n: Gfx.Names, name: String) -> U32:
  Names{seen, next, numbers, distinct} = n
  Pair.snd(Map<&2, U32>, U32, Map.get(U32, Gfx.none(), seen, name))

# Lumps by name
# -------------

# The directory by name; a later lump of a name replaces an earlier, as
# Doom's W_CheckNumForName searches from the end.
def Gfx.dir(lumps: List<&2, W.Wad.Lump>, m: Map<&2, W.Wad.Lump>) -> Map<&2, W.Wad.Lump>:
  match lumps:
    case []:
      m
    case W.Lump{pos, size, +name} <> rest:
      Gfx.dir(rest, Map.set(&2, W.Wad.Lump, m, name, W.Lump{pos, size, name}))

def Gfx.lump.get(+dir: Map<&2, W.Wad.Lump>, name: String) -> W.Wad.Lump:
  Pair.snd(Map<&2, W.Wad.Lump>, W.Wad.Lump,
    Map.get(W.Wad.Lump, W.Lump{Gfx.none(), 0, ""}, dir, name))

def Gfx.lump.pos(l: W.Wad.Lump) -> U32:
  W.Lump{pos, size, name} = l
  pos

def Gfx.lump.check(missing: Bool, who: String, name: String, l: W.Wad.Lump) ->
  Result<&1, &1, U32 & String, W.Wad.Lump>:
  match missing:
    case True{}:
      Fail{(1, who ++ ": " ++ name ++ " not found")}
    case False{}:
      Done{l}

# A lump by name, or Doom's error for who asked.
def Gfx.lump(+dir: Map<&2, W.Wad.Lump>, +who: String, +name: String) ->
  Result<&1, &1, U32 & String, W.Wad.Lump>:
  +l = Gfx.lump.get(dir, name)
  Gfx.lump.check(U32.is_eq(Gfx.lump.pos(l), Gfx.none()), who, name, l)

def Gfx.lookup.cons(l: Result<&1, &1, U32 & String, W.Wad.Lump>,
  rest: Result<&1, &1, U32 & String, List<&2, W.Wad.Lump>>) ->
  Result<&1, &1, U32 & String, List<&2, W.Wad.Lump>>:
  match l rest:
    case Fail{e} _:
      Fail{e}
    case Done{x} Fail{e}:
      Fail{e}
    case Done{x} Done{xs}:
      Done{x <> xs}

# The lump of every name, or the error for the first name the WAD lacks.
def Gfx.lookup(names: List<&2, String>, +dir: Map<&2, W.Wad.Lump>, +who: String) ->
  Result<&1, &1, U32 & String, List<&2, W.Wad.Lump>>:
  match names:
    case []:
      Done{[]}
    case name <> rest:
      Gfx.lookup.cons(Gfx.lump(dir, who, name), Gfx.lookup(rest, dir, who))

# Copying
# -------

type Gfx.Copy is Type:
  Copy{src: Array<U32>, dst: Array<U32>}

# count reads from src, stride bytes apart from from, each converted and
# written to dst from to on.
type Gfx.Job is Data:
  Job{from: U32, to: U32, count: U32}

def Gfx.copy.put(~conv: @+v: U32 -> U32, to: U32, dst: Array<U32>, p: Array<U32> & U32) -> Gfx.Copy:
  (src, v) = p
  Copy{src, Array.set(U32, dst, to, conv(v))}

def Gfx.copy.one(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, ~conv: @+v: U32 -> U32, from: U32,
  to: U32, st: Gfx.Copy) -> Gfx.Copy:
  Copy{src, dst} = st
  Gfx.copy.put(~conv, to, dst, read(src, from))

def Gfx.copy(~read: Array<U32> -> @+i: U32 -> Array<U32> & U32, ~conv: @+v: U32 -> U32, n: Nat,
  +stride: U32, +from: U32, +to: U32, st: Gfx.Copy) -> Gfx.Copy:
  match n:
    case 0n:
      st
    case 1n+m:
      Gfx.copy(~read, ~conv, m, stride, (from + stride : U32), (to + 1 : U32),
        Gfx.copy.one(~read, ~conv, from, to, st))

def Gfx.same(+x: U32) -> U32:
  x

def Gfx.copies(jobs: List<&2, Gfx.Job>, st: Gfx.Copy) -> Gfx.Copy:
  match jobs:
    case []:
      st
    case Job{from, to, count} <> rest:
      Gfx.copies(rest, Gfx.copy(~B.Bytes.at, ~Gfx.same, U32.to_nat(count), 1, from, to, st))

# A palette entry's three bytes, read as a little-endian word, as the
# window's 0xRRGGBB.
def Gfx.rgb(+v: U32) -> U32:
  (((v .&. 255) << 16n) .|. (v .&. 65280) .|. ((v >> 16n) .&. 255) : U32)

def Gfx.Copy.dst(st: Gfx.Copy) -> Array<U32>:
  Copy{src, dst} = st
  dst

# Loading
# -------

def Gfx.flat.jobs(flats: List<&2, W.Wad.Lump>, +to: U32) -> List<&2, Gfx.Job>:
  match flats:
    case []:
      []
    case l <> rest:
      Job{Gfx.lump.pos(l), to, 4096} <> Gfx.flat.jobs(rest, (to + 4096 : U32))

def Gfx.flat.bases(n: Nat, +to: U32) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      to <> Gfx.flat.bases(m, (to + 4096 : U32))

# The array sized for everything, then the first palette, the colormaps
# and the flats copied in.
def Gfx.build(a: Array<U32>, level: L.Level, +fl: Gfx.Names, pal: W.Wad.Lump, cmap: W.Wad.Lump,
  flats: List<&2, W.Wad.Lump>) -> Array<U32> & Gfx & L.Level:
  +nflats = Gfx.Names.count(fl)
  +size = (Gfx.lumps() + nflats * 4096 : U32)
  (Gfx.Copy.dst(Gfx.copies(Job{Gfx.lump.pos(cmap), Gfx.colormap(), 8704}
      <> Gfx.flat.jobs(flats, Gfx.lumps()),
      Gfx.copy(~B.Bytes.u32, ~Gfx.rgb, 256n, 3, Gfx.lump.pos(pal), Gfx.palette(),
        Copy{a, Array.new(U32, V.Vec.depth(size), 0)}))),
    Gfx{V.Vec.of_list(Gfx.flat.bases(U32.to_nat(nflats), Gfx.lumps()), nflats),
      V.Vec.of_list(Gfx.Names.numbers(fl), U32.from_nat(List.length(&2, U32, Gfx.Names.numbers(fl)))),
      Gfx.Names.number(fl, "F_SKY1")},
    level)

def Gfx.load.go(+lumps: List<&2, W.Wad.Lump>, q: Array<U32> & L.Level) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, +level) = q
  +dir = Gfx.dir(lumps, Map.new(&2, W.Wad.Lump))
  +fl = Gfx.names(L.Level.flatnames(level), Names{Map.new(&2, U32), 0, [], []})
  do Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
    pal : W.Wad.Lump <- Gfx.lump(dir, "W_GetNumForName", "PLAYPAL")
    cmap : W.Wad.Lump <- Gfx.lump(dir, "W_GetNumForName", "COLORMAP")
    flats : List<&2, W.Wad.Lump> <- Gfx.lookup(Gfx.Names.distinct(fl), dir, "R_FlatNumForName")
    return Gfx.build(a, level, fl, pal, cmap, flats)

# The level and its graphics from the WAD's bytes and directory, or
# Doom's error for a name the WAD lacks. The WAD's bytes are dropped.
def Gfx.load(p: Array<U32> & List<&2, W.Wad.Lump>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, +lumps) = p
  Gfx.load.go(lumps, L.Level.load((a, lumps)))

# Lookups
# -------

def Gfx.flat(+g: Gfx, pic: U32) -> U32:
  Gfx{flats, pics, sky} = g
  V.Vec.get(flats, pic)

def Gfx.floorpic(+g: Gfx, sector: U32) -> U32:
  Gfx{flats, pics, sky} = g
  V.Vec.get(pics, (sector * 2 : U32))

def Gfx.ceilpic(+g: Gfx, sector: U32) -> U32:
  Gfx{flats, pics, sky} = g
  V.Vec.get(pics, (sector * 2 + 1 : U32))

def Gfx.sky(+g: Gfx) -> U32:
  Gfx{flats, pics, sky} = g
  sky
