# Doom's R_AddLine, R_StoreWallRange and R_RenderSegLoop: a seg clipped
# to the view and against the solid columns, each fragment left stored
# as a wall range with its scale, and its columns drawn between the
# ceiling and floor clips, which they then narrow.
import Base
import ./bytes.bend as B
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

# The range
# ---------

# What R_StoreWallRange works out for a range and the seg loop steps a
# column at a time: the first column and the scale there; the wall's
# top and bottom rows, and the top of the lower and bottom of the upper
# texture, as fractions of 4096 with their steps; the middle, top and
# bottom textures, 0 for none; whether the floor and ceiling are marked;
# the palette index the wall is filled with.
type Segs.Rw is Data:
  Rw{start: U32, scale: U32, step: U32, topfrac: U32, topstep: U32, bottomfrac: U32,
    bottomstep: U32, pixhigh: U32, pixhighstep: U32, pixlow: U32, pixlowstep: U32, mid: U32,
    top: U32, bottom: U32, markfloor: Bool, markceiling: Bool, color: U32}

# A height above the eye as the row fraction at the range's first
# column, and its step a column: Doom's topfrac and topstep.
def Segs.frac(world: U32, scale: U32) -> U32:
  ((P.Project.centery() >> 4n) - F.Fixed.mul(F.Fixed.sarn(world, 4n), scale) : U32)

def Segs.fracstep(world: U32, step: U32) -> U32:
  F.Fixed.neg(F.Fixed.mul(step, F.Fixed.sarn(world, 4n)))

def Segs.rw.of(+gfx: G.Gfx, wall: D.Draw.Wall, +side: U32, +onesided: Bool, +sky2: Bool,
  +samefloor: Bool, +sameceil: Bool, f: L.Level.Sector, b: L.Level.Sector, +vz: U32, +skyfront: Bool,
  color: U32) -> Segs.Rw:
  D.Wall{index, start, stop, +scale, scale2, +step} = wall
  L.Sector{+ffloor, +fceil, +flight} = f
  L.Sector{+bfloor, +bceil, +blight} = b
  +worldtop = (Bool.pick(U32, sky2, bceil, fceil) - vz : U32)
  +worldbottom = (ffloor - vz : U32)
  +worldhigh = (bceil - vz : U32)
  +worldlow = (bfloor - vz : U32)
  +shut = Bool.or(onesided, Bool.or(F.Fixed.le(bceil, ffloor), F.Fixed.ge(bfloor, fceil)))
  +relit = Bool.not(U32.is_eq(blight, flight))
  Rw{start, scale, step, Segs.frac(worldtop, scale), Segs.fracstep(worldtop, step),
    Segs.frac(worldbottom, scale), Segs.fracstep(worldbottom, step),
    Segs.frac(worldhigh, scale), Segs.fracstep(worldhigh, step),
    Segs.frac(worldlow, scale), Segs.fracstep(worldlow, step),
    Bool.pick(U32, onesided, G.Gfx.mid(gfx, side), 0),
    Bool.pick(U32, Bool.and(Bool.not(onesided), F.Fixed.lt(worldhigh, worldtop)), G.Gfx.top(gfx, side), 0),
    Bool.pick(U32, Bool.and(Bool.not(onesided), F.Fixed.gt(worldlow, worldbottom)),
      G.Gfx.bottom(gfx, side), 0),
    Bool.and(F.Fixed.lt(ffloor, vz), Bool.or(shut, Bool.or(relit,
      Bool.or(Bool.not(U32.is_eq(worldlow, worldbottom)), Bool.not(samefloor))))),
    Bool.and(Bool.or(F.Fixed.gt(fceil, vz), skyfront), Bool.or(shut, Bool.or(relit,
      Bool.or(Bool.not(U32.is_eq(worldhigh, worldtop)), Bool.not(sameceil))))),
    color}

# The front and back sectors' part of R_StoreWallRange. Between two sky
# ceilings the upper wall is not drawn: the wall's top is the back's.
def Segs.rw(+view: P.View, +level: L.Level, +gfx: G.Gfx, seg: L.Level.Seg, wall: D.Draw.Wall,
  color: U32) -> Segs.Rw:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, side, +front, +back} = seg
  +onesided = U32.is_eq(back, L.Level.none())
  +skyfront = U32.is_eq(G.Gfx.ceilpic(gfx, front), G.Gfx.sky(gfx))
  Segs.rw.of(gfx, wall, side, onesided,
    Bool.and(Bool.not(onesided), Bool.and(skyfront, U32.is_eq(G.Gfx.ceilpic(gfx, back), G.Gfx.sky(gfx)))),
    U32.is_eq(G.Gfx.floorpic(gfx, back), G.Gfx.floorpic(gfx, front)),
    U32.is_eq(G.Gfx.ceilpic(gfx, back), G.Gfx.ceilpic(gfx, front)),
    L.Level.sector(level, front), L.Level.sector(level, back), P.View.z(view), skyfront, color)

