# The playsim for one player and no things: Doom's P_MovePlayer,
# P_CalcHeight, P_XYMovement, P_TryMove, P_CheckPosition, P_SlideMove
# and P_ZMovement, as pure functions of the level, the tic command and the
# player, and the tic that maps one state of the level to the next.
# Every position the player is moved to has passed Sim.fit, which is
# what Sim.free asks, so the wall law holds by construction.
import Base
import ./vec.bend as V
import ./fixed.bend as F
import ./angle.bend as A
import ./level.bend as L
import ./keys.bend as K

# Doom's mobj and player_t for one player: the position with its height,
# the angle, the momentum, the floor and ceiling under it, the view
# height and its delta, the eye's height, and the special lines this
# tic's moves have crossed, in the order they fire.
type Player is Data:
  Player{x: U32, y: U32, z: U32, angle: U32, momx: U32, momy: U32, momz: U32,
    floorz: U32, ceilz: U32, viewheight: U32, deltaview: U32, viewz: U32, crossed: List<&2, U32>}

# What a position check answers: whether it is clear of solid lines,
# and the floor and ceiling there, from the sector under the point
# narrowed by every two-sided line the player's box crosses.
type Sim.Fit is Data:
  Fit{ok: Bool, floor: U32, ceil: U32}

# A move that was tried: whether it was taken, and the player after.
# Also the slide loop's state, done when a move along the wall was taken.
type Sim.Try is Data:
  Try{ok: Bool, player: Player}

# The XY movement loop's state: done when no move is left.
type Sim.Xy is Data:
  Xy{done: Bool, player: Player, xmove: U32, ymove: U32}

def Sim.radius() -> U32:
  1048576

def Sim.height() -> U32:
  3670016

def Sim.maxmove() -> U32:
  1966080

def Sim.stopspeed() -> U32:
  4096

def Sim.decay() -> U32:
  59392

def Sim.step_up() -> U32:
  1572864

def Sim.viewheight() -> U32:
  2686976

def Sim.gravity() -> U32:
  65536

def Sim.maxbob() -> U32:
  1048576

