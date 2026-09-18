# Doom's R_AddLine, R_StoreWallRange and R_RenderSegLoop: a seg clipped
# to the view and against the solid columns, each fragment left stored
# as a wall range with its scale, and its columns drawn between the
# ceiling and floor clips, which they then narrow.
import Base
import ./vec.bend as V
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

# A range's geometry, from its seg and the angle to the seg's first
# vertex: the wall's normal; its distance, the first vertex's times the
# sine of the angle the view makes with the wall; the texture offset
# where the view meets it, the first vertex's distance along the wall
# plus the side's and the seg's offsets; and the angle its texture
# columns are measured from.
type Segs.Geo is Data:
  Geo{normal: U32, distance: U32, offset: U32, centerangle: U32}

def Segs.geo.of(+view: P.View, +normal: U32, +delta: U32, +hyp: U32, offsets: U32) -> Segs.Geo:
  +sine = P.View.sine(view)
  +along = F.Fixed.mul(hyp, A.Angle.sin(sine, A.Angle.fine(U32.min(
    Bool.pick(U32, U32.is_gt(delta, A.Angle.ang180()), F.Fixed.neg(delta), delta), A.Angle.ang90()))))
  Geo{normal,
    F.Fixed.mul(hyp, A.Angle.sin(sine, A.Angle.fine(
      (A.Angle.ang90() - U32.min(F.Fixed.abs(delta), A.Angle.ang90()) : U32)))),
    (Bool.pick(U32, U32.is_lt(delta, A.Angle.ang180()), F.Fixed.neg(along), along) + offsets : U32),
    (A.Angle.ang90() + P.View.angle(view) - normal : U32)}

def Segs.geo(+view: P.View, seg: L.Level.Seg, side: L.Level.Side, angle1: U32) -> Segs.Geo:
  L.Seg{x1, y1, x2, y2, +angle, offset, flags, sidedef, front, back} = seg
  L.Side{xoff, yoff, sector} = side
  Segs.geo.of(view, (angle + A.Angle.ang90() : U32), (angle + A.Angle.ang90() - angle1 : U32),
    P.View.dist_to(view, x1, y1), (xoff + offset : U32))

def Segs.wall(+view: P.View, index: U32, +start: U32, +stop: U32, geo: Segs.Geo) -> D.Draw.Wall:
  Geo{+normal, +distance, offset, centerangle} = geo
  +scale1 = P.View.scale(view, (P.View.angle(view) + P.View.xtoangle(view, start) : U32), normal, distance)
  +scale2 = Bool.pick(U32, U32.is_gt(stop, start),
    P.View.scale(view, (P.View.angle(view) + P.View.xtoangle(view, stop) : U32), normal, distance), scale1)
  D.Wall{index, start, stop, scale1, scale2, Segs.step(start, stop, scale1, scale2)}

# Light
# -----

# Doom's fake contrast: a wall along the x axis a light number darker,
# one along the y axis a number brighter; held to 0 and 15.
def Segs.lightnum(seg: L.Level.Seg, light: U32) -> U32:
  L.Seg{+x1, +y1, +x2, +y2, angle, offset, flags, side, front, back} = seg
  F.Fixed.max(0, F.Fixed.min(15, ((light >> 4n) - Bool.to_u32(U32.is_eq(y1, y2))
    + Bool.to_u32(Bool.and(Bool.not(U32.is_eq(y1, y2)), U32.is_eq(x1, x2))) : U32)))

# The range
# ---------

# What R_StoreWallRange works out for a range and the seg loop steps a
# column at a time: the first column and the scale there; the wall's
# top and bottom rows, and the top of the lower and bottom of the upper
# texture, as fractions of 4096 with their steps; the middle, top and
# bottom textures, 0 for none, each with the row of its texture at the
# eye's height; whether the floor and ceiling are marked; the light
# number; and the geometry its texture columns come from.
type Segs.Rw is Data:
  Rw{start: U32, scale: U32, step: U32, topfrac: U32, topstep: U32, bottomfrac: U32,
    bottomstep: U32, pixhigh: U32, pixhighstep: U32, pixlow: U32, pixlowstep: U32, mid: U32,
    top: U32, bottom: U32, midmid: U32, topmid: U32, bottommid: U32, markfloor: Bool,
    markceiling: Bool, lightnum: U32, geo: Segs.Geo}