# The seg loop
# ------------

type Segs.Cols is Type:
  Cols{mem: Array<U32>, rw: Segs.Rw}

def Segs.row(frac: U32) -> U32:
  F.Fixed.sarn(frac, 12n)

# Doom's R_RenderSegLoop for one column, given its ceiling and floor
# clips cc and fc: the wall's rows held inside them; a one-sided wall
# drawn whole and the column closed; else the upper wall down to the
# back's ceiling and the lower up from its floor, each narrowing its
# clip, or the clips narrowed to the wall's rows where a plane is
# marked.
def Segs.col.draw(+x: U32, rw: Segs.Rw, +cc: U32, +fc: U32, mem: Array<U32>) -> Array<U32>:
  Rw{+start, scale, step, topfrac, topstep, bottomfrac, bottomstep, pixhigh, pixhighstep, pixlow,
    pixlowstep, mid, top, bottom, markfloor, markceiling, +color} = rw
  +k = (x - start : U32)
  +yl = F.Fixed.max(Segs.row((topfrac + k * topstep + 4095 : U32)), (cc + 1 : U32))
  +yh = F.Fixed.min(Segs.row((bottomfrac + k * bottomstep : U32)), (fc - 1 : U32))
  +solid = Bool.not(U32.is_zero(mid))
  +upper = Bool.and(Bool.not(solid), Bool.not(U32.is_zero(top)))
  +lower = Bool.and(Bool.not(solid), Bool.not(U32.is_zero(bottom)))
  +high = F.Fixed.min(Segs.row((pixhigh + k * pixhighstep : U32)), (fc - 1 : U32))
  +cc2 = Bool.pick(U32, solid, 168, Bool.pick(U32, upper,
    Bool.pick(U32, F.Fixed.ge(high, yl), high, (yl - 1 : U32)),
    Bool.pick(U32, markceiling, (yl - 1 : U32), cc)))
  +low = F.Fixed.max(Segs.row((pixlow + k * pixlowstep + 4095 : U32)), (cc2 + 1 : U32))
  +fc2 = Bool.pick(U32, solid, 4294967295, Bool.pick(U32, lower,
    Bool.pick(U32, F.Fixed.le(low, yh), low, (yh + 1 : U32)),
    Bool.pick(U32, markfloor, (yh + 1 : U32), fc)))
  Array.set(U32, Array.set(U32,
    D.Draw.fill(D.Draw.fill(D.Draw.fill(mem, x, yl, Bool.pick(U32, solid, yh, (yl - 1 : U32)), color),
      x, yl, Bool.pick(U32, upper, high, (yl - 1 : U32)), color),
      x, Bool.pick(U32, lower, low, (yh + 1 : U32)), yh, color),
    (G.Gfx.ceilclip() + x : U32), cc2), (G.Gfx.floorclip() + x : U32), fc2)

def Segs.col.floor(+x: U32, +rw: Segs.Rw, cc: U32, p: Array<U32> & U32) -> Segs.Cols:
  (mem, fc) = p
  Cols{Segs.col.draw(x, rw, cc, fc, mem), rw}

def Segs.col.ceil(+x: U32, rw: Segs.Rw, p: Array<U32> & U32) -> Segs.Cols:
  (mem, cc) = p
  Segs.col.floor(x, rw, cc, B.Bytes.at(mem, (G.Gfx.floorclip() + x : U32)))

def Segs.col(i: Nat, st: Segs.Cols) -> Segs.Cols:
  Cols{mem, rw} = st
  +x = U32.from_nat(i)
  Segs.col.ceil(x, rw, B.Bytes.at(mem, (G.Gfx.ceilclip() + x : U32)))

def Segs.Cols.mem(st: Segs.Cols) -> Array<U32>:
  Cols{mem, rw} = st
  mem

# Light
# -----

