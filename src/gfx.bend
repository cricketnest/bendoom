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
import ./fixed.bend as F
import ./level.bend as L

# flats: a flat number's index in the array. pics: a sector's floor and
# ceiling flat numbers, two a sector. sky: the sky flat's number. texs:
# five words a texture (width, height, patch count, width mask, first
# column), texture 0 being none. cols: every texture's columns, each the
# index of its texels in the array. sidetex: a side's top, bottom and
# middle texture numbers, three a side. skytex: the sky's texture.
type Gfx is Data:
  Gfx{flats: V.Vec, pics: V.Vec, sky: U32, texs: V.Vec, cols: V.Vec, sidetex: V.Vec, skytex: U32}

# The frame: 320 by 200 palette indices, row by row.
def Gfx.frame() -> U32:
  0

# The draw's clip arrays, one slot a column.
def Gfx.ceilclip() -> U32:
  64000

def Gfx.floorclip() -> U32:
  64320

# Where each row's open span starts, while a plane is drawn.
def Gfx.spanstart() -> U32:
  64640

def Gfx.palette() -> U32:
  65536

def Gfx.colormap() -> U32:
  65792

# 128 zeros: the texels of a column no patch covers.
def Gfx.void() -> U32:
  74496

def Gfx.lumps() -> U32:
  74624

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

# Composites
# ----------

# A post of a patch column to paste into a composed column: the index
# of the post's header, of the composed column, the patch's row in the
# texture (signed), and the texture's height.
type Gfx.Paste is Data:
  Paste{src: U32, dst: U32, oy: U32, height: U32}

# The post walk's state: done at the column's 255.
type Gfx.Post is Type:
  Post{done: Bool, mem: Array<U32>, src: U32}

def Gfx.posts.len(~C: Data, ~act: Array<U32> -> @+src: U32 -> @+delta: U32 -> @+len: U32 -> @+ctx: C -> Array<U32>,
  +src: U32, delta: U32, ctx: C, p: Array<U32> & U32) -> Gfx.Post:
  (mem, +len) = p
  Post{False{}, act(mem, src, delta, len, ctx), (src + len + 4 : U32)}

def Gfx.posts.if(~C: Data, ~act: Array<U32> -> @+src: U32 -> @+delta: U32 -> @+len: U32 -> @+ctx: C -> Array<U32>,
  end: Bool, mem: Array<U32>, +src: U32, delta: U32, ctx: C) -> Gfx.Post:
  match end:
    case True{}:
      Post{True{}, mem, src}
    case False{}:
      Gfx.posts.len(~C, ~act, src, delta, ctx, B.Bytes.at(mem, (src + 1 : U32)))

def Gfx.posts.top(~C: Data, ~act: Array<U32> -> @+src: U32 -> @+delta: U32 -> @+len: U32 -> @+ctx: C -> Array<U32>,
  src: U32, ctx: C, p: Array<U32> & U32) -> Gfx.Post:
  (mem, +delta) = p
  Gfx.posts.if(~C, ~act, U32.is_eq(delta, 255), mem, src, delta, ctx)

# A patch column's posts walked from the first's header, in the array:
# act on each, given the post's header index, its first row in the patch
# and its length; the composer pastes them, the masked pass draws them.
# The fuel outlasts any column.
def Gfx.posts(~C: Data, ~act: Array<U32> -> @+src: U32 -> @+delta: U32 -> @+len: U32 -> @+ctx: C -> Array<U32>,
  fuel: Nat, st: Gfx.Post, +ctx: C) -> Array<U32>:
  match fuel st:
    case _ Post{True{}, mem, src}:
      mem
    case 0n Post{False{}, mem, src}:
      mem
    case 1n+f Post{False{}, mem, +src}:
      Gfx.posts(~C, ~act, f, Gfx.posts.top(~C, ~act, src, ctx, B.Bytes.at(mem, src)), ctx)

def Gfx.move.put(to: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, v) = p
  Array.set(U32, mem, to, v)

