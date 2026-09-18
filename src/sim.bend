# The playsim for one player and no things: Doom's P_MovePlayer,
# P_XYMovement, P_TryMove, P_CheckPosition and P_SlideMove, as pure
# functions of the level, the held keys and the player. Every position
# the player is moved to has passed Sim.fit, which is what Sim.free
# asks, so the wall law holds by construction; z tracks the floor.
import Base
import ./vec.bend as V
import ./fixed.bend as F
import ./angle.bend as A
import ./level.bend as L
import ./keys.bend as K

type Player is Data:
  Player{x: U32, y: U32, angle: U32, momx: U32, momy: U32, floorz: U32,
    turnheld: U32}

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

def Player.x(+p: Player) -> U32:
  Player{x, y, angle, momx, momy, floorz, turnheld} = p
  x

def Player.y(+p: Player) -> U32:
  Player{x, y, angle, momx, momy, floorz, turnheld} = p
  y

def Player.angle(+p: Player) -> U32:
  Player{x, y, angle, momx, momy, floorz, turnheld} = p
  angle

def Player.momx(+p: Player) -> U32:
  Player{x, y, angle, momx, momy, floorz, turnheld} = p
  momx

def Player.floorz(+p: Player) -> U32:
  Player{x, y, angle, momx, momy, floorz, turnheld} = p
  floorz

def Player.at(+level: L.Level, s: L.Level.Start) -> Player:
  L.Start{+x, +y, angle} = s
  Player{x, y, angle, 0, 0, L.Level.floor(level, L.Level.sector_at(level, x, y)), 0}

# The player at the level's start, on its floor.
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

def Sim.column(m: Nat, +level: L.Level, +bx: U32, +by: U32) -> List<&2, U32>:
  match m:
    case 0n:
      []
    case 1n+k:
      List.append(&2, U32, L.Level.cell(level, bx, by), Sim.column(k, level, bx, (by + 1 : U32)))

def Sim.cells(n: Nat, +m: Nat, +level: L.Level, +bx: U32, +by: U32) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+k:
      List.append(&2, U32, Sim.column(m, level, bx, by), Sim.cells(k, m, level, (bx + 1 : U32), by))

def Sim.lines.at(+bm: L.Level.Blockmap, +level: L.Level, +x0: U32, +y0: U32, +x1: U32, +y1: U32) ->
  List<&2, U32>:
  L.Blockmap{words, +ox, +oy, cols, rows} = bm
  +xl = Sim.block(x0, ox)
  +yl = Sim.block(y0, oy)
  Sim.cells(U32.to_nat((Sim.block(x1, ox) - xl + 1 : U32)),
    U32.to_nat((Sim.block(y1, oy) - yl + 1 : U32)), level, xl, yl)

def Sim.lines(+level: L.Level, x0: U32, y0: U32, x1: U32, y1: U32) -> List<&2, U32>:
  Sim.lines.at(L.Level.blockmap_of(level), level, x0, y0, x1, y1)

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

def Sim.try_move.fin(go: Bool, p: Player, x: U32, y: U32, floor: U32) -> Sim.Try:
  match go:
    case False{}:
      Try{False{}, p}
    case True{}:
      Player{ox, oy, angle, momx, momy, floorz, turnheld} = p
      Try{True{}, Player{x, y, angle, momx, momy, floor, turnheld}}

# The move is taken when the position is free, the opening fits the
# player, the ceiling is high enough from the player's feet, and the
# floor is at most 24 units up.
def Sim.try_move.fit(+p: Player, x: U32, y: U32, f: Sim.Fit) -> Sim.Try:
  Fit{ok, +floor, +ceil} = f
  +z = Player.floorz(p)
  Sim.try_move.fin(Bool.and(ok, Bool.and(F.Fixed.ge((ceil - floor : U32), Sim.height()),
    Bool.and(F.Fixed.ge((ceil - z : U32), Sim.height()),
      F.Fixed.le((floor - z : U32), Sim.step_up())))), p, x, y, floor)

# Doom's P_TryMove.
def Sim.try_move(+level: L.Level, p: Player, +x: U32, +y: U32) -> Sim.Try:
  Sim.try_move.fit(p, x, y, Sim.fit(level, x, y))

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
  +z = Player.floorz(p)
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