# A height above the eye as the row fraction at the range's first
# column, and its step a column: Doom's topfrac and topstep.
def Segs.frac(world: U32, scale: U32) -> U32:
  ((P.Project.centery() >> 4n) - F.Fixed.mul(F.Fixed.sarn(world, 4n), scale) : U32)

def Segs.fracstep(world: U32, step: U32) -> U32:
  F.Fixed.neg(F.Fixed.mul(step, F.Fixed.sarn(world, 4n)))

# What the two sectors and the side say of a range. The line's flags peg
# its textures: a one-sided wall's hangs from the ceiling, or stands on
# the floor when pegged to the bottom; an upper wall's stands on the
# back's ceiling, or hangs from the front's when pegged to the top; a
# lower wall's hangs from the back's floor, or from the front's ceiling
# when pegged to the bottom. Each then moves by the side's row offset.
def Segs.rw.of(+gfx: G.Gfx, wall: D.Draw.Wall, +side: U32, +flags: U32, +yoff: U32, +onesided: Bool,
  +sky2: Bool, +samefloor: Bool, +sameceil: Bool, f: L.Level.Sector, b: L.Level.Sector, +vz: U32,
  +skyfront: Bool, lightnum: U32, geo: Segs.Geo) -> Segs.Rw:
  D.Wall{index, start, stop, +scale, scale2, +step} = wall
  L.Sector{+ffloor, +fceil, +flight} = f
  L.Sector{+bfloor, +bceil, +blight} = b
  +worldtop = (Bool.pick(U32, sky2, bceil, fceil) - vz : U32)
  +worldbottom = (ffloor - vz : U32)
  +worldhigh = (bceil - vz : U32)
  +worldlow = (bfloor - vz : U32)
  +shut = Bool.or(onesided, Bool.or(F.Fixed.le(bceil, ffloor), F.Fixed.ge(bfloor, fceil)))
  +relit = Bool.not(U32.is_eq(blight, flight))
  +pegtop = Bool.not(U32.is_zero((flags .&. 8 : U32)))
  +pegbottom = Bool.not(U32.is_zero((flags .&. 16 : U32)))
  Rw{start, scale, step, Segs.frac(worldtop, scale), Segs.fracstep(worldtop, step),
    Segs.frac(worldbottom, scale), Segs.fracstep(worldbottom, step),
    Segs.frac(worldhigh, scale), Segs.fracstep(worldhigh, step),
    Segs.frac(worldlow, scale), Segs.fracstep(worldlow, step),
    Bool.pick(U32, onesided, G.Gfx.mid(gfx, side), 0),
    Bool.pick(U32, Bool.and(Bool.not(onesided), F.Fixed.lt(worldhigh, worldtop)), G.Gfx.top(gfx, side), 0),
    Bool.pick(U32, Bool.and(Bool.not(onesided), F.Fixed.gt(worldlow, worldbottom)),
      G.Gfx.bottom(gfx, side), 0),
    (Bool.pick(U32, pegbottom, (ffloor + G.Gfx.tex.height(gfx, G.Gfx.mid(gfx, side)) - vz : U32), worldtop)
      + yoff : U32),
    (Bool.pick(U32, pegtop, worldtop, (bceil + G.Gfx.tex.height(gfx, G.Gfx.top(gfx, side)) - vz : U32))
      + yoff : U32),
    (Bool.pick(U32, pegbottom, worldtop, worldlow) + yoff : U32),
    Bool.and(F.Fixed.lt(ffloor, vz), Bool.or(shut, Bool.or(relit,
      Bool.or(Bool.not(U32.is_eq(worldlow, worldbottom)), Bool.not(samefloor))))),
    Bool.and(Bool.or(F.Fixed.gt(fceil, vz), skyfront), Bool.or(shut, Bool.or(relit,
      Bool.or(Bool.not(U32.is_eq(worldhigh, worldtop)), Bool.not(sameceil))))),
    lightnum, geo}