# n slots copied up the same array.
def Gfx.move(n: Nat, +from: U32, +to: U32, mem: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Gfx.move(m, (from + 1 : U32), (to + 1 : U32), Gfx.move.put(to, B.Bytes.at(mem, from)))

# Doom's R_DrawColumnInCache for one post: pasted at the patch's row
# plus the post's, cut to the texture's height. A post cut at the top
# keeps its first texels, not its last, as Doom's memcpy does.
def Gfx.paste.post(mem: Array<U32>, +src: U32, +delta: U32, +len: U32, +paste: Gfx.Paste) -> Array<U32>:
  Paste{psrc, +dst, +oy, +height} = paste
  +at = (oy + delta : U32)
  +row = F.Fixed.max(at, 0)
  Gfx.move(U32.to_nat(F.Fixed.max(F.Fixed.min((len + F.Fixed.min(at, 0) : U32), (height - row : U32)), 0)),
    (src + 3 : U32), (dst + row : U32), mem)

def Gfx.paste.src(p: Gfx.Paste) -> U32:
  Paste{src, dst, oy, height} = p
  src

# Every post of each patch column, in order, so a later patch covers an
# earlier as in Doom's composite.
def Gfx.pastes(ps: List<&2, Gfx.Paste>, mem: Array<U32>) -> Array<U32>:
  match ps:
    case []:
      mem
    case +p <> rest:
      Gfx.pastes(rest, Gfx.posts(~Gfx.Paste, ~Gfx.paste.post, 256n, Post{False{}, mem, Gfx.paste.src(p)}, p))

# Textures
# --------

# The patches as copied: a patch's index in the array, its width, and
# where its column offsets start in cols, the offsets of all of them.
type Gfx.Patches is Data:
  Patches{base: V.Vec, width: V.Vec, start: V.Vec, cols: V.Vec}

# A patch placed in a texture: its column and row there (signed), and
# which patch.
type Gfx.Placed is Data:
  Placed{x: U32, y: U32, patch: U32}

# The assembly's state: the columns, texture words and pastes so far,
# newest first, the next composed column's index, and the columns so
# far.
type Gfx.Asm is Data:
  Asm{cols: List<&2, U32>, texs: List<&2, U32>, pastes: List<&2, Gfx.Paste>, comp: U32, ncols: U32}

# A 16-bit word as a signed number.
def Gfx.s16(w: U32) -> U32:
  F.Fixed.sarn((w << 16n : U32), 16n)

def Gfx.covering.if(covers: Bool, +ps: Gfx.Patches, +x: U32, placed: Gfx.Placed,
  rest: List<&2, Gfx.Placed>) -> List<&2, Gfx.Placed>:
  match covers:
    case False{}:
      rest
    case True{}:
      Patches{base, width, start, cols} = ps
      Placed{px, y, +patch} = placed
      Placed{(V.Vec.get(base, patch) + V.Vec.get(cols, (V.Vec.get(start, patch) + x - px : U32)) : U32),
        y, patch} <> rest

# The patches over texture column x, in order, each with x replaced by
# the index of its column's first post.
def Gfx.covering(placed: List<&2, Gfx.Placed>, +ps: Gfx.Patches, +x: U32) -> List<&2, Gfx.Placed>:
  match placed:
    case []:
      []
    case Placed{+px, +y, +patch} <> rest:
      Patches{base, width, start, cols} = ps
      Gfx.covering.if(Bool.and(F.Fixed.le(px, x), F.Fixed.lt(x, (px + V.Vec.get(width, patch) : U32))),
        ps, x, Placed{px, y, patch}, Gfx.covering(rest, ps, x))

def Gfx.col.pastes(over: List<&2, Gfx.Placed>, +dst: U32, +height: U32, acc: List<&2, Gfx.Paste>) ->
  List<&2, Gfx.Paste>:
  match over:
    case []:
      acc
    case Placed{src, y, patch} <> rest:
      Gfx.col.pastes(rest, dst, height, Paste{src, dst, y, height} <> acc)

# Doom's R_GenerateLookup for one column: under one patch it is that
# patch's column, past the first post's three header bytes; under
# several it is composed; under none it is the void.
def Gfx.col(over: List<&2, Gfx.Placed>, +height: U32, asm: Gfx.Asm) -> Gfx.Asm:
  match over:
    case []:
      Asm{cols, texs, pastes, comp, ncols} = asm
      Asm{Gfx.void() <> cols, texs, pastes, comp, (ncols + 1 : U32)}
    case Placed{src, y, patch} <> []:
      Asm{cols, texs, pastes, comp, ncols} = asm
      Asm{(src + 3 : U32) <> cols, texs, pastes, comp, (ncols + 1 : U32)}
    case a <> b <> rest:
      Asm{cols, texs, pastes, +comp, ncols} = asm
      Asm{comp <> cols, texs, Gfx.col.pastes(a <> b <> rest, comp, height, pastes),
        (comp + height : U32), (ncols + 1 : U32)}

def Gfx.cols(n: Nat, +placed: List<&2, Gfx.Placed>, +ps: Gfx.Patches, +height: U32, +x: U32,
  asm: Gfx.Asm) -> Gfx.Asm:
  match n:
    case 0n:
      asm
    case 1n+m:
      Gfx.cols(m, placed, ps, height, (x + 1 : U32), Gfx.col(Gfx.covering(placed, ps, x), height, asm))

def Gfx.mask.go(fuel: Nat, +width: U32, +j: U32, done: Bool) -> U32:
  match fuel done:
    case _ True{}:
      (j - 1 : U32)
    case 0n _:
      (j - 1 : U32)
    case 1n+f False{}:
      Gfx.mask.go(f, width, (j << 1n : U32), U32.is_gt((j << 2n : U32), width))

# Doom's texturewidthmask: the largest power of two in the width, less
# one.
def Gfx.mask(+width: U32) -> U32:
  Gfx.mask.go(16n, width, 1, U32.is_gt(2, width))

# A texture's patches from the words read (x, y and patch number a
# patch) and each one's patch index.
def Gfx.placed(n: Nat, words: List<&2, U32>, indices: List<&2, U32>) -> List<&2, Gfx.Placed>:
  match n words indices:
    case 1n+m x <> y <> num <> ws i <> more:
      Placed{Gfx.s16(x), Gfx.s16(y), i} <> Gfx.placed(m, ws, more)
    case _ _ _:
      []

def Gfx.texture(+width: U32, +height: U32, +count: U32, +placed: List<&2, Gfx.Placed>,
  +ps: Gfx.Patches, asm: Gfx.Asm) -> Gfx.Asm:
  Asm{cols, texs, pastes, comp, +ncols} = asm
  Gfx.cols(U32.to_nat(width), placed, ps, height, 0,
    Asm{cols, ncols <> Gfx.mask(width) <> count <> height <> width <> texs, pastes, comp, ncols})

# Every texture in number order: the headers are width, height and patch
# count a texture; the words and indices are consumed a texture's
# patches at a time.
def Gfx.textures(headers: List<&2, U32>, +words: List<&2, U32>, +indices: List<&2, U32>,
  +ps: Gfx.Patches, asm: Gfx.Asm) -> Gfx.Asm:
  match headers:
    case +width <> +height <> +count <> rest:
      Gfx.textures(rest, List.drop(&2, U32, words, U32.to_nat((count * 3 : U32))),
        List.drop(&2, U32, indices, U32.to_nat(count)), ps,
        Gfx.texture(width, height, count, Gfx.placed(U32.to_nat(count), words, indices), ps, asm))
    case _:
      asm

# Loading
# -------

# What the flats' half of the load found, for the textures' half.
type Gfx.Base is Data:
  Base{level: L.Level, fl: Gfx.Names, pal: W.Wad.Lump, cmap: W.Wad.Lump, flats: List<&2, W.Wad.Lump>}

def Gfx.lump.size(l: W.Wad.Lump) -> U32:
  W.Lump{pos, size, name} = l
  size

# A copy of each lump, one after another from to.
def Gfx.jobs(lumps: List<&2, W.Wad.Lump>, +to: U32) -> List<&2, Gfx.Job>:
  match lumps:
    case []:
      []
    case +l <> rest:
      Job{Gfx.lump.pos(l), to, Gfx.lump.size(l)} <> Gfx.jobs(rest, (to + Gfx.lump.size(l) : U32))

# Where each of a list of sizes starts, laid end to end from at, and
# then where the last ends.
def Gfx.starts(sizes: List<&2, U32>, +at: U32) -> List<&2, U32>:
  match sizes:
    case []:
      at <> []
    case size <> rest:
      at <> Gfx.starts(rest, (at + size : U32))

def Gfx.sizes(lumps: List<&2, W.Wad.Lump>) -> List<&2, U32>:
  match lumps:
    case []:
      []
    case l <> rest:
      Gfx.lump.size(l) <> Gfx.sizes(rest)

def Gfx.flat.lumps(flats: List<&2, W.Wad.Lump>) -> List<&2, W.Wad.Lump>:
  match flats:
    case []:
      []
    case W.Lump{pos, size, name} <> rest:
      W.Lump{pos, 4096, name} <> Gfx.flat.lumps(rest)

def Gfx.last(xs: List<&2, U32>) -> U32:
  Maybe.default(&2, U32, List.last(&2, U32, xs), 0)

def Gfx.Asm.comp(asm: Gfx.Asm) -> U32:
  Asm{cols, texs, pastes, comp, ncols} = asm
  comp

def Gfx.Asm.pastes(asm: Gfx.Asm) -> List<&2, Gfx.Paste>:
  Asm{cols, texs, pastes, comp, ncols} = asm
  List.reverse(&2, Gfx.Paste, pastes)

def Gfx.Asm.texs(asm: Gfx.Asm) -> V.Vec:
  Asm{cols, texs, pastes, comp, ncols} = asm
  V.Vec.of(List.reverse(&2, U32, texs))

def Gfx.Asm.cols(asm: Gfx.Asm) -> V.Vec:
  Asm{cols, texs, pastes, comp, ncols} = asm
  V.Vec.of(List.reverse(&2, U32, cols))

# The array sized for everything; the first palette, the colormaps, the
# flats and the patches copied in; the composed columns pasted.
def Gfx.build(a: Array<U32>, base: Gfx.Base, +tn: Gfx.Names, +fbases: List<&2, U32>,
  plumps: List<&2, W.Wad.Lump>, +asm: Gfx.Asm) -> Array<U32> & Gfx & L.Level:
  Base{level, +fl, pal, cmap, flats} = base
  (Gfx.pastes(Gfx.Asm.pastes(asm), Gfx.Copy.dst(Gfx.copies(
      Job{Gfx.lump.pos(cmap), Gfx.colormap(), 8704} <> List.append(&2, Gfx.Job,
        Gfx.jobs(Gfx.flat.lumps(flats), Gfx.lumps()), Gfx.jobs(plumps, Gfx.last(fbases))),
      Gfx.copy(~B.Bytes.u32, ~Gfx.rgb, 256n, 3, Gfx.lump.pos(pal), Gfx.palette(),
        Copy{a, Array.new(U32, V.Vec.depth((Gfx.Asm.comp(asm) + 128 : U32)), 0)})))),
    Gfx{V.Vec.of(fbases), V.Vec.of(Gfx.Names.numbers(fl)), Gfx.Names.number(fl, "F_SKY1"),
      Gfx.Asm.texs(asm), Gfx.Asm.cols(asm), V.Vec.of(Gfx.Names.numbers(tn)),
      Gfx.Names.number(tn, "SKY1")},
    level)

# The flats end where the patches start, the patches where the composed
# columns do; texture 0 is none, five zero words.
def Gfx.layout(a: Array<U32>, +base: Gfx.Base, tn: Gfx.Names, headers: List<&2, U32>,
  words: List<&2, U32>, indices: List<&2, U32>, +plumps: List<&2, W.Wad.Lump>, widths: List<&2, U32>,
  +colofs: List<&2, List<&2, U32>>) -> Array<U32> & Gfx & L.Level:
  Base{level, +fl, pal, cmap, flats} = base
  +fbases = Gfx.starts(Gfx.sizes(Gfx.flat.lumps(flats)), Gfx.lumps())
  +pbases = Gfx.starts(Gfx.sizes(plumps), Gfx.last(fbases))
  +ws = widths
  Gfx.build(a, base, tn, fbases, plumps,
    Gfx.textures(headers, words, indices,
      Patches{V.Vec.of(pbases), V.Vec.of(ws), V.Vec.of(Gfx.starts(ws, 0)),
        V.Vec.of(List.concat(&2, U32, colofs))},
      Asm{[], [0, 0, 0, 0, 0], [], Gfx.last(pbases), 0}))

# The offsets of the given fields from each lump's position.
def Gfx.plan(lumps: List<&2, W.Wad.Lump>, +fields: List<&2, U32>) -> List<&2, U32>:
  match lumps:
    case []:
      []
    case l <> rest:
      B.Bytes.fields.one(fields, Gfx.lump.pos(l), Gfx.plan(rest, fields))

# A run of count records of stride bytes from each lump's position plus
# skip, the counts given lump by lump.
def Gfx.runs(lumps: List<&2, W.Wad.Lump>, counts: List<&2, U32>, +skip: U32, +stride: U32,
  +fields: List<&2, U32>) -> List<&2, List<&2, U32>>:
  match lumps counts:
    case l <> ls count <> cs:
      B.Bytes.fields(U32.to_nat(count), (Gfx.lump.pos(l) + skip : U32), stride, fields)
        <> Gfx.runs(ls, cs, skip, stride, fields)
    case _ _:
      []

def Gfx.load.cols(+base: Gfx.Base, tn: Gfx.Names, headers: List<&2, U32>, words: List<&2, U32>,
  indices: List<&2, U32>, plumps: List<&2, W.Wad.Lump>, widths: List<&2, U32>,
  p: Array<U32> & List<&2, List<&2, U32>>) -> Array<U32> & Gfx & L.Level:
  (a, colofs) = p
  Gfx.layout(a, base, tn, headers, words, indices, plumps, widths, colofs)

# Each patch's width, then its column offsets.
def Gfx.load.widths(+base: Gfx.Base, tn: Gfx.Names, headers: List<&2, U32>, words: List<&2, U32>,
  indices: List<&2, U32>, +plumps: List<&2, W.Wad.Lump>, p: Array<U32> & List<&2, U32>) ->
  Array<U32> & Gfx & L.Level:
  (a, +widths) = p
  Gfx.load.cols(base, tn, headers, words, indices, plumps, widths,
    B.Bytes.lists(~U32, ~B.Bytes.u32, Gfx.runs(plumps, widths, 8, 4, [0]), a))

def Gfx.load.patches(+base: Gfx.Base, tn: Gfx.Names, headers: List<&2, U32>, words: List<&2, U32>,
  indices: List<&2, U32>, a: Array<U32>, +plumps: List<&2, W.Wad.Lump>) -> Array<U32> & Gfx & L.Level:
  Gfx.load.widths(base, tn, headers, words, indices, plumps,
    B.Bytes.each(~U32, ~B.Bytes.u16, Gfx.plan(plumps, [0]), a))

# The patches numbered by name, so one used by several textures is
# copied once.
def Gfx.load.pnames(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, tn: Gfx.Names, headers: List<&2, U32>,
  words: List<&2, U32>, p: Array<U32> & List<&2, String>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, names) = p
  +pn = Gfx.names(names, Names{Map.new(&2, U32), 0, [], []})
  Result.map(&1, &1, U32 & String, List<&2, W.Wad.Lump>, Array<U32> & Gfx & L.Level,
    plumps => Gfx.load.patches(base, tn, headers, words, Gfx.Names.numbers(pn), a, plumps),
    Gfx.lookup(Gfx.Names.distinct(pn), dir, "R_InitTextures: missing patch"))

# The index in PNAMES of the name of each patch number.
def Gfx.pname.plan(words: List<&2, U32>, +pnames: U32) -> List<&2, U32>:
  match words:
    case x <> y <> num <> rest:
      (pnames + 4 + num * 8 : U32) <> Gfx.pname.plan(rest, pnames)
    case _:
      []

def Gfx.load.words(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, tn: Gfx.Names, headers: List<&2, U32>,
  pnames: W.Wad.Lump, p: Array<U32> & List<&2, List<&2, U32>>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, lists) = p
  +words = List.concat(&2, U32, lists)
  Gfx.load.pnames(base, dir, tn, headers, words,
    B.Bytes.each(~String, ~B.Bytes.name, Gfx.pname.plan(words, Gfx.lump.pos(pnames)), a))

def Gfx.counts(headers: List<&2, U32>) -> List<&2, U32>:
  match headers:
    case width <> height <> count <> rest:
      count <> Gfx.counts(rest)
    case _:
      []

# Each texture's width, height and patch count, then its patches' x, y
# and patch number.
def Gfx.load.headers(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, tn: Gfx.Names,
  +defs: List<&2, W.Wad.Lump>, pnames: W.Wad.Lump, p: Array<U32> & List<&2, U32>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, +headers) = p
  Gfx.load.words(base, dir, tn, headers, pnames,
    B.Bytes.lists(~U32, ~B.Bytes.u16, Gfx.runs(defs, Gfx.counts(headers), 22, 10, [0, 2, 4]), a))

# The definitions by name, an earlier one winning, as Doom's search
# runs from the first.
def Gfx.defs(names: List<&2, String>, offs: List<&2, U32>) -> Map<&2, W.Wad.Lump>:
  match names offs:
    case +name <> ns off <> os:
      Map.set(&2, W.Wad.Lump, Gfx.defs(ns, os), name, W.Lump{off, 0, name})
    case _ _:
      Map.new(&2, W.Wad.Lump)

# Doom's texture 0 is no texture, whatever its name: a side naming it
# names none.
def Gfx.rename(names: List<&2, String>, +first: String) -> List<&2, String>:
  match names:
    case []:
      []
    case +name <> rest:
      Bool.pick(String, String.eq(name, first), "-", name) <> Gfx.rename(rest, first)

def Gfx.first(names: List<&2, String>) -> String:
  match names:
    case []:
      "-"
    case name <> rest:
      name

# The textures the sides name and the sky numbered from 1, none being 0.
def Gfx.load.names(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, pnames: W.Wad.Lump,
  +offs: List<&2, U32>, p: Array<U32> & List<&2, String>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  Base{+level, fl, pal, cmap, flats} = base
  (a, +names) = p
  +tn = Gfx.names(Gfx.rename(List.append(&2, String, L.Level.texnames(level), ["SKY1"]),
    Gfx.first(names)), Names{Map.set(&2, U32, Map.new(&2, U32), "-", 0), 1, [], ["-"]})
  Result.bind(&1, &1, U32 & String, List<&2, W.Wad.Lump>, Array<U32> & Gfx & L.Level,
    Gfx.lookup(List.drop(&2, String, Gfx.Names.distinct(tn), 1n), Gfx.defs(names, offs),
      "R_TextureNumForName"),
    +defs => Gfx.load.headers(base, dir, tn, defs, pnames,
      B.Bytes.each(~U32, ~B.Bytes.u16, Gfx.plan(defs, [12, 14, 20]), a)))

# A texture lump's definition offsets made absolute, lump after lump.
def Gfx.absolute(lumps: List<&2, W.Wad.Lump>, lists: List<&2, List<&2, U32>>) -> List<&2, U32>:
  match lumps lists:
    case l <> ls offs <> os:
      List.append(&2, U32, B.Bytes.fields.one(offs, Gfx.lump.pos(l), []), Gfx.absolute(ls, os))
    case _ _:
      []

def Gfx.load.offs(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, pnames: W.Wad.Lump,
  texlumps: List<&2, W.Wad.Lump>, p: Array<U32> & List<&2, List<&2, U32>>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, lists) = p
  +offs = Gfx.absolute(texlumps, lists)
  Gfx.load.names(base, dir, pnames, offs, B.Bytes.each(~String, ~B.Bytes.name, offs, a))

def Gfx.load.counts(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, pnames: W.Wad.Lump,
  +texlumps: List<&2, W.Wad.Lump>, p: Array<U32> & List<&2, U32>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, counts) = p
  Gfx.load.offs(base, dir, pnames, texlumps,
    B.Bytes.lists(~U32, ~B.Bytes.u32, Gfx.runs(texlumps, counts, 4, 4, [0]), a))

def Gfx.present(l: W.Wad.Lump) -> Bool:
  Bool.not(U32.is_eq(Gfx.lump.pos(l), Gfx.none()))

# The texture definitions are TEXTURE1's and then TEXTURE2's, when the
# WAD has the second.
def Gfx.texlumps(+dir: Map<&2, W.Wad.Lump>, texture1: W.Wad.Lump) -> List<&2, W.Wad.Lump>:
  texture1 <> List.filter(~W.Wad.Lump, ~Gfx.present, [Gfx.lump.get(dir, "TEXTURE2")])

# Each lump's count, then its offsets, then the name at each.
def Gfx.load.textures(+base: Gfx.Base, +dir: Map<&2, W.Wad.Lump>, a: Array<U32>, pnames: W.Wad.Lump,
  +texture1: W.Wad.Lump) -> Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  Gfx.load.counts(base, dir, pnames, Gfx.texlumps(dir, texture1),
    B.Bytes.each(~U32, ~B.Bytes.u32, Gfx.plan(Gfx.texlumps(dir, texture1), [0]), a))

def Gfx.load.go(+lumps: List<&2, W.Wad.Lump>, q: Array<U32> & L.Level) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, +level) = q
  +dir = Gfx.dir(lumps, Map.new(&2, W.Wad.Lump))
  +fl = Gfx.names(L.Level.flatnames(level), Names{Map.new(&2, U32), 0, [], []})
  do Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
    pal : W.Wad.Lump <- Gfx.lump(dir, "W_GetNumForName", "PLAYPAL")
    cmap : W.Wad.Lump <- Gfx.lump(dir, "W_GetNumForName", "COLORMAP")
    flats : List<&2, W.Wad.Lump> <- Gfx.lookup(Gfx.Names.distinct(fl), dir, "R_FlatNumForName")
    pnames : W.Wad.Lump <- Gfx.lump(dir, "W_GetNumForName", "PNAMES")
    texture1 : W.Wad.Lump <- Gfx.lump(dir, "W_GetNumForName", "TEXTURE1")
    Gfx.load.textures(Base{level, fl, pal, cmap, flats}, dir, a, pnames, texture1)

# The level and its graphics from the WAD's bytes and directory, or
# Doom's error for a name the WAD lacks. The WAD's bytes are dropped.
def Gfx.load(p: Array<U32> & List<&2, W.Wad.Lump>) ->
  Result<&1, &1, U32 & String, Array<U32> & Gfx & L.Level>:
  (a, +lumps) = p
  Gfx.load.go(lumps, L.Level.load((a, lumps)))

# The level and its graphics from the WAD BENDOOM_IWAD names; a WAD that
# cannot be read, or a name it lacks, ends the program with the error.
def Gfx.open() -> IO(Array<U32> & Gfx & L.Level):
  do IO<Array<U32> & Gfx & L.Level>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    IO.pass(Array<U32> & Gfx & L.Level, Gfx.load(W.Wad.dir(bytes)))

# Lookups
# -------

def Gfx.flat(+g: Gfx, pic: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  V.Vec.get(flats, pic)

def Gfx.floorpic(+g: Gfx, sector: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  V.Vec.get(pics, (sector * 2 : U32))

def Gfx.ceilpic(+g: Gfx, sector: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  V.Vec.get(pics, (sector * 2 + 1 : U32))

def Gfx.sky(+g: Gfx) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  sky

def Gfx.skytex(+g: Gfx) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  skytex

# A side's texture numbers, 0 for none.
def Gfx.top(+g: Gfx, side: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  V.Vec.get(sidetex, (side * 3 : U32))

def Gfx.bottom(+g: Gfx, side: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  V.Vec.get(sidetex, (side * 3 + 1 : U32))

def Gfx.mid(+g: Gfx, side: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  V.Vec.get(sidetex, (side * 3 + 2 : U32))

def Gfx.tex.width(+g: Gfx, t: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  V.Vec.get(texs, (t * 5 : U32))

# A texture's height in fixed point, as pegging uses it.
def Gfx.tex.height(+g: Gfx, t: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  F.Fixed.of_map(V.Vec.get(texs, (t * 5 + 1 : U32)))

def Gfx.tex.patches(+g: Gfx, t: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  V.Vec.get(texs, (t * 5 + 2 : U32))

def Gfx.tex.mask(+g: Gfx, t: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  V.Vec.get(texs, (t * 5 + 3 : U32))

# Where a texture's columns start in the column table.
def Gfx.tex.first(+g: Gfx, t: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  V.Vec.get(texs, (t * 5 + 4 : U32))

# Doom's R_GetColumn, the texture's part looked up beforehand: the index
# of a texture column's texels, the column wrapped by the width mask. A
# patch column's first post header sits three before it.
def Gfx.column.at(+g: Gfx, first: U32, mask: U32, col: U32) -> U32:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  V.Vec.get(cols, (first + (col .&. mask) : U32))

def Gfx.column(+g: Gfx, +t: U32, col: U32) -> U32:
  Gfx.column.at(g, Gfx.tex.first(g, t), Gfx.tex.mask(g, t), col)

# The sides' texture numbers as loaded, which a state starts from.
def Gfx.sidetex(g: Gfx) -> V.Vec:
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex} = g
  sidetex

# The graphics with a state's side textures where the renderer looks.
def Gfx.sided(g: Gfx, sidetex: V.Vec) -> Gfx:
  Gfx{flats, pics, sky, texs, cols, loaded, skytex} = g
  Gfx{flats, pics, sky, texs, cols, sidetex, skytex}