def Sim.hit.near(near: Bool, +level: L.Level, +p: Player, +line: L.Level.Line, frac: U32,
  i: U32, best: U32 & U32) -> U32 & U32:
  match near:
    case False{}:
      best
    case True{}:
      Sim.hit.blocked(Sim.blocks(level, p, line), frac, i, best)

def Sim.hit(+level: L.Level, +p: Player, +tx: U32, +ty: U32, +tdx: U32, +tdy: U32, +i: U32,
  best: U32 & U32) -> U32 & U32:
  +line = L.Level.line(level, i)
  +frac = Sim.intercept(tx, ty, tdx, tdy, line)
  Sim.hit.near(U32.is_le(frac, F.Fixed.unit()), level, p, line, frac, i, best)

def Sim.trace.go(lines: List<&2, U32>, +level: L.Level, +p: Player, +tx: U32, +ty: U32,
  +tdx: U32, +tdy: U32, best: U32 & U32) -> U32 & U32:
  match lines:
    case []:
      best
    case i <> rest:
      Sim.trace.go(rest, level, p, tx, ty, tdx, tdy, Sim.hit(level, p, tx, ty, tdx, tdy, i, best))

# A trace that starts on a cell's edge is nudged off it, as Doom's.
def Sim.nudge(+v: U32, +org: U32) -> U32:
  Bool.pick(U32, U32.is_zero(((v - org : U32) .&. 8388607 : U32)), (v + F.Fixed.unit() : U32), v)

def Sim.trace.at(+bm: L.Level.Blockmap, +level: L.Level, +p: Player, +x1: U32, +y1: U32,
  +x2: U32, +y2: U32, best: U32 & U32) -> U32 & U32:
  L.Blockmap{words, +ox, +oy, cols, rows} = bm
  +tx = Sim.nudge(x1, ox)
  +ty = Sim.nudge(y1, oy)
  Sim.trace.go(Sim.lines(level, F.Fixed.min(tx, x2), F.Fixed.min(ty, y2),
    F.Fixed.max(tx, x2), F.Fixed.max(ty, y2)), level, p, tx, ty, (x2 - tx : U32),
    (y2 - ty : U32), best)

# Doom's P_PathTraverse with PTR_SlideTraverse: the closest blocking
# line along the trace, gathered from the cells the trace's box
# touches rather than walked cell by cell.
def Sim.trace(+level: L.Level, +p: Player, x1: U32, y1: U32, x2: U32, y2: U32, best: U32 & U32) ->
  U32 & U32:
  Sim.trace.at(L.Level.blockmap_of(level), level, p, x1, y1, x2, y2, best)

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
  Player{+x, +y, angle, momx, +momy, floorz, turnheld} = p
  Sim.stairstep.fin(level, Sim.try_move(level, p, x, (y + momy : U32)))

# The remainder of the move, clipped along the wall, becomes the
# momentum and is tried; a failure retries the slide from here.
def Sim.slide.wall.go(+level: L.Level, +p: Player, m: U32 & U32) -> Sim.Try:
  Player{+x, +y, angle, momx, momy, floorz, turnheld} = p
  (+mx, +my) = m
  Sim.try_move(level, Player{x, y, angle, mx, my, floorz, turnheld}, (x + mx : U32),
    (y + my : U32))

def Sim.slide.wall(left: Bool, +level: L.Level, +p: Player, +frac: U32, i: U32) -> Sim.Try:
  match left:
    case False{}:
      Try{True{}, p}
    case True{}:
      Player{x, y, angle, +momx, +momy, floorz, turnheld} = p
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
      Player{+x, +y, angle, +momx, +momy, floorz, turnheld} = p
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
  Player{+x, +y, angle, +momx, +momy, floorz, turnheld} = p
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

# Doom's friction: momentum below the stop speed with no move key
# held stops, else it decays by 0.90625 a tic.
def Sim.slow(stop: Bool, p: Player) -> Player:
  match stop:
    case True{}:
      Player{x, y, angle, momx, momy, floorz, turnheld} = p
      Player{x, y, angle, 0, 0, floorz, turnheld}
    case False{}:
      Player{x, y, angle, momx, momy, floorz, turnheld} = p
      Player{x, y, angle, F.Fixed.mul(momx, Sim.decay()), F.Fixed.mul(momy, Sim.decay()),
        floorz, turnheld}

