# Doom's R_AddLine and R_StoreWallRange: a seg clipped to the view and
# against the solid columns, and each fragment left stored as a wall
# range with its scale.
import Base
import ./fixed.bend as F
import ./angle.bend as A
import ./clip.bend as C
import ./level.bend as L
import ./gfx.bend as G
import ./project.bend as P
import ./draw.bend as D

# Storing
# -------

def Segs.step(+start: U32, +stop: U32, +scale1: U32, scale2: U32) -> U32:
  Bool.pick(U32, U32.is_gt(stop, start), F.Fixed.quot((scale2 - scale1 : U32), (stop - start : U32)), 0)

def Segs.wall(+view: P.View, index: U32, +start: U32, +stop: U32, +normal: U32, +distance: U32) ->
  D.Draw.Wall:
  +scale1 = P.View.scale(view, (P.View.angle(view) + P.View.xtoangle(view, start) : U32), normal, distance)
  +scale2 = Bool.pick(U32, U32.is_gt(stop, start),
    P.View.scale(view, (P.View.angle(view) + P.View.xtoangle(view, stop) : U32), normal, distance), scale1)
  D.Wall{index, start, stop, scale1, scale2, Segs.step(start, stop, scale1, scale2)}

# The wall's distance: the seg's first vertex's, times the sine of the
# angle the view makes with the wall.
def Segs.distance(+view: P.View, +seg: L.Level.Seg, +normal: U32, angle1: U32) -> U32:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, side, front, back} = seg
  F.Fixed.mul(P.View.dist_to(view, x1, y1), A.Angle.sin(P.View.sine(view), A.Angle.fine(
    (A.Angle.ang90() - U32.min(F.Fixed.abs((normal - angle1 : U32)), A.Angle.ang90()) : U32))))

def Segs.normal(seg: L.Level.Seg) -> U32:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, side, front, back} = seg
  (angle + A.Angle.ang90() : U32)

# Doom's R_StoreWallRange for the columns of one gap.
def Segs.store(+view: P.View, +seg: L.Level.Seg, index: U32, angle1: U32, gap: C.Clip.Range,
  st: D.Draw) -> D.Draw:
  C.Range{first, last} = gap
  D.Draw{mem, solid, walls, tasks} = st
  D.Draw{mem, solid, Segs.wall(view, index, U32.from_nat(first), U32.from_nat(last), Segs.normal(seg),
    Segs.distance(view, seg, Segs.normal(seg), angle1)) <> walls, tasks}

def Segs.stores(gaps: List<&2, C.Clip.Range>, +view: P.View, +seg: L.Level.Seg, +index: U32,
  +angle1: U32, st: D.Draw) -> D.Draw:
  match gaps:
    case []:
      st
    case gap <> rest:
      Segs.stores(rest, view, seg, index, angle1, Segs.store(view, seg, index, angle1, gap, st))

# Adding
# ------

# Doom's R_AddLine's verdict on a seg in view: 1 a solid wall (one-sided
# or a closed door), 2 a window, 0 a line with the same sector on both
# sides and no middle texture, which draws nothing.
def Segs.kind(f: L.Level.Sector, b: L.Level.Sector, onesided: Bool, samepics: Bool, nomid: Bool) -> U32:
  L.Sector{+ffloor, +fceil, flight} = f
  L.Sector{+bfloor, +bceil, blight} = b
  Bool.pick(U32, Bool.or(onesided, Bool.or(F.Fixed.le(bceil, ffloor), F.Fixed.ge(bfloor, fceil))), 1,
    Bool.pick(U32, Bool.not(Bool.and(U32.is_eq(bceil, fceil), U32.is_eq(bfloor, ffloor))), 2,
      Bool.pick(U32, Bool.and(samepics, Bool.and(U32.is_eq(blight, flight), nomid)), 0, 2)))

def Segs.kind.of(+level: L.Level, +gfx: G.Gfx, seg: L.Level.Seg) -> U32:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, side, +front, +back} = seg
  Segs.kind(L.Level.sector(level, front), L.Level.sector(level, back), U32.is_eq(back, L.Level.none()),
    Bool.and(U32.is_eq(G.Gfx.ceilpic(gfx, back), G.Gfx.ceilpic(gfx, front)),
      U32.is_eq(G.Gfx.floorpic(gfx, back), G.Gfx.floorpic(gfx, front))),
    U32.is_zero(G.Gfx.mid(gfx, side)))

# The gaps are stored, and a solid wall's columns join the solid list.
def Segs.clip(draws: Bool, solid: Bool, +view: P.View, +seg: L.Level.Seg, index: U32, angle1: U32,
  +first: Nat, +last: Nat, st: D.Draw) -> D.Draw:
  match draws:
    case False{}:
      st
    case True{}:
      D.Draw{mem, +cols, walls, tasks} = st
      Segs.stores(C.Clip.gaps(first, last, cols), view, seg, index, angle1,
        D.Draw{mem, Bool.pick(List<&2, C.Clip.Range>, solid, C.Clip.add(first, last, cols), cols), walls,
          tasks})

def Segs.add.span(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, index: U32,
  angle1: U32, span: P.View.Span, st: D.Draw) -> D.Draw:
  match span:
    case P.Span{False{}, True{}, x1, x2}:
      +kind = Segs.kind.of(level, gfx, seg)
      Segs.clip(Bool.not(U32.is_zero(kind)), U32.is_eq(kind, 1), view, seg, index, angle1,
        U32.to_nat(x1), U32.to_nat((x2 - 1 : U32)), st)
    case _:
      st

def Segs.add.seg(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, index: U32,
  st: D.Draw) -> D.Draw:
  L.Seg{+x1, +y1, x2, y2, angle, offset, flags, side, front, back} = seg
  Segs.add.span(view, level, gfx, seg, index, P.View.angle_to(view, x1, y1),
    P.View.span(view, P.View.angle_to(view, x1, y1), P.View.angle_to(view, x2, y2)), st)

# Doom's R_AddLine.
def Segs.add(+view: P.View, +level: L.Level, +gfx: G.Gfx, +index: U32, st: D.Draw) -> D.Draw:
  Segs.add.seg(view, level, gfx, L.Level.seg(level, index), index, st)