def Segs.side.yoff(s: L.Level.Side) -> U32:
  L.Side{xoff, yoff, sector} = s
  yoff

# The front and back sectors' part of R_StoreWallRange. Between two sky
# ceilings the upper wall is not drawn: the wall's top is the back's.
def Segs.rw(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, wall: D.Draw.Wall,
  geo: Segs.Geo) -> Segs.Rw:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, +side, +front, +back} = seg
  +onesided = U32.is_eq(back, L.Level.none())
  +skyfront = U32.is_eq(G.Gfx.ceilpic(gfx, front), G.Gfx.sky(gfx))
  Segs.rw.of(gfx, wall, side, flags, Segs.side.yoff(L.Level.side(level, side)), onesided,
    Bool.and(Bool.not(onesided), Bool.and(skyfront, U32.is_eq(G.Gfx.ceilpic(gfx, back), G.Gfx.sky(gfx)))),
    U32.is_eq(G.Gfx.floorpic(gfx, back), G.Gfx.floorpic(gfx, front)),
    U32.is_eq(G.Gfx.ceilpic(gfx, back), G.Gfx.ceilpic(gfx, front)),
    L.Level.sector(level, front), L.Level.sector(level, back), P.View.z(view), skyfront,
    Segs.lightnum(seg, L.Level.sector.light(level, front)), geo)

# The seg loop
# ------------

type Segs.Cols is Type:
  Cols{mem: Array<U32>, rw: Segs.Rw, view: P.View, gfx: G.Gfx}

def Segs.row(frac: U32) -> U32:
  F.Fixed.sarn(frac, 12n)

# A column's texture column: the range's offset less the tangent of the
# column's angle from the wall's normal times the wall's distance.
def Segs.texcol(+view: P.View, geo: Segs.Geo, x: U32) -> U32:
  Geo{normal, distance, offset, centerangle} = geo
  F.Fixed.sarn((offset - F.Fixed.mul(V.Vec.get(P.View.tangent(view),
    A.Angle.fine((centerangle + P.View.xtoangle(view, x) : U32))), distance) : U32), 16n)

# The colormap of a wall column at a scale: Doom's walllights at the
# scale's light index, which the table's end caps.
def Segs.colormap(lightnum: U32, scale: U32) -> U32:
  (G.Gfx.colormap() + P.Project.scalelight(lightnum, U32.min((scale >> 12n : U32), 47)) * 256 : U32)

# Doom's dc_iscale: the texture rows a screen row, the reciprocal of
# the scale by the 32-bit division.
def Segs.iscale(scale: U32) -> U32:
  (4294967295 / scale : U32)