# Doom's fake contrast: a wall along the x axis a light number darker,
# one along the y axis a number brighter; held to 0 and 15.
def Segs.lightnum(seg: L.Level.Seg, light: U32) -> U32:
  L.Seg{+x1, +y1, +x2, +y2, angle, offset, flags, side, front, back} = seg
  F.Fixed.max(0, F.Fixed.min(15, ((light >> 4n) - Bool.to_u32(U32.is_eq(y1, y2))
    + Bool.to_u32(Bool.and(Bool.not(U32.is_eq(y1, y2)), U32.is_eq(x1, x2))) : U32)))

# The colormap of a wall column at a scale.
def Segs.colormap(lightnum: U32, scale: U32) -> U32:
  (G.Gfx.colormap() + P.Project.scalelight(lightnum, U32.min((scale >> 12n : U32), 47)) * 256 : U32)

# Storing
# -------

def Segs.store.color(+view: P.View, +level: L.Level, +gfx: G.Gfx, seg: L.Level.Seg, +wall: D.Draw.Wall,
  solid: List<&2, C.Clip.Range>, walls: List<&2, D.Draw.Wall>, tasks: List<&2, D.Draw.Task>,
  p: Array<U32> & U32) -> D.Draw:
  D.Wall{index, +x1, +x2, scale1, scale2, step} = wall
  (mem, color) = p
  D.Draw{Segs.Cols.mem(D.Draw.each(~Segs.Cols, ~Segs.col, U32.to_nat((x2 - x1 + 1 : U32)), U32.to_nat(x1),
    Cols{mem, Segs.rw(view, level, gfx, seg, wall, color)})), solid, wall <> walls, tasks}

def Segs.scale1(wall: D.Draw.Wall) -> U32:
  D.Wall{index, x1, x2, scale1, scale2, step} = wall
  scale1

def Segs.front.light(+level: L.Level, seg: L.Level.Seg) -> U32:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, side, front, back} = seg
  L.Level.sector.light(level, front)

# The range is stored, its wall's palette index read through the
# colormap of its sector's light at its first scale, and its columns
# drawn.
def Segs.store.wall(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, +wall: D.Draw.Wall,
  st: D.Draw) -> D.Draw:
  D.Draw{mem, solid, walls, tasks} = st
  Segs.store.color(view, level, gfx, seg, wall, solid, walls, tasks, B.Bytes.at(mem,
    (Segs.colormap(Segs.lightnum(seg, Segs.front.light(level, seg)), Segs.scale1(wall)) + 96 : U32)))

# Doom's R_StoreWallRange for the columns of one gap.
def Segs.store(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, index: U32, angle1: U32,
  gap: C.Clip.Range, st: D.Draw) -> D.Draw:
  C.Range{first, last} = gap
  Segs.store.wall(view, level, gfx, seg, Segs.wall(view, index, U32.from_nat(first), U32.from_nat(last),
    Segs.normal(seg), Segs.distance(view, seg, Segs.normal(seg), angle1)), st)

def Segs.stores(gaps: List<&2, C.Clip.Range>, +view: P.View, +level: L.Level, +gfx: G.Gfx,
  +seg: L.Level.Seg, +index: U32, +angle1: U32, st: D.Draw) -> D.Draw:
  match gaps:
    case []:
      st
    case gap <> rest:
      Segs.stores(rest, view, level, gfx, seg, index, angle1,
        Segs.store(view, level, gfx, seg, index, angle1, gap, st))

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
def Segs.clip(draws: Bool, solid: Bool, +view: P.View, +level: L.Level, +gfx: G.Gfx,
  +seg: L.Level.Seg, index: U32, angle1: U32, +first: Nat, +last: Nat, st: D.Draw) -> D.Draw:
  match draws:
    case False{}:
      st
    case True{}:
      D.Draw{mem, +cols, walls, tasks} = st
      Segs.stores(C.Clip.gaps(first, last, cols), view, level, gfx, seg, index, angle1,
        D.Draw{mem, Bool.pick(List<&2, C.Clip.Range>, solid, C.Clip.add(first, last, cols), cols), walls,
          tasks})

def Segs.add.span(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, index: U32,
  angle1: U32, span: P.View.Span, st: D.Draw) -> D.Draw:
  match span:
    case P.Span{False{}, True{}, x1, x2}:
      +kind = Segs.kind.of(level, gfx, seg)
      Segs.clip(Bool.not(U32.is_zero(kind)), U32.is_eq(kind, 1), view, level, gfx, seg, index, angle1,
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
