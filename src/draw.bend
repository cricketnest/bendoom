# The draw's state: the one linear array and the lists Doom keeps in
# static arrays, here with no limit. One value threaded through the BSP
# walk, since every step reads what the last wrote.
import Base
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

# A column fill's state: the array, the column and the palette index.
type Draw.Fill is Type:
  Fill{mem: Array<U32>, x: U32, color: U32}

def Draw.fill.px(row: Nat, st: Draw.Fill) -> Draw.Fill:
  Fill{mem, +x, +color} = st
  Fill{Array.set(U32, mem, Draw.at(x, row), color), x, color}

def Draw.Fill.mem(st: Draw.Fill) -> Array<U32>:
  Fill{mem, x, color} = st
  mem

# Column x from row yl to yh in one palette index.
def Draw.fill(mem: Array<U32>, x: U32, +yl: U32, yh: U32, color: U32) -> Array<U32>:
  Draw.Fill.mem(Draw.each(~Draw.Fill, ~Draw.fill.px, Draw.rows(yl, yh), U32.to_nat(yl), Fill{mem, x, color}))

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
