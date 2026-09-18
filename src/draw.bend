# The draw's state: the one linear array and the lists Doom keeps in
# static arrays, here with no limit. One value threaded through the BSP
# walk, since every step reads what the last wrote.
import Base
import ./bytes.bend as B
import ./clip.bend as C
import ./gfx.bend as G

# The walk's work, a stack: a node or subsector to visit, a node's far
# child to visit if its box might show, a seg to add.
type Draw.Task is Data:
  Visit{node: U32}
  Check{node: U32, side: U32}
  Line{seg: U32}

# A stored wall range, Doom's drawseg: the seg, its first and last
# column, and its scale at each with the step between.
type Draw.Wall is Data:
  Wall{seg: U32, x1: U32, x2: U32, scale1: U32, scale2: U32, step: U32}

# mem: the frame, the clip arrays and the graphics. solid: the solid
# columns. walls: the stored ranges, newest first. tasks: the walk's
# stack.
type Draw is Type:
  Draw{mem: Array<U32>, solid: List<&2, C.Clip.Range>, walls: List<&2, Draw.Wall>,
    tasks: List<&2, Draw.Task>}

# Drawing
# -------

# f at every index from i, n of them, in order: the loop under every
# column and span, so that the law on which indices it reaches covers
# them all. The state carries what f needs, since a template's function
# is closed.
def Draw.each(~S: Type, ~f: Nat -> S -> S, n: Nat, +i: Nat, st: S) -> S:
  match n:
    case 0n:
      st
    case 1n+m:
      Draw.each(~S, ~f, m, 1n+i, f(i, st))

# The rows from yl to yh, none when yh is above yl, as Doom's column
# loop counts them.
def Draw.rows(+yl: U32, +yh: U32) -> Nat:
  U32.to_nat(Bool.pick(U32, U32.is_gt((yh - yl + 1 : U32), 200), 0, (yh - yl + 1 : U32)))

# A pixel's index in the frame.
def Draw.at(x: U32, row: Nat) -> U32:
  (G.Gfx.frame() + U32.from_nat(row) * 320 + x : U32)

# A column's state: the array, the column, the texture fraction at the
# next row with its step a row, the index of the texture column's
# texels, and of the colormap.
type Draw.Col is Type:
  Col{mem: Array<U32>, x: U32, frac: U32, step: U32, src: U32, cmap: U32}

def Draw.col.lit(row: Nat, +x: U32, +frac: U32, +step: U32, src: U32, cmap: U32, p: Array<U32> & U32) ->
  Draw.Col:
  (mem, c) = p
  Col{Array.set(U32, mem, Draw.at(x, row), c), x, (frac + step : U32), step, src, cmap}

def Draw.col.texel(row: Nat, x: U32, frac: U32, step: U32, src: U32, +cmap: U32, p: Array<U32> & U32) ->
  Draw.Col:
  (mem, t) = p
  Draw.col.lit(row, x, frac, step, src, cmap, B.Bytes.at(mem, (cmap + t : U32)))

# Doom's R_DrawColumn for one row: the texel at the fraction's whole
# part, wrapped to 128 rows, through the colormap.
def Draw.col.px(row: Nat, st: Draw.Col) -> Draw.Col:
  Col{mem, x, +frac, step, +src, cmap} = st
  Draw.col.texel(row, x, frac, step, src, cmap, B.Bytes.at(mem, (src + ((frac >> 16n) .&. 127) : U32)))

def Draw.Col.mem(st: Draw.Col) -> Array<U32>:
  Col{mem, x, frac, step, src, cmap} = st
  mem

# Column x from row yl to yh: the texture column at src, its row mid at
# the view's centre row, stepped iscale a row, lit through cmap.
def Draw.column(mem: Array<U32>, x: U32, +yl: U32, yh: U32, src: U32, mid: U32, +iscale: U32,
  cmap: U32) -> Array<U32>:
  Draw.Col.mem(Draw.each(~Draw.Col, ~Draw.col.px, Draw.rows(yl, yh), U32.to_nat(yl),
    Col{mem, x, (mid + (yl - 84) * iscale : U32), iscale, src, cmap}))

# n slots from i set to v.
def Draw.set(n: Nat, mem: Array<U32>, +i: U32, +v: U32) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Draw.set(m, Array.set(U32, mem, i, v), (i + 1 : U32), v)

# Doom's R_ClearPlanes: no column is clipped yet, the ceiling's clip
# above row 0 and the floor's below the last.
def Draw.clear(mem: Array<U32>) -> Array<U32>:
  Draw.set(320n, Draw.set(320n, mem, G.Gfx.ceilclip(), 4294967295), G.Gfx.floorclip(), 168)