# Doom's R_RenderSegLoop for one column, given its ceiling and floor
# clips cc and fc: the wall's rows held inside them; a one-sided wall
# drawn whole and the column closed; else the upper wall down to the
# back's ceiling and the lower up from its floor, each narrowing its
# clip, or the clips narrowed to the wall's rows where a plane is
# marked. The three walls share the column's texture column, colormap
# and reciprocal scale.
def Segs.col.draw(+x: U32, rw: Segs.Rw, +view: P.View, +gfx: G.Gfx, +cc: U32, +fc: U32,
  mem: Array<U32>) -> Array<U32>:
  Rw{+start, +scale0, +step, topfrac, topstep, bottomfrac, bottomstep, pixhigh, pixhighstep, pixlow,
    pixlowstep, +mid, +top, +bottom, midmid, topmid, bottommid, markfloor, markceiling, lightnum,
    geo} = rw
  +k = (x - start : U32)
  +scale = (scale0 + k * step : U32)
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
  +texcol = Segs.texcol(view, geo, x)
  +cmap = Segs.colormap(lightnum, scale)
  +iscale = Segs.iscale(scale)
  Array.set(U32, Array.set(U32,
    D.Draw.column(D.Draw.column(D.Draw.column(mem,
      x, yl, Bool.pick(U32, solid, yh, (yl - 1 : U32)), G.Gfx.column(gfx, mid, texcol), midmid, iscale, cmap),
      x, yl, Bool.pick(U32, upper, high, (yl - 1 : U32)), G.Gfx.column(gfx, top, texcol), topmid, iscale, cmap),
      x, Bool.pick(U32, lower, low, (yh + 1 : U32)), yh, G.Gfx.column(gfx, bottom, texcol), bottommid, iscale,
      cmap),
    (G.Gfx.ceilclip() + x : U32), cc2), (G.Gfx.floorclip() + x : U32), fc2)

def Segs.col.floor(+x: U32, +rw: Segs.Rw, +view: P.View, +gfx: G.Gfx, cc: U32, p: Array<U32> & U32) ->
  Segs.Cols:
  (mem, fc) = p
  Cols{Segs.col.draw(x, rw, view, gfx, cc, fc, mem), rw, view, gfx}

def Segs.col.ceil(+x: U32, rw: Segs.Rw, view: P.View, gfx: G.Gfx, p: Array<U32> & U32) -> Segs.Cols:
  (mem, cc) = p
  Segs.col.floor(x, rw, view, gfx, cc, B.Bytes.at(mem, (G.Gfx.floorclip() + x : U32)))

def Segs.col(i: Nat, st: Segs.Cols) -> Segs.Cols:
  Cols{mem, rw, view, gfx} = st
  +x = U32.from_nat(i)
  Segs.col.ceil(x, rw, view, gfx, B.Bytes.at(mem, (G.Gfx.ceilclip() + x : U32)))

def Segs.Cols.mem(st: Segs.Cols) -> Array<U32>:
  Cols{mem, rw, view, gfx} = st
  mem

# Doom's R_StoreWallRange for the columns of one gap: the range stored,
# and its columns drawn.
def Segs.store.wall(+view: P.View, +level: L.Level, +gfx: G.Gfx, seg: L.Level.Seg, +wall: D.Draw.Wall,
  geo: Segs.Geo, st: D.Draw) -> D.Draw:
  D.Wall{index, +x1, x2, scale1, scale2, step} = wall
  D.Draw{mem, solid, walls, tasks} = st
  D.Draw{Segs.Cols.mem(D.Draw.each(~Segs.Cols, ~Segs.col, U32.to_nat((x2 - x1 + 1 : U32)), U32.to_nat(x1),
    Cols{mem, Segs.rw(view, level, gfx, seg, wall, geo), view, gfx})), solid, wall <> walls, tasks}

def Segs.store.geo(+view: P.View, +level: L.Level, +gfx: G.Gfx, seg: L.Level.Seg, index: U32,
  gap: C.Clip.Range, +geo: Segs.Geo, st: D.Draw) -> D.Draw:
  C.Range{first, last} = gap
  Segs.store.wall(view, level, gfx, seg, Segs.wall(view, index, U32.from_nat(first), U32.from_nat(last), geo),
    geo, st)

def Segs.seg.side(seg: L.Level.Seg) -> U32:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, side, front, back} = seg
  side

def Segs.store(+view: P.View, +level: L.Level, +gfx: G.Gfx, +seg: L.Level.Seg, index: U32, angle1: U32,
  gap: C.Clip.Range, st: D.Draw) -> D.Draw:
  Segs.store.geo(view, level, gfx, seg, index, gap,
    Segs.geo(view, seg, L.Level.side(level, Segs.seg.side(seg)), angle1), st)

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