def Sim.crawling(+mom: U32) -> Bool:
  Bool.and(F.Fixed.gt(mom, F.Fixed.neg(Sim.stopspeed())), F.Fixed.lt(mom, Sim.stopspeed()))

def Sim.friction(+cmd: K.Cmd, +p: Player) -> Player:
  K.Cmd{forward, side, turn} = cmd
  Player{x, y, angle, +momx, +momy, floorz, turnheld} = p
  Sim.slow(Bool.and(Sim.crawling(momx), Bool.and(Sim.crawling(momy),
    Bool.and(U32.is_zero(forward), U32.is_zero(side)))), p)

def Sim.clamp(+mom: U32) -> U32:
  F.Fixed.max(F.Fixed.neg(Sim.maxmove()), F.Fixed.min(mom, Sim.maxmove()))

def Sim.xy.moving(moving: Bool, +level: L.Level, +cmd: K.Cmd, +p: Player) -> Player:
  match moving:
    case False{}:
      p
    case True{}:
      Player{x, y, angle, momx, momy, floorz, turnheld} = p
      +xm = Sim.clamp(momx)
      +ym = Sim.clamp(momy)
      Sim.friction(cmd, Sim.xy.go(2n, level,
        Xy{False{}, Player{x, y, angle, xm, ym, floorz, turnheld}, xm, ym}))

# Doom's P_XYMovement: the momentum, capped, moves the player, in
# halves when large; a blocked move slides; then friction.
def Sim.xy(+level: L.Level, cmd: K.Cmd, +p: Player) -> Player:
  Player{x, y, angle, +momx, +momy, floorz, turnheld} = p
  Sim.xy.moving(Bool.not(Bool.and(U32.is_zero(momx), U32.is_zero(momy))), level, cmd, p)

# The tic
# -------

# Doom's P_Thrust: momentum along an angle.
def Sim.thrust(+level: L.Level, p: Player, +angle: U32, +move: U32) -> Player:
  Player{x, y, a, momx, momy, floorz, turnheld} = p
  +sine = L.Level.sine(level)
  +f = A.Angle.fine(angle)
  Player{x, y, a, (momx + F.Fixed.mul(move, A.Angle.cos(sine, f)) : U32),
    (momy + F.Fixed.mul(move, A.Angle.sin(sine, f)) : U32), floorz, turnheld}

def Sim.push(+level: L.Level, +p: Player, +angle: U32, +move: U32) -> Player:
  Bool.pick(Player, U32.is_zero(move), p, Sim.thrust(level, p, angle, (move * 2048 : U32)))

# Doom's P_MovePlayer: turn, then thrust forward and sideways.
def Sim.move(+level: L.Level, +cmd: K.Cmd, p: Player) -> Player:
  K.Cmd{forward, side, turn} = cmd
  Player{x, y, angle, momx, momy, floorz, turnheld} = p
  +a = (angle + (turn << 16n) : U32)
  Sim.push(level, Sim.push(level, Player{x, y, a, momx, momy, floorz, turnheld}, a, forward),
    (a - A.Angle.ang90() : U32), side)

# One tic: the command from the held keys, the move, the XY movement.
def Sim.tic(+level: L.Level, +keys: K.Keys, p: Player) -> Player:
  Player{x, y, angle, momx, momy, floorz, turnheld} = p
  +held = K.Keys.held(keys, turnheld)
  +cmd = K.Keys.cmd(keys, held)
  Sim.xy(level, cmd, Sim.move(level, cmd, Player{x, y, angle, momx, momy, floorz, held}))

# n tics of the same held keys.
def Sim.run(n: Nat, +level: L.Level, +keys: K.Keys, p: Player) -> Player:
  match n:
    case 0n:
      p
    case 1n+m:
      Sim.run(m, level, keys, Sim.tic(level, keys, p))

# A tic for each element of the list, in order: a demo.
def Sim.replay(script: List<&2, K.Keys>, +level: L.Level, p: Player) -> Player:
  match script:
    case []:
      p
    case keys <> rest:
      Sim.replay(rest, level, Sim.tic(level, keys, p))