def Player.x(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  x

def Player.y(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  y

def Player.angle(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  angle

def Player.momx(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  momx

def Player.z(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  z

def Player.floorz(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  floorz

def Player.ceilz(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  ceilz

def Player.crossed(+p: Player) -> List<&2, U32>:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  crossed

def Player.viewz(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  viewz

# On the ground: at or below the floor.
def Player.onground(+p: Player) -> Bool:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  F.Fixed.le(z, floorz)

def Player.at.fin(+x: U32, +y: U32, angle: U32, +floor: U32, ceil: U32) -> Player:
  Player{x, y, floor, angle, 0, 0, 0, floor, ceil, Sim.viewheight(), 0,
    (floor + Sim.viewheight() : U32), []}

def Player.at(+level: L.Level, s: L.Level.Start) -> Player:
  L.Start{+x, +y, angle} = s
  +sector = L.Level.sector_at(level, x, y)
  Player.at.fin(x, y, angle, L.Level.floor(level, sector), L.Level.ceil(level, sector))

# The player at the level's start, on its floor, its eye at rest.
def Player.start(+level: L.Level) -> Player:
  Player.at(level, L.Level.start_of(level))

# Lines and the player's box
# --------------------------

# Doom's P_PointOnLineSide: True on the back side.
def Sim.point_side.slow(+x: U32, +y: U32, +dx: U32, +dy: U32) -> Bool:
  Bool.not(F.Fixed.lt(F.Fixed.mul(y, F.Fixed.sarn(dx, 16n)),
    F.Fixed.mul(F.Fixed.sarn(dy, 16n), x)))

def Sim.point_side(+x: U32, +y: U32, +line: L.Level.Line) -> Bool:
  L.Line{+x1, +y1, +x2, +y2, flags, front, back} = line
  +dx = (x2 - x1 : U32)
  +dy = (y2 - y1 : U32)
  L.Level.axis_side(x, y, x1, y1, dx, dy,
    Sim.point_side.slow((x - x1 : U32), (y - y1 : U32), dx, dy))

# Doom's P_BoxOnLineSide, answering whether the box straddles the line.
# The slope's sign is the sign of dy over dx, which FixedDiv keeps for
# any whole-unit line.
def Sim.box_crosses(+x: U32, +y: U32, +line: L.Level.Line) -> Bool:
  L.Line{+x1, +y1, +x2, +y2, flags, front, back} = line
  +dx = (x2 - x1 : U32)
  +dy = (y2 - y1 : U32)
  +top = (y + Sim.radius() : U32)
  +bottom = (y - Sim.radius() : U32)
  +left = (x - Sim.radius() : U32)
  +right = (x + Sim.radius() : U32)
  Bool.pick(Bool, U32.is_zero(dx),
    Bool.xor(F.Fixed.lt(right, x1), F.Fixed.lt(left, x1)),
    Bool.pick(Bool, U32.is_zero(dy),
      Bool.xor(F.Fixed.gt(top, y1), F.Fixed.gt(bottom, y1)),
      Bool.pick(Bool, Bool.xor(F.Fixed.is_neg(dx), F.Fixed.is_neg(dy)),
        Bool.xor(Sim.point_side(right, top, line), Sim.point_side(left, bottom, line)),
        Bool.xor(Sim.point_side(left, top, line), Sim.point_side(right, bottom, line)))))

# Whether the player's box at (x, y) overlaps the line's box.
def Sim.box_touches(+x: U32, +y: U32, +line: L.Level.Line) -> Bool:
  L.Line{+x1, +y1, +x2, +y2, flags, front, back} = line
  Bool.and(F.Fixed.gt((x + Sim.radius() : U32), F.Fixed.min(x1, x2)),
    Bool.and(F.Fixed.lt((x - Sim.radius() : U32), F.Fixed.max(x1, x2)),
      Bool.and(F.Fixed.gt((y + Sim.radius() : U32), F.Fixed.min(y1, y2)),
        F.Fixed.lt((y - Sim.radius() : U32), F.Fixed.max(y1, y2)))))

# A line the player's box crosses blocks when it is one-sided or
# flagged blocking.
def Sim.solid(+line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, +flags, front, +back} = line
  Bool.or(U32.is_eq(back, L.Level.none()), U32.is_eq((flags .&. 1 : U32), 1))

# The distance condition: line i does not stop a player at (x, y).
def Sim.line_ok(+level: L.Level, +x: U32, +y: U32, i: U32) -> Bool:
  +line = L.Level.line(level, i)
  Bool.not(Bool.and(Sim.box_touches(x, y, line),
    Bool.and(Sim.box_crosses(x, y, line), Sim.solid(line))))

# The opening of a two-sided line: the higher floor, the lower ceiling.
def Sim.open_bottom(+level: L.Level, +line: L.Level.Line) -> U32:
  L.Line{x1, y1, x2, y2, flags, front, back} = line
  F.Fixed.max(L.Level.floor(level, front), L.Level.floor(level, back))

def Sim.open_top(+level: L.Level, +line: L.Level.Line) -> U32:
  L.Line{x1, y1, x2, y2, flags, front, back} = line
  F.Fixed.min(L.Level.ceil(level, front), L.Level.ceil(level, back))

def Sim.fit.narrow(hit: Bool, +level: L.Level, +line: L.Level.Line, fit: Sim.Fit) ->
  Sim.Fit:
  match hit:
    case False{}:
      fit
    case True{}:
      Fit{ok, floor, ceil} = fit
      Fit{ok, F.Fixed.max(floor, Sim.open_bottom(level, line)),
        F.Fixed.min(ceil, Sim.open_top(level, line))}

# A two-sided line the box crosses narrows the floor and ceiling.
def Sim.fit.heights(+level: L.Level, +x: U32, +y: U32, +line: L.Level.Line, fit: Sim.Fit) ->
  Sim.Fit:
  L.Line{x1, y1, x2, y2, flags, front, +back} = line
  Sim.fit.narrow(Bool.and(Bool.not(U32.is_eq(back, L.Level.none())),
    Bool.and(Sim.box_touches(x, y, line), Sim.box_crosses(x, y, line))), level, line, fit)

def Sim.fit.and(b: Bool, fit: Sim.Fit) -> Sim.Fit:
  Fit{ok, floor, ceil} = fit
  Fit{Bool.and(ok, b), floor, ceil}

def Sim.fit.line(+level: L.Level, +x: U32, +y: U32, +i: U32, fit: Sim.Fit) -> Sim.Fit:
  Sim.fit.and(Sim.line_ok(level, x, y, i),
    Sim.fit.heights(level, x, y, L.Level.line(level, i), fit))

def Sim.fit.go(lines: List<&2, U32>, +level: L.Level, +x: U32, +y: U32, fit: Sim.Fit) ->
  Sim.Fit:
  match lines:
    case []:
      fit
    case i <> rest:
      Sim.fit.go(rest, level, x, y, Sim.fit.line(level, x, y, i, fit))

# The blockmap cells a box from (x0, y0) to (x1, y1) touches, as one
# list of the lines they hold (a line in two cells is listed twice).
def Sim.block(v: U32, +org: U32) -> U32:
  F.Fixed.sarn((v - org : U32), 23n)

def Sim.column(m: Nat, +bm: L.Level.Blockmap, +bx: U32, +by: U32) -> List<&2, U32>:
  match m:
    case 0n:
      []
    case 1n+k:
      List.append(&2, U32, L.Level.cell.at(bm, bx, by), Sim.column(k, bm, bx, (by + 1 : U32)))

def Sim.cells(n: Nat, +m: Nat, +bm: L.Level.Blockmap, +bx: U32, +by: U32) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+k:
      List.append(&2, U32, Sim.column(m, bm, bx, by), Sim.cells(k, m, bm, (bx + 1 : U32), by))

def Sim.lines.at(+bm: L.Level.Blockmap, +x0: U32, +y0: U32, +x1: U32, +y1: U32) -> List<&2, U32>:
  L.Blockmap{words, +ox, +oy, cols, rows} = bm
  +xl = Sim.block(x0, ox)
  +yl = Sim.block(y0, oy)
  Sim.cells(U32.to_nat((Sim.block(x1, ox) - xl + 1 : U32)),
    U32.to_nat((Sim.block(y1, oy) - yl + 1 : U32)), bm, xl, yl)

def Sim.lines(+level: L.Level, x0: U32, y0: U32, x1: U32, y1: U32) -> List<&2, U32>:
  Sim.lines.at(L.Level.blockmap_of(level), x0, y0, x1, y1)

# Doom's P_CheckPosition for the player's box at (x, y).
def Sim.fit(+level: L.Level, +x: U32, +y: U32) -> Sim.Fit:
  +sector = L.Level.sector_at(level, x, y)
  Sim.fit.go(Sim.lines(level, (x - Sim.radius() : U32), (y - Sim.radius() : U32),
    (x + Sim.radius() : U32), (y + Sim.radius() : U32)), level, x, y,
    Fit{True{}, L.Level.floor(level, sector), L.Level.ceil(level, sector)})

def Sim.Fit.ok(f: Sim.Fit) -> Bool:
  Fit{ok, floor, ceil} = f
  ok

# Free: no solid line in the cells the player's box touches crosses
# the box. What every move the sim takes has passed.
def Sim.free(+level: L.Level, x: U32, y: U32) -> Bool:
  Sim.Fit.ok(Sim.fit(level, x, y))

# Moving
# ------

def Sim.keep(keep: Bool, x: U32, rest: List<&2, U32>) -> List<&2, U32>:
  match keep:
    case False{}:
      rest
    case True{}:
      x <> rest

def Sim.member(xs: List<&2, U32>, +i: U32) -> Bool:
  match xs:
    case []:
      False{}
    case x <> rest:
      Bool.or(U32.is_eq(x, i), Sim.member(rest, i))

# Whether a move from (ox, oy) to (x, y) crosses a line with a special:
# Doom's spechit, a two-sided special line the box at the new place is
# across, tested as P_TryMove tests it, by the side of the player's
# centre before and after.
def Sim.crosses(+level: L.Level, +ox: U32, +oy: U32, +x: U32, +y: U32, +i: U32) -> Bool:
  +line = L.Level.line(level, i)
  Bool.and(Bool.not(U32.is_zero(L.Level.special(level, i))),
    Bool.and(Bool.not(Sim.solid(line)), Bool.and(Sim.box_touches(x, y, line),
      Bool.and(Sim.box_crosses(x, y, line),
        Bool.xor(Sim.point_side(ox, oy, line), Sim.point_side(x, y, line))))))

# The lines a move crosses, the last gathered first, as Doom fires them,
# a line the blockmap lists twice taken once.
def Sim.crossings.go(lines: List<&2, U32>, +level: L.Level, +ox: U32, +oy: U32, +x: U32, +y: U32,
  +found: List<&2, U32>) -> List<&2, U32>:
  match lines:
    case []:
      found
    case +i <> rest:
      Sim.crossings.go(rest, level, ox, oy, x, y, Sim.keep(Bool.and(Sim.crosses(level, ox, oy, x, y, i),
        Bool.not(Sim.member(found, i))), i, found))

def Sim.crossings(+level: L.Level, ox: U32, oy: U32, +x: U32, +y: U32) -> List<&2, U32>:
  Sim.crossings.go(Sim.lines(level, (x - Sim.radius() : U32), (y - Sim.radius() : U32),
    (x + Sim.radius() : U32), (y + Sim.radius() : U32)), level, ox, oy, x, y, [])

def Sim.try_move.fin(go: Bool, p: Player, x: U32, y: U32, floor: U32, ceil: U32, over: List<&2, U32>) ->
  Sim.Try:
  match go:
    case False{}:
      Try{False{}, p}
    case True{}:
      Player{ox, oy, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
      Try{True{}, Player{x, y, z, angle, momx, momy, momz, floor, ceil, viewheight, deltaview, viewz,
        List.append(&2, U32, crossed, over)}}

# The move is taken when the position is free, the opening fits the
# player, the ceiling is high enough from the player's feet, and the
# floor is at most 24 units up.
def Sim.try_move.fit(+p: Player, x: U32, y: U32, f: Sim.Fit, over: List<&2, U32>) -> Sim.Try:
  Fit{ok, +floor, +ceil} = f
  +z = Player.z(p)
  Sim.try_move.fin(Bool.and(ok, Bool.and(F.Fixed.ge((ceil - floor : U32), Sim.height()),
    Bool.and(F.Fixed.ge((ceil - z : U32), Sim.height()),
      F.Fixed.le((floor - z : U32), Sim.step_up())))), p, x, y, floor, ceil, over)

# Doom's P_TryMove: a move taken adds the special lines it crossed to
# the player's.
def Sim.try_move(+level: L.Level, +p: Player, +x: U32, +y: U32) -> Sim.Try:
  Sim.try_move.fit(p, x, y, Sim.fit(level, x, y), Sim.crossings(level, Player.x(p), Player.y(p), x, y))

def Sim.Try.player(t: Sim.Try) -> Player:
  Try{ok, p} = t
  p

# Sliding
# -------

# Doom's P_PointOnDivlineSide against the trace, for far ends.
def Sim.div_side.slow(+x: U32, +y: U32, +dx: U32, +dy: U32) -> Bool:
  Bool.pick(Bool, U32.is_zero(((dy .^. dx .^. x .^. y) .&. 2147483648 : U32)),
    Bool.not(F.Fixed.lt(F.Fixed.mul(F.Fixed.sarn(y, 8n), F.Fixed.sarn(dx, 8n)),
      F.Fixed.mul(F.Fixed.sarn(dy, 8n), F.Fixed.sarn(x, 8n)))),
    Bool.not(U32.is_zero(((dy .^. x) .&. 2147483648 : U32))))

def Sim.div_side(+x: U32, +y: U32, +tx: U32, +ty: U32, +dx: U32, +dy: U32) -> Bool:
  L.Level.axis_side(x, y, tx, ty, dx, dy, Sim.div_side.slow((x - tx : U32), (y - ty : U32), dx, dy))

def Sim.far(+d: U32) -> Bool:
  Bool.or(F.Fixed.gt(d, 1048576), F.Fixed.lt(d, 4293918720))

# Whether the line's ends lie on opposite sides of the trace: the
# divline test for long traces, the line side test for short ones.
def Sim.crossed(+tx: U32, +ty: U32, +tdx: U32, +tdy: U32, +line: L.Level.Line) -> Bool:
  L.Line{+x1, +y1, +x2, +y2, flags, front, back} = line
  Bool.pick(Bool, Bool.or(Sim.far(tdx), Sim.far(tdy)),
    Bool.xor(Sim.div_side(x1, y1, tx, ty, tdx, tdy), Sim.div_side(x2, y2, tx, ty, tdx, tdy)),
    Bool.xor(Sim.point_side(tx, ty, line), Sim.point_side((tx + tdx : U32), (ty + tdy : U32), line)))

# Doom's P_InterceptVector: how far along the trace the line is.
def Sim.intercept.div(+num: U32, +den: U32) -> U32:
  Bool.pick(U32, U32.is_zero(den), 0, F.Fixed.div(num, den))

def Sim.intercept.frac(+tx: U32, +ty: U32, +tdx: U32, +tdy: U32, +line: L.Level.Line) -> U32:
  L.Line{+x1, +y1, +x2, +y2, flags, front, back} = line
  +dx = (x2 - x1 : U32)
  +dy = (y2 - y1 : U32)
  Sim.intercept.div(
    (F.Fixed.mul(F.Fixed.sarn((x1 - tx : U32), 8n), dy)
      + F.Fixed.mul(F.Fixed.sarn((ty - y1 : U32), 8n), dx) : U32),
    (F.Fixed.mul(F.Fixed.sarn(dy, 8n), tdx) - F.Fixed.mul(F.Fixed.sarn(dx, 8n), tdy) : U32))

# The fraction where the trace meets the line, or past one when it
# does not (Doom's INT_MAX for an intercept out of range).
def Sim.intercept(+tx: U32, +ty: U32, +tdx: U32, +tdy: U32, +line: L.Level.Line) -> U32:
  Bool.pick(U32, Sim.crossed(tx, ty, tdx, tdy, line),
    Sim.intercept.frac(tx, ty, tdx, tdy, line), 2147483647)

# Doom's PTR_SlideTraverse: whether the line stops the slide. A line
# flagged two-sided with no back sector has no opening and blocks.
def Sim.blocks.open(+level: L.Level, +p: Player, +line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, flags, front, +back} = line
  +top = Sim.open_top(level, line)
  +bottom = Sim.open_bottom(level, line)
  +z = Player.z(p)
  Bool.or(U32.is_eq(back, L.Level.none()),
    Bool.or(F.Fixed.lt((top - bottom : U32), Sim.height()),
      Bool.or(F.Fixed.lt((top - z : U32), Sim.height()),
        F.Fixed.gt((bottom - z : U32), Sim.step_up()))))

def Sim.blocks(+level: L.Level, +p: Player, +line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, +flags, front, back} = line
  Bool.pick(Bool, U32.is_zero((flags .&. 4 : U32)),
    Bool.not(Sim.point_side(Player.x(p), Player.y(p), line)),
    Sim.blocks.open(level, p, line))

# The best hit so far: the least fraction and its line; none is one
# past a whole move.
def Sim.hit.better(closer: Bool, frac: U32, i: U32, best: U32 & U32) -> U32 & U32:
  match closer:
    case False{}:
      best
    case True{}:
      (frac, i)

def Sim.hit.blocked(blocked: Bool, +frac: U32, i: U32, best: U32 & U32) -> U32 & U32:
  match blocked:
    case False{}:
      best
    case True{}:
      (+bf, bi) = best
      Sim.hit.better(U32.is_lt(frac, bf), frac, i, (bf, bi))

# A line a trace meets, and how far along the trace, as a fraction.
type Sim.Meet is Data:
  Meet{frac: U32, line: U32}

def Sim.meets.add(near: Bool, frac: U32, i: U32, rest: List<&2, Sim.Meet>) -> List<&2, Sim.Meet>:
  match near:
    case False{}:
      rest
    case True{}:
      Meet{frac, i} <> rest

def Sim.meets.go(lines: List<&2, U32>, +level: L.Level, +tx: U32, +ty: U32, +tdx: U32, +tdy: U32) ->
  List<&2, Sim.Meet>:
  match lines:
    case []:
      []
    case +i <> rest:
      +frac = Sim.intercept(tx, ty, tdx, tdy, L.Level.line(level, i))
      Sim.meets.add(U32.is_le(frac, F.Fixed.unit()), frac, i, Sim.meets.go(rest, level, tx, ty, tdx, tdy))

# A trace that starts on a cell's edge is nudged off it, as Doom's.
def Sim.nudge(+v: U32, +org: U32) -> U32:
  Bool.pick(U32, U32.is_zero(((v - org : U32) .&. 8388607 : U32)), (v + F.Fixed.unit() : U32), v)

def Sim.meets.at(+bm: L.Level.Blockmap, +level: L.Level, +x1: U32, +y1: U32, +x2: U32, +y2: U32) ->
  List<&2, Sim.Meet>:
  L.Blockmap{words, +ox, +oy, cols, rows} = bm
  +tx = Sim.nudge(x1, ox)
  +ty = Sim.nudge(y1, oy)
  Sim.meets.go(Sim.lines(level, F.Fixed.min(tx, x2), F.Fixed.min(ty, y2), F.Fixed.max(tx, x2),
    F.Fixed.max(ty, y2)), level, tx, ty, (x2 - tx : U32), (y2 - ty : U32))

# Doom's P_PathTraverse intercepts: the lines a trace meets within its
# length, gathered from the cells the trace's box touches rather than
# walked cell by cell, in the order gathered.
def Sim.meets(+level: L.Level, x1: U32, y1: U32, x2: U32, y2: U32) -> List<&2, Sim.Meet>:
  Sim.meets.at(L.Level.blockmap_of(level), level, x1, y1, x2, y2)

def Sim.trace.go(meets: List<&2, Sim.Meet>, +level: L.Level, +p: Player, best: U32 & U32) -> U32 & U32:
  match meets:
    case []:
      best
    case Meet{frac, +i} <> rest:
      Sim.trace.go(rest, level, p, Sim.hit.blocked(Sim.blocks(level, p, L.Level.line(level, i)), frac, i, best))

# Doom's PTR_SlideTraverse over a trace: the closest line it meets that
# blocks.
def Sim.trace(+level: L.Level, +p: Player, x1: U32, y1: U32, x2: U32, y2: U32, best: U32 & U32) ->
  U32 & U32:
  Sim.trace.go(Sim.meets(level, x1, y1, x2, y2), level, p, best)

# Doom's P_AproxDistance.
def Sim.approx(+dx: U32, +dy: U32) -> U32:
  +ax = F.Fixed.abs(dx)
  +ay = F.Fixed.abs(dy)
  Bool.pick(U32, F.Fixed.lt(ax, ay), (ax + ay - (ax >> 1n) : U32), (ax + ay - (ay >> 1n) : U32))

# Doom's P_HitSlideLine: the move projected onto the line.
def Sim.along.angle(+level: L.Level, +p: Player, +line: L.Level.Line, +mx: U32, +my: U32) ->
  U32 & U32:
  L.Line{+x1, +y1, +x2, +y2, flags, front, back} = line
  +tanto = L.Level.tanto(level)
  +sine = L.Level.sine(level)
  +lineangle = (A.Angle.of(tanto, (x2 - x1 : U32), (y2 - y1 : U32))
    + Bool.pick(U32, Sim.point_side(Player.x(p), Player.y(p), line), A.Angle.ang180(), 0) : U32)
  +delta = (A.Angle.of(tanto, mx, my) - lineangle : U32)
  +delta2 = Bool.pick(U32, U32.is_gt(delta, A.Angle.ang180()), (delta + A.Angle.ang180() : U32), delta)
  +newlen = F.Fixed.mul(Sim.approx(mx, my), A.Angle.cos(sine, A.Angle.fine(delta2)))
  (F.Fixed.mul(newlen, A.Angle.cos(sine, A.Angle.fine(lineangle))),
    F.Fixed.mul(newlen, A.Angle.sin(sine, A.Angle.fine(lineangle))))

def Sim.along.line(+level: L.Level, +p: Player, +line: L.Level.Line, +mx: U32, +my: U32) ->
  U32 & U32:
  L.Line{+x1, +y1, +x2, +y2, flags, front, back} = line
  Bool.pick(U32 & U32, U32.is_eq(y1, y2), (mx, 0),
    Bool.pick(U32 & U32, U32.is_eq(x1, x2), (0, my),
      Sim.along.angle(level, p, line, mx, my)))

def Sim.along(+level: L.Level, +p: Player, i: U32, mx: U32, my: U32) -> U32 & U32:
  Sim.along.line(level, p, L.Level.line(level, i), mx, my)

def Sim.stairstep.fin(+level: L.Level, t: Sim.Try) -> Player:
  match t:
    case Try{True{}, p}:
      p
    case Try{False{}, +p}:
      Sim.Try.player(Sim.try_move(level, p, (Player.x(p) + Player.momx(p) : U32), Player.y(p)))

# Doom's stairstep: the move along y alone, else along x alone.
def Sim.stairstep(+level: L.Level, +p: Player) -> Player:
  Player{+x, +y, z, angle, momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  Sim.stairstep.fin(level, Sim.try_move(level, p, x, (y + momy : U32)))

# The remainder of the move, clipped along the wall, becomes the
# momentum and is tried; a failure retries the slide from here.
def Sim.slide.wall.go(+level: L.Level, +p: Player, m: U32 & U32) -> Sim.Try:
  Player{+x, +y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  (+mx, +my) = m
  Sim.try_move(level, Player{x, y, z, angle, mx, my, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed}, (x + mx : U32),
    (y + my : U32))

def Sim.slide.wall(left: Bool, +level: L.Level, +p: Player, +frac: U32, i: U32) -> Sim.Try:
  match left:
    case False{}:
      Try{True{}, p}
    case True{}:
      Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
      Sim.slide.wall.go(level, p, Sim.along(level, p, i, F.Fixed.mul(momx, frac),
        F.Fixed.mul(momy, frac)))

# After the move up to the wall: the fraction left, capped at a whole
# move, is slid along the wall if there is any.
def Sim.slide.rest(+level: L.Level, +p: Player, +frac: U32, i: U32) -> Sim.Try:
  +left = F.Fixed.min(F.Fixed.unit(), (F.Fixed.unit() - frac - 2048 : U32))
  Sim.slide.wall(F.Fixed.gt(left, 0), level, p, left, i)

def Sim.slide.upto.fin(+level: L.Level, +frac: U32, i: U32, t: Sim.Try) -> Sim.Try:
  match t:
    case Try{True{}, p}:
      Sim.slide.rest(level, p, frac, i)
    case Try{False{}, p}:
      Try{True{}, Sim.stairstep(level, p)}

# The move up to the wall, a little short of it; a failure stairsteps.
def Sim.slide.upto(some: Bool, +level: L.Level, +p: Player, +frac: U32, i: U32) -> Sim.Try:
  match some:
    case False{}:
      Sim.slide.rest(level, p, frac, i)
    case True{}:
      Player{+x, +y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
      Sim.slide.upto.fin(level, frac, i, Sim.try_move(level, p,
        (x + F.Fixed.mul(momx, frac) : U32), (y + F.Fixed.mul(momy, frac) : U32)))

# No line hit means the move hit the middle, so stairstep.
def Sim.slide.found(hit: Bool, +level: L.Level, +p: Player, +frac: U32, i: U32) -> Sim.Try:
  match hit:
    case False{}:
      Try{True{}, Sim.stairstep(level, p)}
    case True{}:
      Sim.slide.upto(F.Fixed.gt(frac, 0), level, p, frac, i)

def Sim.slide.hit(+level: L.Level, +p: Player, best: U32 & U32) -> Sim.Try:
  (+frac, i) = best
  Sim.slide.found(U32.is_le(frac, F.Fixed.unit()), level, p, (frac - 2048 : U32), i)

def Sim.lead(+v: U32, +mom: U32) -> U32:
  Bool.pick(U32, F.Fixed.gt(mom, 0), (v + Sim.radius() : U32), (v - Sim.radius() : U32))

def Sim.trail(+v: U32, +mom: U32) -> U32:
  Bool.pick(U32, F.Fixed.gt(mom, 0), (v - Sim.radius() : U32), (v + Sim.radius() : U32))

# One try of the slide: the three leading corners are traced along the
# momentum for the closest blocking line.
def Sim.slide.once(+level: L.Level, +p: Player) -> Sim.Try:
  Player{+x, +y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  +lx = Sim.lead(x, momx)
  +ly = Sim.lead(y, momy)
  +tx = Sim.trail(x, momx)
  +ty = Sim.trail(y, momy)
  Sim.slide.hit(level, p,
    Sim.trace(level, p, lx, ty, (lx + momx : U32), (ty + momy : U32),
      Sim.trace(level, p, tx, ly, (tx + momx : U32), (ly + momy : U32),
        Sim.trace(level, p, lx, ly, (lx + momx : U32), (ly + momy : U32),
          ((F.Fixed.unit() + 1 : U32), 0)))))

def Sim.slide.go(fuel: Nat, +level: L.Level, st: Sim.Try) -> Player:
  match fuel st:
    case _ Try{True{}, p}:
      p
    case 0n Try{False{}, p}:
      Sim.stairstep(level, p)
    case 1n+f Try{False{}, p}:
      Sim.slide.go(f, level, Sim.slide.once(level, p))

# Doom's P_SlideMove: two tries, then stairstep.
def Sim.slide(+level: L.Level, p: Player) -> Player:
  Sim.slide.go(2n, level, Try{False{}, p})

# XY movement
# -----------

def Sim.xy.tried(+level: L.Level, t: Sim.Try) -> Player:
  match t:
    case Try{True{}, p}:
      p
    case Try{False{}, p}:
      Sim.slide(level, p)

def Sim.xy.fin(+level: L.Level, +p: Player, tx: U32, ty: U32, +xm: U32, +ym: U32) -> Sim.Xy:
  Xy{Bool.and(U32.is_zero(xm), U32.is_zero(ym)),
    Sim.xy.tried(level, Sim.try_move(level, p, tx, ty)), xm, ym}

# A move past half the most is taken in halves: the half tried is C's
# division, the half kept is the shift, as in Doom.
def Sim.xy.step(big: Bool, +level: L.Level, +p: Player, +xm: U32, +ym: U32) -> Sim.Xy:
  match big:
    case True{}:
      Sim.xy.fin(level, p, (Player.x(p) + F.Fixed.half(xm) : U32),
        (Player.y(p) + F.Fixed.half(ym) : U32), F.Fixed.sar(xm), F.Fixed.sar(ym))
    case False{}:
      Sim.xy.fin(level, p, (Player.x(p) + xm : U32), (Player.y(p) + ym : U32), 0, 0)

def Sim.big(+xm: U32, +ym: U32) -> Bool:
  Bool.or(F.Fixed.gt(xm, F.Fixed.sar(Sim.maxmove())), F.Fixed.gt(ym, F.Fixed.sar(Sim.maxmove())))

def Sim.xy.go(fuel: Nat, +level: L.Level, st: Sim.Xy) -> Player:
  match fuel st:
    case _ Xy{True{}, p, xm, ym}:
      p
    case 0n Xy{False{}, p, xm, ym}:
      p
    case 1n+f Xy{False{}, p, +xm, +ym}:
      Sim.xy.go(f, level, Sim.xy.step(Sim.big(xm, ym), level, p, xm, ym))

# Doom's friction on the ground: momentum below the stop speed with no
# move key held stops, else it decays by 0.90625 a tic.
def Sim.slow(stop: Bool, p: Player) -> Player:
  match stop:
    case True{}:
      Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
      Player{x, y, z, angle, 0, 0, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed}
    case False{}:
      Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
      Player{x, y, z, angle, F.Fixed.mul(momx, Sim.decay()), F.Fixed.mul(momy, Sim.decay()),
        momz, floorz, ceilz, viewheight, deltaview, viewz, crossed}

def Sim.crawling(+mom: U32) -> Bool:
  Bool.and(F.Fixed.gt(mom, F.Fixed.neg(Sim.stopspeed())), F.Fixed.lt(mom, Sim.stopspeed()))

def Sim.friction.ground(+cmd: K.Cmd, +p: Player) -> Player:
  K.Cmd{forward, side, turn, use} = cmd
  Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  Sim.slow(Bool.and(Sim.crawling(momx), Bool.and(Sim.crawling(momy),
    Bool.and(U32.is_zero(forward), U32.is_zero(side)))), p)

# No friction in the air.
def Sim.friction(+cmd: K.Cmd, +p: Player) -> Player:
  Bool.pick(Player, Player.onground(p), Sim.friction.ground(cmd, p), p)

def Sim.clamp(+mom: U32) -> U32:
  F.Fixed.max(F.Fixed.neg(Sim.maxmove()), F.Fixed.min(mom, Sim.maxmove()))

def Sim.xy.moving(moving: Bool, +level: L.Level, +cmd: K.Cmd, +p: Player) -> Player:
  match moving:
    case False{}:
      p
    case True{}:
      Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
      +xm = Sim.clamp(momx)
      +ym = Sim.clamp(momy)
      Sim.friction(cmd, Sim.xy.go(2n, level,
        Xy{False{}, Player{x, y, z, angle, xm, ym, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed}, xm, ym}))

# Doom's P_XYMovement: the momentum, capped, moves the player, in
# halves when large; a blocked move slides; then friction.
def Sim.xy(+level: L.Level, cmd: K.Cmd, +p: Player) -> Player:
  Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  Sim.xy.moving(Bool.not(Bool.and(U32.is_zero(momx), U32.is_zero(momy))), level, cmd, p)

# The move
# --------

# Doom's P_Thrust: momentum along an angle.
def Sim.thrust(+level: L.Level, p: Player, +angle: U32, +move: U32) -> Player:
  Player{x, y, z, a, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  +sine = L.Level.sine(level)
  +f = A.Angle.fine(angle)
  Player{x, y, z, a, (momx + F.Fixed.mul(move, A.Angle.cos(sine, f)) : U32),
    (momy + F.Fixed.mul(move, A.Angle.sin(sine, f)) : U32), momz, floorz, ceilz, viewheight,
    deltaview, viewz, crossed}

# A move key thrusts only on the ground.
def Sim.push(+level: L.Level, +p: Player, +angle: U32, +move: U32) -> Player:
  Bool.pick(Player, Bool.or(U32.is_zero(move), Bool.not(Player.onground(p))), p,
    Sim.thrust(level, p, angle, (move * 2048 : U32)))

# Doom's P_MovePlayer: turn, then thrust forward and sideways.
def Sim.move(+level: L.Level, +cmd: K.Cmd, p: Player) -> Player:
  K.Cmd{forward, side, turn, use} = cmd
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  +a = (angle + (turn << 16n) : U32)
  Sim.push(level, Sim.push(level, Player{x, y, z, a, momx, momy, momz, floorz, ceilz, viewheight,
    deltaview, viewz, crossed}, a, forward), (a - A.Angle.ang90() : U32), side)

# The eye
# -------

# Doom's P_CalcHeight on the ground: the view height ramps back to its
# rest by its delta, held between half the rest and the rest, and the
# eye is the height plus the bob, no higher than four under the ceiling.
def Sim.eye.delta(+viewheight: U32, +deltaview: U32) -> U32 & U32:
  +high = F.Fixed.gt(viewheight, Sim.viewheight())
  +low = F.Fixed.lt(viewheight, (Sim.viewheight() >> 1n : U32))
  +vh = Bool.pick(U32, high, Sim.viewheight(),
    Bool.pick(U32, low, (Sim.viewheight() >> 1n : U32), viewheight))
  +dv = Bool.pick(U32, high, 0,
    Bool.pick(U32, Bool.and(low, F.Fixed.le(deltaview, 0)), 1, deltaview))
  +dv2 = (dv + 16384 : U32)
  (vh, Bool.pick(U32, U32.is_zero(dv), 0, Bool.pick(U32, U32.is_zero(dv2), 1, dv2)))

def Sim.eye.ground.fin(+p: Player, +swing: U32, vd: U32 & U32) -> Player:
  Player{x, y, +z, angle, momx, momy, momz, floorz, +ceilz, viewheight, deltaview, viewz, crossed} = p
  (+vh, dv) = vd
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, vh, dv,
    F.Fixed.min((z + vh + swing : U32), (ceilz - 262144 : U32)), crossed}

def Sim.eye.ground(+p: Player, swing: U32) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, +viewheight, +deltaview, viewz, crossed} = p
  Sim.eye.ground.fin(p, swing, Sim.eye.delta((viewheight + deltaview : U32), deltaview))

# In the air the eye sits at the view height, unbobbed.
def Sim.eye.air(p: Player) -> Player:
  Player{x, y, +z, angle, momx, momy, momz, floorz, ceilz, +viewheight, deltaview, viewz, crossed} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview,
    (z + viewheight : U32), crossed}

def Sim.eye.if(onground: Bool, +p: Player, swing: U32) -> Player:
  match onground:
    case True{}:
      Sim.eye.ground(p, swing)
    case False{}:
      Sim.eye.air(p)

# The bob is the squared momentum over four, at most 16 units; half of
# it swings the eye on the level's clock, a turn every 20 tics.
def Sim.eye(+level: L.Level, clock: U32, +p: Player) -> Player:
  Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  Sim.eye.if(Player.onground(p), p, F.Fixed.mul((F.Fixed.min(Sim.maxbob(),
    ((F.Fixed.mul(momx, momx) + F.Fixed.mul(momy, momy) : U32) >> 2n : U32)) >> 1n : U32),
    A.Angle.sin(L.Level.sine(level), ((409 * clock : U32) .&. 8191 : U32))))

# The vertical move
# -----------------

# Landing from a fall faster than eight units a tic dips the view by an
# eighth of the momentum.
def Sim.z.land(landing: Bool, +momz: U32, deltaview: U32) -> U32:
  match landing:
    case True{}:
      Bool.pick(U32, F.Fixed.lt(momz, F.Fixed.neg((Sim.gravity() << 3n : U32))),
        F.Fixed.sarn(momz, 3n), deltaview)
    case False{}:
      deltaview

# Below the ceiling: at most 56 under it, no rising momentum.
def Sim.z.ceiling(+z: U32, +momz: U32, +ceilz: U32) -> U32 & U32:
  +hit = F.Fixed.gt((z + Sim.height() : U32), ceilz)
  (Bool.pick(U32, hit, (ceilz - Sim.height() : U32), z),
    Bool.pick(U32, Bool.and(hit, F.Fixed.gt(momz, 0)), 0, momz))

def Sim.z.fin(+p: Player, zm: U32 & U32) -> Player:
  Player{x, y, oz, angle, momx, momy, omomz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  (z, momz) = zm
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed}

# On or under the floor the fall ends there; above it gravity pulls,
# doubled on the first airborne tic.
def Sim.z.clip(+p: Player, +z: U32) -> Player:
  Player{x, y, oz, angle, momx, momy, +momz, +floorz, +ceilz, viewheight, +deltaview, viewz, crossed} = p
  +floored = F.Fixed.le(z, floorz)
  +falling = F.Fixed.lt(momz, 0)
  +momz2 = Bool.pick(U32, floored, Bool.pick(U32, falling, 0, momz),
    Bool.pick(U32, U32.is_zero(momz), F.Fixed.neg((Sim.gravity() << 1n : U32)),
      (momz - Sim.gravity() : U32)))
  Sim.z.fin(Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight,
    Sim.z.land(Bool.and(floored, falling), momz, deltaview), viewz, crossed},
    Sim.z.ceiling(Bool.pick(U32, floored, floorz, z), momz2, ceilz))

# A floor risen under the player dips the view by the rise, to recover
# by an eighth of the gap a tic.
def Sim.z.step(+p: Player) -> Player:
  Player{x, y, +z, angle, momx, momy, +momz, +floorz, ceilz, +viewheight, deltaview, viewz, crossed} = p
  +below = F.Fixed.lt(z, floorz)
  +vh = Bool.pick(U32, below, (viewheight - (floorz - z) : U32), viewheight)
  Sim.z.clip(Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, vh,
    Bool.pick(U32, below, F.Fixed.sarn((Sim.viewheight() - vh : U32), 3n), deltaview),
    viewz, crossed}, (z + momz : U32))

def Sim.z.if(still: Bool, +p: Player) -> Player:
  match still:
    case True{}:
      p
    case False{}:
      Sim.z.step(p)

# Doom's P_ZMovement, run when the player is off the floor or moving
# vertically.
def Sim.z(+p: Player) -> Player:
  Player{x, y, +z, angle, momx, momy, +momz, +floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  Sim.z.if(Bool.and(U32.is_eq(z, floorz), U32.is_zero(momz)), p)

# The state
# ---------

# A step of a mover's plan: its plane moves to a height, down or up, or
# it waits some tics.
type Sim.Step is Data:
  Travel{down: Bool, dest: U32}
  Hold{tics: U32}

# Doom's thinkers. A mover is T_VerticalDoor, T_PlatRaise and T_MoveFloor
# in one: a sector's ceiling or floor, a speed, the steps left, and the
# whole plan, which a crushed mover starts again. A button is a pressed
# switch waiting to pop back: the side, which of its three textures, the
# texture it showed, and the tics left.
type Thinker is Data:
  Mover{sector: U32, ceiling: Bool, speed: U32, steps: List<&2, Sim.Step>, plan: List<&2, Sim.Step>}
  Button{side: U32, slot: U32, texture: U32, tics: U32}

# Everything a tic changes, in one value: the player, the level (its
# sectors' words and its lines' specials), the sides' texture numbers
# (top, bottom and middle a side, as the graphics number them), the
# thinkers in the order they run, the random table's index, the clock
# (Doom's leveltime), whether the level has ended, and whether use was
# down on the last tic.
type State is Data:
  State{player: Player, level: L.Level, sidetex: V.Vec, thinkers: List<&2, Thinker>, rnd: U32,
    clock: U32, ended: Bool, usedown: Bool}

# The state a level starts in, from the map as loaded, with the player
# at rest at a place and use counted as down, as Doom's G_PlayerReborn
# leaves it, so a key held since before the level does nothing.
def State.at(+level: L.Level, place: L.Level.Start) -> State:
  State{Player.at(level, place), level, L.Level.sidetex(level), [], 0, 0, False{}, True{}}

def State.start(+level: L.Level) -> State:
  State.at(level, L.Level.start_of(level))

def State.player(s: State) -> Player:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  player

def State.level(s: State) -> L.Level:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  level

def State.sidetex(s: State) -> V.Vec:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  sidetex

def State.thinkers(s: State) -> List<&2, Thinker>:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  thinkers

def State.rnd(s: State) -> U32:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  rnd

def State.clock(s: State) -> U32:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  clock

def State.ended(s: State) -> Bool:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  ended

def State.usedown(s: State) -> Bool:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  usedown

# The state with a thinker more, last to run.
def State.thinking(s: State, t: Thinker) -> State:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  State{player, level, sidetex, List.append(&2, Thinker, thinkers, [t]), rnd, clock, ended, usedown}

# Movers
# ------

# Doom's P_ThingHeightClip: the floor and ceiling under the player again,
# a player who stood on the floor kept on it, a head in the ceiling
# lowered under it, and whether the player still fits.
def Sim.reclip.fit(p: Player, f: Sim.Fit) -> Sim.Try:
  Player{x, y, +z, angle, momx, momy, momz, +floorz, ceilz, viewheight, deltaview, viewz, crossed} = p
  Fit{ok, +floor, +ceil} = f
  Try{F.Fixed.ge((ceil - floor : U32), Sim.height()), Player{x, y,
    Bool.pick(U32, U32.is_eq(z, floorz), floor, F.Fixed.min(z, (ceil - Sim.height() : U32))), angle, momx,
    momy, momz, floor, ceil, viewheight, deltaview, viewz, crossed}}

def Sim.reclip(+level: L.Level, +p: Player) -> Sim.Try:
  Sim.reclip.fit(p, Sim.fit(level, Player.x(p), Player.y(p)))

# A mover with steps left runs again next tic, after those kept so far;
# one with none has ended.
def Sim.mover.kept(sector: U32, ceiling: Bool, speed: U32, steps: List<&2, Sim.Step>,
  plan: List<&2, Sim.Step>, s: State) -> State:
  match steps:
    case []:
      s
    case step <> rest:
      State.thinking(s, Mover{sector, ceiling, speed, step <> rest, plan})

# A step the player does not fit is undone, the player clipped again,
# and the mover crushed: it starts its plan again, unless the step was
# its travel's last, which Doom ends all the same.
def Sim.mover.fitted(t: Sim.Try, +sector: U32, +ceiling: Bool, speed: U32, was: U32, past: Bool,
  +rest: List<&2, Sim.Step>, going: List<&2, Sim.Step>, +plan: List<&2, Sim.Step>, s: State) -> State:
  match t:
    case Try{True{}, p}:
      State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
      Sim.mover.kept(sector, ceiling, speed, going, plan,
        State{p, level, sidetex, thinkers, rnd, clock, ended, usedown})
    case Try{False{}, +p}:
      State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
      +undone = L.Level.plane.put(level, sector, ceiling, was)
      Sim.mover.kept(sector, ceiling, speed, Bool.pick(List<&2, Sim.Step>, past, rest, plan), plan,
        State{Sim.Try.player(Sim.reclip(undone, p)), undone, sidetex, thinkers, rnd, clock, ended, usedown})

# Doom's P_ChangeSector for the one thing there is: the player is
# clipped again when in a cell of the sector's block box, touching the
# sector or not.
def Sim.mover.changed(near: Bool, +sector: U32, +ceiling: Bool, speed: U32, was: U32, past: Bool,
  rest: List<&2, Sim.Step>, going: List<&2, Sim.Step>, plan: List<&2, Sim.Step>, +s: State) -> State:
  match near:
    case False{}:
      Sim.mover.kept(sector, ceiling, speed, going, plan, s)
    case True{}:
      Sim.mover.fitted(Sim.reclip(State.level(s), State.player(s)), sector, ceiling, speed, was, past, rest,
        going, plan, s)

# Doom's T_MovePlane: a step that would pass the destination lands on it
# and ends the travel.
def Sim.mover.move(+sector: U32, +ceiling: Bool, +speed: U32, +down: Bool, +dest: U32,
  +rest: List<&2, Sim.Step>, plan: List<&2, Sim.Step>, s: State) -> State:
  State{+player, +level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  +was = L.Level.plane(level, sector, ceiling)
  +next = Bool.pick(U32, down, (was - speed : U32), (was + speed : U32))
  +past = Bool.pick(Bool, down, F.Fixed.lt(next, dest), F.Fixed.gt(next, dest))
  Sim.mover.changed(L.Level.blocked(level, sector, Player.x(player), Player.y(player)), sector, ceiling,
    speed, was, past, rest, Bool.pick(List<&2, Sim.Step>, past, rest, Travel{down, dest} <> rest), plan,
    State{player, L.Level.plane.put(level, sector, ceiling, Bool.pick(U32, past, dest, next)), sidetex,
      thinkers, rnd, clock, ended, usedown})

# Doom's button in P_UpdateSpecials: the tic its count reaches zero the
# side shows its texture again.
def Sim.button(done: Bool, side: U32, slot: U32, texture: U32, tics: U32, s: State) -> State:
  match done:
    case True{}:
      State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
      State{player, level, V.Vec.set(sidetex, (side * 3 + slot : U32), texture), thinkers, rnd, clock, ended,
        usedown}
    case False{}:
      State.thinking(s, Button{side, slot, texture, (tics - 1 : U32)})

# A thinker's tic. A wait counts down, and the tic it reaches zero does
# nothing else, as Doom's doors and lifts turn.
def Sim.think(t: Thinker, s: State) -> State:
  match t:
    case Mover{sector, ceiling, speed, [], plan}:
      s
    case Mover{sector, ceiling, speed, Hold{+tics} <> +rest, plan}:
      Sim.mover.kept(sector, ceiling, speed, Bool.pick(List<&2, Sim.Step>, U32.is_eq(tics, 1), rest,
        Hold{(tics - 1 : U32)} <> rest), plan, s)
    case Mover{sector, ceiling, speed, Travel{down, dest} <> rest, plan}:
      Sim.mover.move(sector, ceiling, speed, down, dest, rest, plan, s)
    case Button{side, slot, texture, +tics}:
      Sim.button(U32.is_eq(tics, 1), side, slot, texture, tics, s)

# Doom's P_RunThinkers: each in turn, in the order they were started,
# the state's list being those kept so far.
def Sim.thinkers.go(todo: List<&2, Thinker>, s: State) -> State:
  match todo:
    case []:
      s
    case t <> rest:
      Sim.thinkers.go(rest, Sim.think(t, s))

def Sim.thinkers(s: State) -> State:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  Sim.thinkers.go(thinkers, State{player, level, sidetex, [], rnd, clock, ended, usedown})

# The sectors across a sector's two-sided lines, as Doom's getNextSector
# answers them line by line: the back of a line whose front is the
# sector, else the front.
def Sim.around.of(+sector: U32, line: L.Level.Line, rest: List<&2, U32>) -> List<&2, U32>:
  L.Line{x1, y1, x2, y2, flags, +front, +back} = line
  Sim.keep(Bool.and(Bool.not(U32.is_zero((flags .&. 4 : U32))),
    Bool.and(Bool.not(U32.is_eq(back, L.Level.none())),
      Bool.or(U32.is_eq(front, sector), U32.is_eq(back, sector)))),
    Bool.pick(U32, U32.is_eq(front, sector), back, front), rest)

def Sim.around.go(n: Nat, +level: L.Level, +sector: U32, +i: U32) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      Sim.around.of(sector, L.Level.line(level, i), Sim.around.go(m, level, sector, (i + 1 : U32)))

def Sim.around(+level: L.Level, sector: U32) -> List<&2, U32>:
  Sim.around.go(U32.to_nat(L.Level.nlines(level)), level, sector, 0)

# The least or the most of a plane over some sectors, from a first
# value: Doom's P_FindLowestCeilingSurrounding and its kin.
def Sim.extreme(~pick: @+a: U32 -> @+b: U32 -> U32, sectors: List<&2, U32>, +level: L.Level,
  +ceiling: Bool, acc: U32) -> U32:
  match sectors:
    case []:
      acc
    case s <> rest:
      Sim.extreme(~pick, rest, level, ceiling, pick(acc, L.Level.plane(level, s, ceiling)))

def Sim.moving(thinkers: List<&2, Thinker>, +sector: U32) -> Bool:
  match thinkers:
    case []:
      False{}
    case Mover{s, ceiling, speed, steps, plan} <> rest:
      Bool.or(U32.is_eq(s, sector), Sim.moving(rest, sector))
    case Button{side, slot, texture, tics} <> rest:
      Sim.moving(rest, sector)

# A mover at the start of its plan.
def Sim.mover.new(sector: U32, ceiling: Bool, speed: U32, +plan: List<&2, Sim.Step>) -> Thinker:
  Mover{sector, ceiling, speed, plan, plan}

# Doors
# -----

# Doom's EV_VerticalDoor on a door already moving: one closing goes back
# up through its plan, any other starts down at once.
def Sim.door.turned(steps: List<&2, Sim.Step>, plan: List<&2, Sim.Step>, floor: U32) ->
  List<&2, Sim.Step>:
  match steps:
    case Travel{True{}, dest} <> rest:
      plan
    case _:
      [Travel{True{}, floor}]

def Sim.door.turn(thinkers: List<&2, Thinker>, +sector: U32, +floor: U32) -> List<&2, Thinker>:
  match thinkers:
    case []:
      []
    case Mover{+s, ceiling, speed, +steps, +plan} <> rest:
      Mover{s, ceiling, speed, Bool.pick(List<&2, Sim.Step>, U32.is_eq(s, sector),
        Sim.door.turned(steps, plan, floor), steps), plan} <> Sim.door.turn(rest, sector, floor)
    case Button{side, slot, texture, tics} <> rest:
      Button{side, slot, texture, tics} <> Sim.door.turn(rest, sector, floor)

# A door's top: 4 under the lowest ceiling around it.
def Sim.door.top(+level: L.Level, sector: U32) -> U32:
  (Sim.extreme(~F.Fixed.min, Sim.around(level, sector), level, True{}, 2147483647) - 262144 : U32)

# A door's plan: up to its top, 150 tics open, down to its floor.
def Sim.door.plan(+level: L.Level, +sector: U32) -> List<&2, Sim.Step>:
  [Travel{False{}, Sim.door.top(level, sector)}, Hold{150}, Travel{True{}, L.Level.floor(level, sector)}]

def Sim.door.on(moving: Bool, +sector: U32, speed: U32, +s: State) -> State:
  match moving:
    case True{}:
      State{player, +level, sidetex, thinkers, rnd, clock, ended, usedown} = s
      State{player, level, sidetex, Sim.door.turn(thinkers, sector, L.Level.floor(level, sector)), rnd,
        clock, ended, usedown}
    case False{}:
      State.thinking(s, Sim.mover.new(sector, True{}, speed, Sim.door.plan(State.level(s), sector)))

# Doom's EV_VerticalDoor: the door is the sector behind the line.
def Sim.door(line: L.Level.Line, speed: U32, +s: State) -> State:
  L.Line{x1, y1, x2, y2, flags, front, +back} = line
  Sim.door.on(Sim.moving(State.thinkers(s), back), back, speed, s)

# Switches and tagged movers
# --------------------------

# The sectors of a tag with no mover, in sector order: the ones a tagged
# special starts, as Doom passes over a sector whose specialdata is set.
def Sim.tagged.go(n: Nat, +level: L.Level, +thinkers: List<&2, Thinker>, +tag: U32, +s: U32) ->
  List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      Sim.keep(Bool.and(U32.is_eq(L.Level.sector.tag(level, s), tag), Bool.not(Sim.moving(thinkers, s))), s,
        Sim.tagged.go(m, level, thinkers, tag, (s + 1 : U32)))

def Sim.tagged(+s: State, line: U32) -> List<&2, U32>:
  Sim.tagged.go(U32.to_nat(L.Level.nsectors(State.level(s))), State.level(s), State.thinkers(s),
    L.Level.tag(State.level(s), line), 0)

# A mover made for each sector, all against the level as it stood.
def Sim.start(~make: @+level: L.Level -> @+sector: U32 -> Thinker, sectors: List<&2, U32>, +s: State) ->
  State:
  match sectors:
    case []:
      s
    case sector <> rest:
      Sim.start(~make, rest, State.thinking(s, make(State.level(s), sector)))

# Doom's lowerFloorToLowest: 1 a tic down to the lowest floor around,
# its own included.
def Sim.floor.low(+level: L.Level, +sector: U32) -> Thinker:
  Sim.mover.new(sector, False{}, 65536, [Travel{True{}, Sim.extreme(~F.Fixed.min,
    Sim.around(level, sector), level, False{}, L.Level.floor(level, sector))}])

# Which of a side's three textures is a switch: the top, else the
# middle, else the bottom; 3 when none is.
def Sim.switch.slot(+level: L.Level, +sidetex: V.Vec, +at: U32) -> U32:
  Bool.pick(U32, U32.is_zero(L.Level.switch(level, V.Vec.get(sidetex, at))),
    Bool.pick(U32, U32.is_zero(L.Level.switch(level, V.Vec.get(sidetex, (at + 2 : U32)))),
      Bool.pick(U32, U32.is_zero(L.Level.switch(level, V.Vec.get(sidetex, (at + 1 : U32)))), 3, 1), 2), 0)

def Sim.pressed.side(thinkers: List<&2, Thinker>, +side: U32) -> Bool:
  match thinkers:
    case []:
      False{}
    case Button{pressed, slot, texture, tics} <> rest:
      Bool.or(U32.is_eq(pressed, side), Sim.pressed.side(rest, side))
    case Mover{sector, ceiling, speed, steps, plan} <> rest:
      Sim.pressed.side(rest, side)

# A switch that works again starts a button of 35 tics for the texture
# it showed, unless its side has one running.
def Sim.switch.button(start: Bool, side: U32, slot: U32, showed: U32, s: State) -> State:
  match start:
    case False{}:
      s
    case True{}:
      State.thinking(s, Button{side, slot, showed, 35})

# The switch's texture swapped for its partner.
def Sim.switch.swap(none: Bool, again: Bool, +side: U32, +slot: U32, s: State) -> State:
  match none:
    case True{}:
      s
    case False{}:
      State{player, +level, +sidetex, +thinkers, rnd, clock, ended, usedown} = s
      +showed = V.Vec.get(sidetex, (side * 3 + slot : U32))
      Sim.switch.button(Bool.and(again, Bool.not(Sim.pressed.side(thinkers, side))), side, slot, showed,
        State{player, level, V.Vec.set(sidetex, (side * 3 + slot : U32), L.Level.switch(level, showed)),
          thinkers, rnd, clock, ended, usedown})

# Doom's P_ChangeSwitchTexture on the line's front side.
def Sim.switch(again: Bool, line: U32, +s: State) -> State:
  +side = L.Level.line.side(State.level(s), line, 0)
  +slot = Sim.switch.slot(State.level(s), State.sidetex(s), (side * 3 : U32))
  Sim.switch.swap(U32.is_eq(slot, 3), again, side, slot, s)

# A line that works once has no special afterwards.
def Sim.once(line: U32, s: State) -> State:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  State{player, L.Level.special.put(level, line, 0), sidetex, thinkers, rnd, clock, ended, usedown}

# Doom's G_ExitLevel: the level ends, and the tic it ends on runs on.
def State.end(s: State) -> State:
  State{player, level, sidetex, thinkers, rnd, clock, ended, usedown} = s
  State{player, level, sidetex, thinkers, rnd, clock, True{}, usedown}

# A switch that works once: when its tag starts a mover, its texture is
# swapped and its special cleared.
def Sim.use.once(~make: @+level: L.Level -> @+sector: U32 -> Thinker, sectors: List<&2, U32>, +line: U32,
  s: State) -> State:
  match sectors:
    case []:
      s
    case sector <> rest:
      Sim.once(line, Sim.switch(False{}, line, Sim.start(~make, sector <> rest, s)))

# A switch that works again: when its tag starts a mover, its texture is
# swapped for 35 tics.
def Sim.use.again(~make: @+level: L.Level -> @+sector: U32 -> Thinker, sectors: List<&2, U32>, line: U32,
  +s: State) -> State:
  match sectors:
    case []:
      s
    case sector <> rest:
      Sim.switch(True{}, line, Sim.start(~make, sector <> rest, s))

# Doom's downWaitUpStay lift: 4 a tic down to the lowest floor around,
# its own included, 105 tics there, and back up to where it was.
def Sim.lift(+level: L.Level, +sector: U32) -> Thinker:
  Sim.mover.new(sector, False{}, 262144, [Travel{True{}, Sim.extreme(~F.Fixed.min,
    Sim.around(level, sector), level, False{}, L.Level.floor(level, sector))}, Hold{105},
    Travel{False{}, L.Level.floor(level, sector)}])

# Walk-over lines
# ---------------

# Doom's EV_DoDoor open: up to the door's top, where it stays.
def Sim.door.open(+level: L.Level, +sector: U32) -> Thinker:
  Sim.mover.new(sector, True{}, 131072, [Travel{False{}, Sim.door.top(level, sector)}])

# Doom's turboLower: 4 a tic down to the highest floor around, plus 8
# when that is not the floor's own height. A travel down to a height
# above lands at once, as Doom's does.
def Sim.floor.turbo.to(+highest: U32, own: U32) -> U32:
  Bool.pick(U32, U32.is_eq(highest, own), highest, (highest + 524288 : U32))

def Sim.floor.turbo(+level: L.Level, +sector: U32) -> Thinker:
  Sim.mover.new(sector, False{}, 262144, [Travel{True{}, Sim.floor.turbo.to(Sim.extreme(~F.Fixed.max,
    Sim.around(level, sector), level, False{}, 4262199296), L.Level.floor(level, sector))}])

# Doom's P_CrossSpecialLine for the specials E1M1 carries. The two that
# work once lose their special whether or not a sector started; the
# lift's line works every time.
def Sim.cross.special(special: U32, +line: U32, +s: State) -> State:
  match special:
    case 2:
      Sim.once(line, Sim.start(~Sim.door.open, Sim.tagged(s, line), s))
    case 36:
      Sim.once(line, Sim.start(~Sim.floor.turbo, Sim.tagged(s, line), s))
    case 88:
      Sim.start(~Sim.lift, Sim.tagged(s, line), s)
    case _:
      s

# The lines the player's moves crossed this tic, each by the special it
# has when its turn comes.
def Sim.cross(lines: List<&2, U32>, +s: State) -> State:
  match lines:
    case []:
      s
    case +line <> rest:
      Sim.cross(rest, Sim.cross.special(L.Level.special(State.level(s), line), line, s))

# Use
# ---

# Doom's P_UseSpecialLine for the specials E1M1 carries: the manual door
# and its blazing twin, the switch that lowers floors, the lift's, and
# the exit. The blue key door is not among them until keys exist, so it
# refuses, as any special Doom does not know does nothing.
def Sim.use.special(special: U32, +i: U32, +s: State) -> State:
  match special:
    case 1:
      Sim.door(L.Level.line(State.level(s), i), 131072, s)
    case 117:
      Sim.door(L.Level.line(State.level(s), i), 524288, s)
    case 23:
      Sim.use.once(~Sim.floor.low, Sim.tagged(s, i), i, s)
    case 62:
      Sim.use.again(~Sim.lift, Sim.tagged(s, i), i, s)
    case 11:
      State.end(Sim.once(i, Sim.switch(False{}, i, s)))
    case _:
      s

# Only the front of a line answers use.
def Sim.use.line(back: Bool, +level: L.Level, +i: U32, s: State) -> State:
  match back:
    case True{}:
      s
    case False{}:
      Sim.use.special(L.Level.special(level, i), i, s)

def Sim.use.hit(hit: Maybe<&2, U32>, +p: Player, +s: State) -> State:
  match hit:
    case None{}:
      s
    case Some{+i}:
      Sim.use.line(Sim.point_side(Player.x(p), Player.y(p), L.Level.line(State.level(s), i)),
        State.level(s), i, s)

# Doom's P_LineOpening leaves no opening in a line with one side.
def Sim.use.shut(+level: L.Level, +line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, flags, front, back} = line
  Bool.or(U32.is_eq(back, L.Level.none()),
    F.Fixed.le((Sim.open_top(level, line) - Sim.open_bottom(level, line) : U32), 0))

def Sim.use.first.pick(special: Bool, shut: Bool, i: U32, later: Maybe<&2, U32>) -> Maybe<&2, U32>:
  match special shut:
    case True{} _:
      Some{i}
    case False{} True{}:
      None{}
    case False{} False{}:
      later

# Doom's PTR_UseTraverse along the sorted meets: the first special line
# ends the trace whatever its special; a line without one lets it go on
# when its opening is more than nothing.
def Sim.use.first(sorted: List<&2, Sim.Meet>, +level: L.Level) -> Maybe<&2, U32>:
  match sorted:
    case []:
      None{}
    case Meet{frac, +i} <> rest:
      Sim.use.first.pick(Bool.not(U32.is_zero(L.Level.special(level, i))),
        Sim.use.shut(level, L.Level.line(level, i)), i, Sim.use.first(rest, level))

def Sim.Meet.frac(m: Sim.Meet) -> U32:
  Meet{frac, line} = m
  frac

# A meet into a list sorted by fraction, after its equals, so the first
# gathered of equals stays first, as Doom picks them.
def Sim.use.insert(+m: Sim.Meet, sorted: List<&2, Sim.Meet>) -> List<&2, Sim.Meet>:
  match sorted:
    case []:
      [m]
    case +h <> +rest:
      Bool.pick(List<&2, Sim.Meet>, U32.is_lt(Sim.Meet.frac(m), Sim.Meet.frac(h)), m <> h <> rest,
        h <> Sim.use.insert(m, rest))

def Sim.use.sort(meets: List<&2, Sim.Meet>, sorted: List<&2, Sim.Meet>) -> List<&2, Sim.Meet>:
  match meets:
    case []:
      sorted
    case m <> rest:
      Sim.use.sort(rest, Sim.use.insert(m, sorted))

# Doom's P_UseLines, on the press: a trace of 64 units along the facing.
def Sim.use(press: Bool, +p: Player, +s: State) -> State:
  match press:
    case False{}:
      s
    case True{}:
      +level = State.level(s)
      +sine = L.Level.sine(level)
      +f = A.Angle.fine(Player.angle(p))
      Sim.use.hit(Sim.use.first(Sim.use.sort(Sim.meets(level, Player.x(p), Player.y(p),
        (Player.x(p) + 64 * A.Angle.cos(sine, f) : U32), (Player.y(p) + 64 * A.Angle.sin(sine, f) : U32)), []),
        level), p, s)

# The tic
# -------

# Use acts on the tic it goes down, not while it is held.
def Sim.pressed(cmd: K.Cmd, usedown: Bool) -> Bool:
  Bool.and(K.Cmd.use(cmd), Bool.not(usedown))

# The player as moved, at the height, floor and ceiling a mover left,
# the lines it crossed fired and forgotten.
def Player.stood(moved: Player, +q: Player) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed} = moved
  Player{x, y, Player.z(q), angle, momx, momy, momz, Player.floorz(q), Player.ceilz(q), viewheight,
    deltaview, viewz, []}

# What a live tic keeps of the state it began with, whatever the
# thinkers did: the geometry, so no tic writes a wall, and the place the
# movement left the player, so no mover pushes the player sideways.
def Sim.tic.kept(geo: L.Level.Geo, moved: Player, clock: U32, use: Bool, +after: State) -> State:
  State{Player.stood(moved, State.player(after)), L.Level{geo, L.Level.sectors(State.level(after)), L.Level.specials(State.level(after))},
    State.sidetex(after), State.thinkers(after), State.rnd(after), (clock + 1 : U32), State.ended(after),
    use}

# One tic in Doom's order: the player thinks (the move, the eye, then
# use on the press), the XY and the vertical movement, the lines that
# movement crossed, the thinkers in the order they were started, the
# clock. An ended level stands still.
def Sim.tic(+cmd: K.Cmd, s: State) -> State:
  match s:
    case State{player, level, sidetex, thinkers, rnd, clock, True{}, usedown}:
      State{player, level, sidetex, thinkers, rnd, clock, True{}, usedown}
    case State{player, L.Level{+geo, sectors, specials}, sidetex, thinkers, rnd, +clock, False{}, +usedown}:
      +level = {L.Level{geo, sectors, specials} : L.Level}
      +thought = Sim.eye(level, clock, Sim.move(level, cmd, player))
      +moved = Sim.z(Sim.xy(level, cmd, thought))
      Sim.tic.kept(geo, moved, clock, K.Cmd.use(cmd), Sim.thinkers(Sim.cross(Player.crossed(moved),
        Sim.use(Sim.pressed(cmd, usedown), thought,
          State{moved, level, sidetex, thinkers, rnd, clock, False{}, usedown}))))

# A tic for each command of the list, in order: a demo.
def Sim.replay(script: List<&2, K.Cmd>, s: State) -> State:
  match script:
    case []:
      s
    case cmd <> rest:
      Sim.replay(rest, Sim.tic(cmd, s))
