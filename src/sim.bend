# The playsim for one player among things: Doom's P_MovePlayer,
# P_CalcHeight, P_MovePsprites, P_XYMovement, P_TryMove,
# P_CheckPosition, P_SlideMove and P_ZMovement, as pure functions of the
# level, the things, the tic command and the player, and the tic that
# maps one state of the level to the next, with the sounds that tic
# starts and stops where vanilla calls S_StartSound and S_StopSound.
# Every position the player is moved to has passed Sim.check, whose
# lines are what Sim.free asks, so the wall law holds by construction.
import Base
import ./vec.bend as V
import ./fixed.bend as F
import ./angle.bend as A
import ./level.bend as L
import ./keys.bend as K
import ./random.bend as M
import ./things.bend as H
import ./inventory.bend as I
import ./sound.bend as Sn

# Doom's pspdef_t, a player sprite: its state row, none while it does
# not show, the tics left in it, and its place on a 320 by 200 screen.
type Psprite is Data:
  Psprite{state: Maybe<&2, U32>, tics: U32, sx: U32, sy: U32}

# The player's sprites: the weapon and its muzzle flash.
type Psprites is Data:
  Psprites{weapon: Psprite, flash: Psprite}

# Doom's mobj and player_t for one player: the position with its height,
# the angle, the momentum, the floor and ceiling under it, the view
# height and its delta, the eye's height, the special lines this tic's
# moves have crossed, in the order they fire, the inventory, and the
# player sprites.
type Player is Data:
  Player{x: U32, y: U32, z: U32, angle: U32, momx: U32, momy: U32, momz: U32,
    floorz: U32, ceilz: U32, viewheight: U32, deltaview: U32, viewz: U32, crossed: List<&2, U32>,
    inv: I.Inventory, psprites: Psprites}

# What Doom's P_CheckPosition and PIT_CheckThing read of a mobj, the one
# moved or one in its way: its id, its centre, its feet, its radius and
# height in fixed point, and its flags.
type Sim.Body is Data:
  Body{id: U32, x: U32, y: U32, z: U32, radius: U32, height: U32, flags: U32}

# What the thing half of Doom's P_CheckPosition meets: the mobjs near
# before the first that stops the box, in the blockmap's order, and that
# one, which is what a missile hit; none when the box is clear.
type Sim.Met is Data:
  Met{before: List<&2, U32>, hit: Maybe<&2, U32>}

# What Doom's P_CheckPosition answers for a mobj's box: whether no thing
# stops it and no line does, and the floor and ceiling there. A thing in
# the way leaves the sector's under the point; otherwise each two-sided
# line the box crosses narrows them, up to the first line that stops the
# box.
type Sim.Fit is Data:
  Fit{ok: Bool, floor: U32, ceil: U32}

# A move that was tried: whether it was taken, the player after, and
# the things left by the pickups its position checks made, taken or
# not. Also the slide loop's state, done when a move along the wall was
# taken.
type Sim.Try is Data:
  Try{ok: Bool, player: Player, things: H.Things}

# The XY movement loop's state: done when no move is left, and the last
# move tried.
type Sim.Xy is Data:
  Xy{done: Bool, moved: Sim.Try, xmove: U32, ymove: U32}

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
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  x

def Player.y(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  y

def Player.angle(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  angle

def Player.momx(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  momx

def Player.z(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  z

def Player.floorz(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  floorz

def Player.ceilz(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  ceilz

def Player.crossed(+p: Player) -> List<&2, U32>:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  crossed

def Player.viewz(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  viewz

def Player.inv(+p: Player) -> I.Inventory:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  inv

def Player.psprites(+p: Player) -> Psprites:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  psprites

# The player holding an inventory.
def Player.holding(p: Player, held: I.Inventory) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, held, psprites}

# On the ground: at or below the floor.
def Player.onground(+p: Player) -> Bool:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  F.Fixed.le(z, floorz)

# The weapon
# ----------

# Doom's WEAPONBOTTOM, WEAPONTOP and RAISESPEED: the screen row a weapon
# starts to rise from, the row it rests at, and its rise a tic.
def Sim.weaponbottom() -> U32:
  8388608

def Sim.weapontop() -> U32:
  2097152

def Sim.raisespeed() -> U32:
  393216

# Doom's player->bob: the squared momentum over four, at most 16 units.
def Sim.bob(+momx: U32, +momy: U32) -> U32:
  F.Fixed.min(Sim.maxbob(), ((F.Fixed.mul(momx, momx) + F.Fixed.mul(momy, momy) : U32) >> 2n : U32))

# A sprite and the state it is to enter, if any.
type Sim.Entering is Data:
  Entering{state: Maybe<&2, U32>, psp: Psprite}

# Doom's A_Raise: the sprite rises, and at the top the weapon's ready
# state is set.
def Sim.raise(psp: Psprite, weapon: H.Thing.Weapon) -> Sim.Entering:
  Psprite{state, tics, sx, sy} = psp
  H.Weapon{up, ready} = weapon
  +risen = (sy - Sim.raisespeed() : U32)
  Entering{Bool.pick(Maybe<&2, U32>, F.Fixed.gt(risen, Sim.weapontop()), None{}, Some{ready}),
    Psprite{state, tics, sx, F.Fixed.max(risen, Sim.weapontop())}}

# Doom's A_WeaponReady's bob: the sprite swings on the level's clock, a
# turn every 64 tics, as far as the bob to either side of column 1 and
# below the top.
def Sim.ready(psp: Psprite, +sine: V.Vec, clock: U32, +bob: U32) -> Sim.Entering:
  Psprite{state, tics, sx, sy} = psp
  +angle = ((128 * clock : U32) .&. 8191 : U32)
  Entering{None{}, Psprite{state, tics, (65536 + F.Fixed.mul(bob, A.Angle.cos(sine, angle)) : U32),
    (Sim.weapontop() + F.Fixed.mul(bob, A.Angle.sin(sine, (angle .&. 4095 : U32))) : U32)}}

def Sim.psprite.act(action: H.Thing.Action, psp: Psprite, sine: V.Vec, clock: U32, bob: U32,
  weapon: H.Thing.Weapon) -> Sim.Entering:
  match action:
    case H.Null{}:
      Entering{None{}, psp}
    case H.Raise{}:
      Sim.raise(psp, weapon)
    case H.WeaponReady{}:
      Sim.ready(psp, sine, clock, bob)

# Doom's P_SetPsprite: the sprite enters the state for its tics and the
# state's action runs, and again for a state the action sets. No chain of
# vanilla's is longer than three.
def Sim.psprite.set(fuel: Nat, st: Sim.Entering, +sine: V.Vec, +clock: U32, +bob: U32, +weapon: H.Thing.Weapon) ->
  Psprite:
  match fuel st:
    case 1n+f Entering{Some{+state}, Psprite{was, tics, sx, sy}}:
      Sim.psprite.set(f, Sim.psprite.act(H.Thing.Row.action(H.Thing.row(state)),
        Psprite{Some{state}, H.Thing.Row.tics(H.Thing.row(state)), sx, sy}, sine, clock, bob, weapon),
        sine, clock, bob, weapon)
    case _ Entering{state, psp}:
      psp

# Doom's P_MovePsprites for one sprite: one that shows counts its tics
# down, and the tic they run out enters its next state. No weapon state
# lasts.
def Sim.psprite.tic(psp: Psprite, sine: V.Vec, clock: U32, bob: U32, weapon: H.Thing.Weapon) -> Psprite:
  match psp:
    case Psprite{None{}, tics, sx, sy}:
      Psprite{None{}, tics, sx, sy}
    case Psprite{Some{+state}, +tics, sx, sy}:
      Sim.psprite.set(4n, Entering{Bool.pick(Maybe<&2, U32>, U32.is_eq(tics, 1),
        Some{H.Thing.Row.next(H.Thing.row(state))}, None{}), Psprite{Some{state}, (tics - 1 : U32), sx, sy}},
        sine, clock, bob, weapon)

# The flash is drawn where the weapon is.
def Sim.psprites.follow(weapon: Psprite, flash: Psprite) -> Psprites:
  Psprite{state, tics, +sx, +sy} = weapon
  Psprite{fstate, ftics, fx, fy} = flash
  Psprites{Psprite{state, tics, sx, sy}, Psprite{fstate, ftics, sx, sy}}

# Doom's P_MovePsprites, with the bob P_CalcHeight works out from the
# momentum the move left.
def Sim.psprites(+level: L.Level, +clock: U32, p: Player) -> Player:
  Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv,
    Psprites{weapon, flash}} = p
  +sine = L.Level.sine(level)
  +bob = Sim.bob(momx, momy)
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv,
    Sim.psprites.follow(Sim.psprite.tic(weapon, sine, clock, bob, H.Thing.pistol()),
      Sim.psprite.tic(flash, sine, clock, bob, H.Thing.pistol()))}

# Doom's P_SetupPsprites and P_BringUpWeapon: no sprite shows, then the
# weapon enters its raise state at the bottom.
def Psprites.start(+sine: V.Vec, +weapon: H.Thing.Weapon) -> Psprites:
  H.Weapon{up, ready} = weapon
  Psprites{Sim.psprite.set(4n, Entering{Some{up}, Psprite{None{}, 0, 0, Sim.weaponbottom()}}, sine, 0, 0, weapon),
    Psprite{None{}, 0, 0, 0}}

def Player.at.fin(+x: U32, +y: U32, angle: U32, +floor: U32, ceil: U32, psprites: Psprites) -> Player:
  Player{x, y, floor, angle, 0, 0, 0, floor, ceil, Sim.viewheight(), 0,
    (floor + Sim.viewheight() : U32), [], I.Inventory.start(), psprites}

def Player.at(+level: L.Level, s: L.Level.Start) -> Player:
  L.Start{+x, +y, angle} = s
  +sector = L.Level.sector_at(level, x, y)
  Player.at.fin(x, y, angle, L.Level.floor(level, sector), L.Level.ceil(level, sector),
    Psprites.start(L.Level.sine(level), H.Thing.pistol()))

# The player at the level's start, on its floor, its eye at rest, with
# the inventory Doom's G_PlayerReborn gives and the pistol coming up.
def Player.start(+level: L.Level) -> Player:
  Player.at(level, L.Level.start_of(level))

# Lines and boxes
# ---------------

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

# Doom's P_BoxOnLineSide, answering whether the box of radius r at (x, y)
# straddles the line. The slope's sign is the sign of dy over dx, which
# FixedDiv keeps for any whole-unit line.
def Sim.box_crosses(+x: U32, +y: U32, +r: U32, +line: L.Level.Line) -> Bool:
  L.Line{+x1, +y1, +x2, +y2, flags, front, back} = line
  +dx = (x2 - x1 : U32)
  +dy = (y2 - y1 : U32)
  +top = (y + r : U32)
  +bottom = (y - r : U32)
  +left = (x - r : U32)
  +right = (x + r : U32)
  Bool.pick(Bool, U32.is_zero(dx),
    Bool.xor(F.Fixed.lt(right, x1), F.Fixed.lt(left, x1)),
    Bool.pick(Bool, U32.is_zero(dy),
      Bool.xor(F.Fixed.gt(top, y1), F.Fixed.gt(bottom, y1)),
      Bool.pick(Bool, Bool.xor(F.Fixed.is_neg(dx), F.Fixed.is_neg(dy)),
        Bool.xor(Sim.point_side(right, top, line), Sim.point_side(left, bottom, line)),
        Bool.xor(Sim.point_side(left, top, line), Sim.point_side(right, bottom, line)))))

# Whether the box of radius r at (x, y) overlaps the line's box.
def Sim.box_touches(+x: U32, +y: U32, +r: U32, +line: L.Level.Line) -> Bool:
  L.Line{+x1, +y1, +x2, +y2, flags, front, back} = line
  Bool.and(F.Fixed.gt((x + r : U32), F.Fixed.min(x1, x2)),
    Bool.and(F.Fixed.lt((x - r : U32), F.Fixed.max(x1, x2)),
      Bool.and(F.Fixed.gt((y + r : U32), F.Fixed.min(y1, y2)),
        F.Fixed.lt((y - r : U32), F.Fixed.max(y1, y2)))))

# A line a box crosses stops it when it is one-sided or has a flag of the
# mask: blocking, 1, stops everything; blocking monsters, 2, every thing
# but the player.
def Sim.solid(+mask: U32, +line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, +flags, front, +back} = line
  Bool.or(U32.is_eq(back, L.Level.none()), Bool.not(U32.is_zero((flags .&. mask : U32))))

# The distance condition: line i does not stop a box of radius r at
# (x, y) that the mask's lines stop.
def Sim.line_ok(+level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32, i: U32) -> Bool:
  +line = L.Level.line(level, i)
  Bool.not(Bool.and(Sim.box_touches(x, y, r, line),
    Bool.and(Sim.box_crosses(x, y, r, line), Sim.solid(mask, line))))

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
def Sim.fit.heights(+level: L.Level, +x: U32, +y: U32, +r: U32, +line: L.Level.Line, fit: Sim.Fit) ->
  Sim.Fit:
  L.Line{x1, y1, x2, y2, flags, front, +back} = line
  Sim.fit.narrow(Bool.and(Bool.not(U32.is_eq(back, L.Level.none())),
    Bool.and(Sim.box_touches(x, y, r, line), Sim.box_crosses(x, y, r, line))), level, line, fit)

def Sim.fit.cross(ok: Bool, +level: L.Level, +x: U32, +y: U32, +r: U32, +line: L.Level.Line, floor: U32,
  ceil: U32) -> Sim.Fit:
  match ok:
    case False{}:
      Fit{False{}, floor, ceil}
    case True{}:
      Sim.fit.heights(level, x, y, r, line, Fit{True{}, floor, ceil})

# Doom's PIT_CheckLine: a line that stops the box ends the check, the
# floor and ceiling as the lines before it left them; any other narrows
# them.
def Sim.fit.line(+level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32, +i: U32, fit: Sim.Fit) -> Sim.Fit:
  match fit:
    case Fit{False{}, floor, ceil}:
      Fit{False{}, floor, ceil}
    case Fit{True{}, floor, ceil}:
      Sim.fit.cross(Sim.line_ok(level, x, y, r, mask, i), level, x, y, r, L.Level.line(level, i), floor, ceil)

def Sim.fit.go(lines: List<&2, U32>, +level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32, fit: Sim.Fit) ->
  Sim.Fit:
  match lines:
    case []:
      fit
    case i <> rest:
      Sim.fit.go(rest, level, x, y, r, mask, Sim.fit.line(level, x, y, r, mask, i, fit))

# The blockmap
# ------------

def Sim.column(m: Nat, +bx: U32, +by: U32) -> List<&2, L.Level.Cell>:
  match m:
    case 0n:
      []
    case 1n+k:
      L.Cell{bx, by} <> Sim.column(k, bx, (by + 1 : U32))

# The cells of n columns of m, column by column from the west, each from
# the south: the order Doom walks a box's cells in.
def Sim.cells(n: Nat, +m: Nat, +bx: U32, +by: U32) -> List<&2, L.Level.Cell>:
  match n:
    case 0n:
      []
    case 1n+k:
      List.append(&2, L.Level.Cell, Sim.column(m, bx, by), Sim.cells(k, m, (bx + 1 : U32), by))

def Sim.box.of(lo: L.Level.Cell, hi: L.Level.Cell) -> List<&2, L.Level.Cell>:
  L.Cell{+xl, +yl} = lo
  L.Cell{xh, yh} = hi
  Sim.cells(U32.to_nat((xh - xl + 1 : U32)), U32.to_nat((yh - yl + 1 : U32)), xl, yl)

# The cells a box from (x0, y0) to (x1, y1) touches.
def Sim.box(+bm: L.Level.Blockmap, x0: U32, y0: U32, x1: U32, y1: U32) -> List<&2, L.Level.Cell>:
  Sim.box.of(L.Level.cell_of(bm, x0, y0), L.Level.cell_of(bm, x1, y1))

def Sim.lines.go(cells: List<&2, L.Level.Cell>, +geo: L.Level.Geo) -> List<&2, U32>:
  match cells:
    case []:
      []
    case c <> rest:
      List.append(&2, U32, L.Level.cell.lines(geo, c), Sim.lines.go(rest, geo))

# The lines of the cells a box touches, as one list (a line in two cells
# is listed twice, and line 0 in each).
def Sim.lines(+level: L.Level, x0: U32, y0: U32, x1: U32, y1: U32) -> List<&2, U32>:
  Sim.lines.go(Sim.box(L.Level.blockmap_of(level), x0, y0, x1, y1), L.Level.geo(level))

# Doom's MAXRADIUS, 32, the largest radius a thing has.
def Sim.maxradius() -> U32:
  2097152

# The mobjs linked in the cells of a box of radius r at (x, y) widened
# by the largest radius, in the blockmap's order: the ones Doom's
# P_CheckPosition looks at, since a mobj is linked by its centre alone.
def Sim.near(+level: L.Level, things: H.Things, +x: U32, +y: U32, +r: U32) -> List<&2, U32>:
  +reach = (r + Sim.maxradius() : U32)
  H.Things.linked(things, L.Level.blockmap_of(level), Sim.box(L.Level.blockmap_of(level), (x - reach : U32),
    (y - reach : U32), (x + reach : U32), (y + reach : U32)))

# Things
# ------

# The player's mobj, MT_PLAYER: solid, shootable, free to drop off
# ledges and to pick things up.
def Player.body(+p: Player, id: U32) -> Sim.Body:
  Body{id, Player.x(p), Player.y(p), Player.z(p), Sim.radius(), Sim.height(), 33557510}

def Sim.body.def(d: H.Thing.Def, id: U32, x: U32, y: U32, z: U32) -> Sim.Body:
  H.Def{kind, state, radius, height, flags} = d
  Body{id, x, y, z, F.Fixed.of_map(radius), F.Fixed.of_map(height), flags}

def Sim.body.of(th: H.Thing) -> Sim.Body:
  H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics} = th
  Sim.body.def(H.Thing.info(kind), id, x, y, z)

# The mobj with its centre at another place.
def Sim.Body.at(m: Sim.Body, x: U32, y: U32) -> Sim.Body:
  Body{id, ox, oy, z, radius, height, flags} = m
  Body{id, x, y, z, radius, height, flags}

# The mobj an id names: the player's, a thing alive, or none.
def Sim.body(+things: H.Things, +p: Player, +id: U32) -> Maybe<&2, Sim.Body>:
  Bool.pick(Maybe<&2, Sim.Body>, U32.is_eq(id, H.Things.you(things)), Some{Player.body(p, id)},
    Maybe.map(&2, H.Thing, Sim.Body, Sim.body.of, H.Things.get(things, id)))

# Doom's PIT_CheckThing's first test: boxes of radius q at (tx, ty) and
# r at (x, y) meet when their centres are nearer than the two radii
# along both axes.
def Sim.overlap(+q: U32, +tx: U32, +ty: U32, +x: U32, +y: U32, +r: U32) -> Bool:
  +reach = (q + r : U32)
  Bool.and(F.Fixed.lt(F.Fixed.abs((tx - x : U32)), reach), F.Fixed.lt(F.Fixed.abs((ty - y : U32)), reach))

# Doom's PIT_CheckThing's verdict on a mobj in the way of one moved:
# it stops the box when it is another mobj and their boxes overlap, if
# it is solid; a missile, flag 65536, passes over and under it, and is
# stopped by a shootable one too, which it has then hit.
def Sim.stops(m: Sim.Body, t: Sim.Body) -> Bool:
  Body{mi, +mx, +my, +mz, mr, mh, mf} = m
  Body{ti, tx, ty, +tz, tr, th, +tf} = t
  Bool.and(Sim.overlap(tr, tx, ty, mx, my, mr), Bool.and(Bool.not(U32.is_eq(ti, mi)),
    Bool.pick(Bool, U32.is_zero((mf .&. 65536 : U32)), Bool.not(U32.is_zero((tf .&. 2 : U32))),
      Bool.and(Bool.not(U32.is_zero((tf .&. 6 : U32))),
        Bool.not(Bool.or(F.Fixed.gt(mz, (tz + th : U32)), F.Fixed.lt((mz + mh : U32), tz)))))))

def Sim.stops.some(m: Sim.Body, t: Maybe<&2, Sim.Body>) -> Bool:
  match t:
    case None{}:
      False{}
    case Some{b}:
      Sim.stops(m, b)

# Whether the mobj an id names stops a mobj's box.
def Sim.stops.at(things: H.Things, p: Player, m: Sim.Body, id: U32) -> Bool:
  Sim.stops.some(m, Sim.body(things, p, id))

def Sim.met.if(stops: Bool, id: U32, later: Sim.Met) -> Sim.Met:
  match stops:
    case True{}:
      Met{[], Some{id}}
    case False{}:
      Met{before, hit} = later
      Met{id <> before, hit}

def Sim.met.go(ids: List<&2, U32>, +things: H.Things, +p: Player, +m: Sim.Body) -> Sim.Met:
  match ids:
    case []:
      Met{[], None{}}
    case +id <> rest:
      Sim.met.if(Sim.stops.at(things, p, m, id), id, Sim.met.go(rest, things, p, m))

# The mobjs near a mobj's box.
def Sim.nearby(+level: L.Level, things: H.Things, m: Sim.Body) -> List<&2, U32>:
  Body{id, x, y, z, radius, height, flags} = m
  Sim.near(level, things, x, y, radius)

# The thing half of Doom's P_CheckPosition for a mobj's box.
def Sim.met(+level: L.Level, +things: H.Things, p: Player, +m: Sim.Body) -> Sim.Met:
  Sim.met.go(Sim.nearby(level, things, m), things, p, m)

def Sim.Met.hit(t: Sim.Met) -> Maybe<&2, U32>:
  Met{before, hit} = t
  hit

# The mobj that stops a mobj's box, none when it is clear.
def Sim.blocked(+level: L.Level, +things: H.Things, p: Player, +m: Sim.Body) -> Maybe<&2, U32>:
  Sim.Met.hit(Sim.met(level, things, p, m))

# The floor and ceiling of the sector under a point.
def Sim.fit.start(ok: Bool, +level: L.Level, +x: U32, +y: U32) -> Sim.Fit:
  +sector = L.Level.sector_at(level, x, y)
  Fit{ok, L.Level.floor(level, sector), L.Level.ceil(level, sector)}

# The line half of Doom's P_CheckPosition for a box of radius r at
# (x, y), stopped by the mask's lines, after its things gave their
# verdict: a thing in the way ends it at the floor and ceiling of the
# sector under the point; otherwise the lines the box crosses narrow
# them, until one stops it.
def Sim.fit.at(clear: Bool, +level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32) -> Sim.Fit:
  match clear:
    case False{}:
      Sim.fit.start(False{}, level, x, y)
    case True{}:
      Sim.fit.go(Sim.lines(level, (x - r : U32), (y - r : U32), (x + r : U32), (y + r : U32)), level, x, y, r, mask,
        Sim.fit.start(True{}, level, x, y))

# The line half, after what the thing half met.
def Sim.check.met(met: Sim.Met, +level: L.Level, m: Sim.Body, mask: U32) -> Sim.Fit:
  Body{id, x, y, z, radius, height, flags} = m
  Sim.fit.at(Maybe.is_none(&2, U32, Sim.Met.hit(met)), level, x, y, radius, mask)

# Doom's P_CheckPosition for any mobj where its body stands, among the
# things and the player, stopped by the mask's lines: 1 for the player,
# 3 for a thing, which lines blocking monsters stop as well.
def Sim.check(+level: L.Level, things: H.Things, p: Player, +m: Sim.Body, mask: U32) -> Sim.Fit:
  Sim.check.met(Sim.met(level, things, p, m), level, m, mask)

def Sim.Fit.ok(f: Sim.Fit) -> Bool:
  Fit{ok, floor, ceil} = f
  ok

# Free: no solid line in the cells the player's box touches crosses the
# box. What every move the sim takes has passed.
def Sim.free(+level: L.Level, x: U32, y: U32) -> Bool:
  Sim.Fit.ok(Sim.fit.at(True{}, level, x, y, Sim.radius(), 1))

# Doom's P_TryMove's rule for a checked place: the opening fits the
# mobj, the ceiling is high enough from its feet, and the floor is at
# most 24 units up.
def Sim.passes(f: Sim.Fit, +z: U32, +height: U32) -> Bool:
  Fit{ok, +floor, +ceil} = f
  Bool.and(ok, Bool.and(F.Fixed.ge((ceil - floor : U32), height),
    Bool.and(F.Fixed.ge((ceil - z : U32), height), F.Fixed.le((floor - z : U32), Sim.step_up()))))

# Pickups
# -------

# The end of P_TouchSpecialThing: a thing taken is removed, and then
# heard from nobody.
def Sim.touch.took(granted: Maybe<&2, I.Inventory>, counted: Bool, inv: I.Inventory, kind: U32,
  bm: L.Level.Blockmap, th: H.Thing, things: H.Things) -> I.Inventory & H.Things:
  match granted:
    case None{}:
      (inv, things)
    case Some{got}:
      (I.Inventory.took(counted, got), H.Things.sounded(H.Things.removed(things, bm, th),
        Sn.Sound.plain(I.Inventory.sound(kind), Sn.Nobody{})))

def Sim.touch.offer(reached: Bool, +kind: U32, counted: Bool, +inv: I.Inventory, bm: L.Level.Blockmap, th: H.Thing,
  things: H.Things) -> I.Inventory & H.Things:
  match reached:
    case False{}:
      (inv, things)
    case True{}:
      Sim.touch.took(I.Inventory.grant(kind, inv), counted, inv, kind, bm, th, things)

# Doom's PIT_CheckThing and P_TouchSpecialThing for the player's box at
# (x, y) with its feet at z: a special thing the box overlaps, its
# bottom at most 8 under the feet and at most the player's height over
# them, is offered to the inventory.
def Sim.touch.def(d: H.Thing.Def, +th: H.Thing, +x: U32, +y: U32, +z: U32, inv: I.Inventory, bm: L.Level.Blockmap,
  things: H.Things) -> I.Inventory & H.Things:
  H.Def{+kind, state, radius, height, +flags} = d
  H.Thing{id, k, +tx, +ty, tz, floorz, ceilz, angle, sector, st, tics} = th
  +dz = (tz - z : U32)
  Sim.touch.offer(Bool.and(Bool.not(U32.is_zero((flags .&. 1 : U32))),
      Bool.and(Sim.overlap(F.Fixed.of_map(radius), tx, ty, x, y, Sim.radius()),
        Bool.and(F.Fixed.le(dz, Sim.height()), F.Fixed.ge(dz, 4294443008)))), kind,
    Bool.not(U32.is_zero((flags .&. 8388608 : U32))), inv, bm, th, things)

# The player's own id names no thing.
def Sim.touch.thing(m: Maybe<&2, H.Thing>, +x: U32, +y: U32, +z: U32, inv: I.Inventory, bm: L.Level.Blockmap,
  things: H.Things) -> I.Inventory & H.Things:
  match m:
    case None{}:
      (inv, things)
    case Some{H.Thing{id, +kind, tx, ty, tz, floorz, ceilz, angle, sector, state, tics}}:
      Sim.touch.def(H.Thing.info(kind), H.Thing{id, kind, tx, ty, tz, floorz, ceilz, angle, sector, state, tics}, x, y,
        z, inv, bm, things)

def Sim.touch.one(+id: U32, +x: U32, +y: U32, +z: U32, +bm: L.Level.Blockmap, got: I.Inventory & H.Things) ->
  I.Inventory & H.Things:
  (inv, +things) = got
  Sim.touch.thing(H.Things.get(things, id), x, y, z, inv, bm, things)

def Sim.touch.go(ids: List<&2, U32>, +x: U32, +y: U32, +z: U32, +bm: L.Level.Blockmap,
  got: I.Inventory & H.Things) -> I.Inventory & H.Things:
  match ids:
    case []:
      got
    case id <> rest:
      Sim.touch.go(rest, x, y, z, bm, Sim.touch.one(id, x, y, z, bm, got))

# The pickups of the player's position check with its box at (x, y):
# each special thing met before the one that stops the box is offered to
# the inventory, in the blockmap's order; one the grant takes is removed,
# and the things kept keep their ids.
def Sim.touch(+level: L.Level, things: H.Things, +p: Player, x: U32, y: U32, met: Sim.Met) ->
  I.Inventory & H.Things:
  Met{before, hit} = met
  Sim.touch.go(before, x, y, Player.z(p), L.Level.blockmap_of(level), (Player.inv(p), things))

# Moving
# ------

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
    Bool.and(Bool.not(Sim.solid(1, line)), Bool.and(Sim.box_touches(x, y, Sim.radius(), line),
      Bool.and(Sim.box_crosses(x, y, Sim.radius(), line),
        Bool.xor(Sim.point_side(ox, oy, line), Sim.point_side(x, y, line))))))

# The lines a move crosses, the last gathered first, as Doom fires them,
# a line the blockmap lists twice taken once.
def Sim.crossings.go(lines: List<&2, U32>, +level: L.Level, +ox: U32, +oy: U32, +x: U32, +y: U32,
  +found: List<&2, U32>) -> List<&2, U32>:
  match lines:
    case []:
      found
    case +i <> rest:
      Sim.crossings.go(rest, level, ox, oy, x, y, V.Vec.keep(~U32, Bool.and(Sim.crosses(level, ox, oy, x, y, i),
        Bool.not(Sim.member(found, i))), i, found))

def Sim.crossings(+level: L.Level, ox: U32, oy: U32, +x: U32, +y: U32) -> List<&2, U32>:
  Sim.crossings.go(Sim.lines(level, (x - Sim.radius() : U32), (y - Sim.radius() : U32),
    (x + Sim.radius() : U32), (y + Sim.radius() : U32)), level, ox, oy, x, y, [])

# The player's mobj unlinked from one place and linked at another, as
# Doom's P_TryMove does about a move.
def Sim.relink(+level: L.Level, +things: H.Things, +ox: U32, +oy: U32, +x: U32, +y: U32) -> H.Things:
  H.Things.link(H.Things.unlink(things, L.Level.blockmap_of(level), H.Things.you(things), ox, oy,
    L.Level.sector_at(level, ox, oy)), L.Level.blockmap_of(level), H.Things.you(things), x, y,
    L.Level.sector_at(level, x, y))

def Sim.try_move.fin(go: Bool, +level: L.Level, p: Player, things: H.Things, +x: U32, +y: U32, floor: U32,
  ceil: U32, over: List<&2, U32>) -> Sim.Try:
  match go:
    case False{}:
      Try{False{}, p, things}
    case True{}:
      Player{ox, oy, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
      Try{True{}, Player{x, y, z, angle, momx, momy, momz, floor, ceil, viewheight, deltaview, viewz,
        List.append(&2, U32, crossed, over), inv, psprites}, Sim.relink(level, things, ox, oy, x, y)}

# The move is taken when the place passes; the player's mobj then goes
# first in its cell and its sector. What the check picked up stays picked
# up either way.
def Sim.try_move.fit(+level: L.Level, +p: Player, x: U32, y: U32, touched: I.Inventory & H.Things, +f: Sim.Fit,
  over: List<&2, U32>) -> Sim.Try:
  (inv, things) = touched
  Fit{ok, floor, ceil} = f
  Sim.try_move.fin(Sim.passes(f, Player.z(p), Sim.height()), level, Player.holding(p, inv), things, x, y, floor,
    ceil, over)

# The player's position check at a place, P_CheckPosition once: what
# its box met gives its pickups and its verdict.
def Sim.try_move.met(+level: L.Level, things: H.Things, +p: Player, +m: Sim.Body, +met: Sim.Met,
  over: List<&2, U32>) -> Sim.Try:
  Body{id, +x, +y, z, radius, height, flags} = m
  Sim.try_move.fit(level, p, x, y, Sim.touch(level, things, p, x, y, met), Sim.check.met(met, level, m, 1), over)

# Doom's P_TryMove: P_CheckPosition touches the things and checks the
# place; a move taken adds the special lines it crossed to the player's.
def Sim.try_move(+level: L.Level, +things: H.Things, +p: Player, +x: U32, +y: U32) -> Sim.Try:
  Sim.try_move.met(level, things, p, Sim.Body.at(Player.body(p, H.Things.you(things)), x, y),
    Sim.met(level, things, p, Sim.Body.at(Player.body(p, H.Things.you(things)), x, y)),
    Sim.crossings(level, Player.x(p), Player.y(p), x, y))

def Sim.Try.ok(t: Sim.Try) -> Bool:
  Try{ok, p, things} = t
  ok

def Sim.Try.player(t: Sim.Try) -> Player:
  Try{ok, p, things} = t
  p

# A try that ends the slide, taken or not.
def Sim.Try.done(t: Sim.Try) -> Sim.Try:
  Try{ok, p, things} = t
  Try{True{}, p, things}

# A try passed whatever it found.
def Sim.Try.or(b: Bool, t: Sim.Try) -> Sim.Try:
  Try{ok, p, things} = t
  Try{Bool.or(b, ok), p, things}

# The path traversal
# ------------------

# Doom's P_PointOnDivlineSide: the cross product with the sign-bit
# shortcut, one factor shifted by eight as the original shifts it.
def Sim.div_side.slow(+x: U32, +y: U32, +dx: U32, +dy: U32) -> Bool:
  Bool.pick(Bool, U32.is_zero(((dy .^. dx .^. x .^. y) .&. 2147483648 : U32)),
    Bool.not(F.Fixed.lt(F.Fixed.mul(y, F.Fixed.sarn(dx, 8n)), F.Fixed.mul(F.Fixed.sarn(dy, 8n), x))),
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

# Doom's P_InterceptVector: how far along the trace it meets the line
# from (x, y) along (dx, dy).
def Sim.intercept.div(+num: U32, +den: U32) -> U32:
  Bool.pick(U32, U32.is_zero(den), 0, F.Fixed.div(num, den))

def Sim.intercept.at(+tx: U32, +ty: U32, +tdx: U32, +tdy: U32, +x: U32, +y: U32, +dx: U32, +dy: U32) -> U32:
  Sim.intercept.div(
    (F.Fixed.mul(F.Fixed.sarn((x - tx : U32), 8n), dy)
      + F.Fixed.mul(F.Fixed.sarn((ty - y : U32), 8n), dx) : U32),
    (F.Fixed.mul(F.Fixed.sarn(dy, 8n), tdx) - F.Fixed.mul(F.Fixed.sarn(dx, 8n), tdy) : U32))

def Sim.intercept.frac(+tx: U32, +ty: U32, +tdx: U32, +tdy: U32, +line: L.Level.Line) -> U32:
  L.Line{+x1, +y1, +x2, +y2, flags, front, back} = line
  Sim.intercept.at(tx, ty, tdx, tdy, x1, y1, (x2 - x1 : U32), (y2 - y1 : U32))

# The fraction where the trace meets the line, or past one when it
# does not (Doom's INT_MAX for an intercept out of range).
def Sim.intercept(+tx: U32, +ty: U32, +tdx: U32, +tdy: U32, +line: L.Level.Line) -> U32:
  Bool.pick(U32, Sim.crossed(tx, ty, tdx, tdy, line),
    Sim.intercept.frac(tx, ty, tdx, tdy, line), 2147483647)

# The fraction where the trace meets the segment from (x, y) along
# (dx, dy), which is a thing's crossing diagonal, or past one when the
# segment's ends lie on one side of the trace.
def Sim.intercept.cross(+tx: U32, +ty: U32, +tdx: U32, +tdy: U32, +x: U32, +y: U32, +dx: U32, +dy: U32) -> U32:
  Bool.pick(U32, Bool.xor(Sim.div_side(x, y, tx, ty, tdx, tdy),
      Sim.div_side((x + dx : U32), (y + dy : U32), tx, ty, tdx, tdy)),
    Sim.intercept.at(tx, ty, tdx, tdy, x, y, dx, dy), 2147483647)

# The diagonal of the thing's box that a trace of this slope can cross:
# the one from the top left corner down when the trace rises, the one
# from the bottom left corner up otherwise.
def Sim.intercept.box(rising: Bool, +tx: U32, +ty: U32, +tdx: U32, +tdy: U32, +x: U32, +y: U32, +r: U32) -> U32:
  match rising:
    case True{}:
      Sim.intercept.cross(tx, ty, tdx, tdy, (x - r : U32), (y + r : U32), (r + r : U32), (0 - r - r : U32))
    case False{}:
      Sim.intercept.cross(tx, ty, tdx, tdy, (x - r : U32), (y - r : U32), (r + r : U32), (r + r : U32))

# Doom's PIT_AddThingIntercepts: a mobj is met where the trace crosses
# its corner to corner diagonal. One the population no longer has is met
# nowhere.
def Sim.intercept.thing(m: Maybe<&2, Sim.Body>, +tx: U32, +ty: U32, +tdx: U32, +tdy: U32) -> U32:
  match m:
    case None{}:
      4294967295
    case Some{Body{id, +x, +y, z, +radius, height, flags}}:
      Sim.intercept.box(F.Fixed.gt((tdx .^. tdy : U32), 0), tx, ty, tdx, tdy, x, y, radius)

# Doom's intercept_t: how far along the trace the meeting is, whether a
# line was met, and the name of the line or of the thing.
type Sim.Meet is Data:
  Meet{frac: U32, isline: Bool, what: U32}

def Sim.Meet.frac(m: Sim.Meet) -> U32:
  Meet{frac, isline, what} = m
  frac

# Doom's validcount over the lines of a cell: a line an earlier cell
# listed, or this cell listed already, is passed over.
def Sim.meets.fresh(ids: List<&2, U32>, +seen: List<&2, U32>) -> List<&2, U32>:
  match ids:
    case []:
      []
    case +i <> rest:
      V.Vec.keep(~U32, Bool.not(Sim.member(seen, i)), i, Sim.meets.fresh(rest, i <> seen))

# The lines a cell holds for a walk that asks for them: Doom's
# PT_ADDLINES.
def Sim.meets.ids(add: Bool, geo: L.Level.Geo, c: L.Level.Cell) -> List<&2, U32>:
  match add:
    case False{}:
      []
    case True{}:
      L.Level.cell.lines(geo, c)

# The mobjs a cell links for a walk that asks for them: Doom's
# PT_ADDTHINGS.
def Sim.meets.linked(add: Bool, ts: H.Things, bm: L.Level.Blockmap, c: L.Level.Cell) -> List<&2, U32>:
  match add:
    case False{}:
      []
    case True{}:
      H.Things.linked(ts, bm, [c])

# Doom's PIT_AddLineIntercepts: a line the trace crosses within its
# length is met, at the fraction P_InterceptVector gives; one behind the
# source or past the end is left out, as the traversal would pass over
# it.
def Sim.meets.lines(ids: List<&2, U32>, +level: L.Level, +tx: U32, +ty: U32, +tdx: U32, +tdy: U32) ->
  List<&2, Sim.Meet>:
  match ids:
    case []:
      []
    case +i <> rest:
      +frac = Sim.intercept(tx, ty, tdx, tdy, L.Level.line(level, i))
      V.Vec.keep(~Sim.Meet, U32.is_le(frac, F.Fixed.unit()), Meet{frac, True{}, i},
        Sim.meets.lines(rest, level, tx, ty, tdx, tdy))

def Sim.meets.things(ids: List<&2, U32>, +ts: H.Things, +p: Player, +tx: U32, +ty: U32, +tdx: U32,
  +tdy: U32) -> List<&2, Sim.Meet>:
  match ids:
    case []:
      []
    case +id <> rest:
      +frac = Sim.intercept.thing(Sim.body(ts, p, id), tx, ty, tdx, tdy)
      V.Vec.keep(~Sim.Meet, U32.is_le(frac, F.Fixed.unit()), Meet{frac, False{}, id},
        Sim.meets.things(rest, ts, p, tx, ty, tdx, tdy))

# A trace that starts on a cell's edge is nudged off it, as Doom's.
def Sim.nudge(+v: U32, +org: U32) -> U32:
  Bool.pick(U32, U32.is_zero(((v - org : U32) .&. 8388607 : U32)), (v + F.Fixed.unit() : U32), v)

# P_PathTraverse's setup along one axis: the step from cell to cell, how
# much of the first cell is left to cross, and how far the other axis
# gains a cell.
type Sim.Axis is Data:
  Axis{step: U32, partial: U32, gain: U32}

def Sim.ray.axis(ahead: Bool, back: Bool, v: U32, dv: U32, dw: U32) -> Sim.Axis:
  match ahead back:
    case True{} _:
      Axis{1, (F.Fixed.unit() - (F.Fixed.sarn(v, 7n) .&. 65535 : U32) : U32), F.Fixed.div(dw, F.Fixed.abs(dv))}
    case False{} True{}:
      Axis{4294967295, (F.Fixed.sarn(v, 7n) .&. 65535 : U32), F.Fixed.div(dw, F.Fixed.abs(dv))}
    case False{} False{}:
      Axis{0, F.Fixed.unit(), 16777216}

# The walk's place: the cell it stands in, the two intercepts it steps
# by, and whether the cell is the last.
type Sim.Ray is Data:
  Ray{done: Bool, mapx: U32, mapy: U32, xi: U32, yi: U32}

def Sim.ray.of(xt2: U32, yt2: U32, +mapx: U32, +mapy: U32, xi: U32, yi: U32) -> Sim.Ray:
  Ray{Bool.and(U32.is_eq(mapx, xt2), U32.is_eq(mapy, yt2)), mapx, mapy, xi, yi}

# The next cell: the axis whose intercept still falls in this cell
# advances, y before x; when neither does the walk stands still, as
# Doom's does, until its count runs out.
def Sim.ray.step(ymet: Bool, xmet: Bool, xt2: U32, yt2: U32, xstep: U32, ystep: U32, mapxstep: U32,
  mapystep: U32, mapx: U32, mapy: U32, xi: U32, yi: U32) -> Sim.Ray:
  match ymet xmet:
    case True{} _:
      Sim.ray.of(xt2, yt2, (mapx + mapxstep : U32), mapy, xi, (yi + ystep : U32))
    case False{} True{}:
      Sim.ray.of(xt2, yt2, mapx, (mapy + mapystep : U32), (xi + xstep : U32), yi)
    case False{} False{}:
      Sim.ray.of(xt2, yt2, mapx, mapy, xi, yi)

def Sim.ray.go(fuel: Nat, r: Sim.Ray, +xt2: U32, +yt2: U32, +xstep: U32, +ystep: U32, +mapxstep: U32,
  +mapystep: U32) -> List<&2, L.Level.Cell>:
  match fuel r:
    case 0n _:
      []
    case 1n+k Ray{True{}, mapx, mapy, xi, yi}:
      [L.Cell{mapx, mapy}]
    case 1n+k Ray{False{}, +mapx, +mapy, +xi, +yi}:
      L.Cell{mapx, mapy} <> Sim.ray.go(k, Sim.ray.step(U32.is_eq(F.Fixed.sarn(yi, 16n), mapy),
        U32.is_eq(F.Fixed.sarn(xi, 16n), mapx), xt2, yt2, xstep, ystep, mapxstep, mapystep, mapx, mapy, xi, yi),
        xt2, yt2, xstep, ystep, mapxstep, mapystep)

def Sim.ray.walk(ax: Sim.Axis, ay: Sim.Axis, rx: U32, ry: U32, xt1: U32, yt1: U32, +xt2: U32, +yt2: U32) ->
  List<&2, L.Level.Cell>:
  Axis{mapxstep, partialx, +ystep} = ax
  Axis{mapystep, partialy, +xstep} = ay
  Sim.ray.go(64n, Sim.ray.of(xt2, yt2, xt1, yt1, (F.Fixed.sarn(rx, 7n) + F.Fixed.mul(partialy, xstep) : U32),
    (F.Fixed.sarn(ry, 7n) + F.Fixed.mul(partialx, ystep) : U32)), xt2, yt2, xstep, ystep, mapxstep, mapystep)

# P_PathTraverse's walk: the cells the trace crosses, the one it starts
# in first, at most 64, ending with the one it ends in. Doom's count
# stops a trace whose stepping never reaches that cell.
def Sim.ray(+ox: U32, +oy: U32, +tx: U32, +ty: U32, +x2: U32, +y2: U32) -> List<&2, L.Level.Cell>:
  +rx = (tx - ox : U32)
  +ry = (ty - oy : U32)
  +dx = (x2 - tx : U32)
  +dy = (y2 - ty : U32)
  +xt1 = F.Fixed.sarn(rx, 23n)
  +yt1 = F.Fixed.sarn(ry, 23n)
  +xt2 = F.Fixed.sarn((x2 - ox : U32), 23n)
  +yt2 = F.Fixed.sarn((y2 - oy : U32), 23n)
  Sim.ray.walk(Sim.ray.axis(F.Fixed.gt(xt2, xt1), F.Fixed.lt(xt2, xt1), rx, dx, dy),
    Sim.ray.axis(F.Fixed.gt(yt2, yt1), F.Fixed.lt(yt2, yt1), ry, dy, dx), rx, ry, xt1, yt1, xt2, yt2)

# The meetings of one walk, cell by cell: the lines of a cell, then the
# things linked in it, as Doom's iterators run.
def Sim.meets.go(cells: List<&2, L.Level.Cell>, +seen: List<&2, U32>, +lines: Bool, +things: Bool,
  +level: L.Level, +ts: H.Things, +p: Player, +tx: U32, +ty: U32, +tdx: U32, +tdy: U32) ->
  List<&2, Sim.Meet>:
  match cells:
    case []:
      []
    case +c <> rest:
      +ids = Sim.meets.ids(lines, L.Level.geo(level), c)
      List.append(&2, Sim.Meet, List.append(&2, Sim.Meet,
        Sim.meets.lines(Sim.meets.fresh(ids, seen), level, tx, ty, tdx, tdy),
        Sim.meets.things(Sim.meets.linked(things, ts, L.Level.blockmap_of(level), c), ts, p, tx, ty, tdx, tdy)),
        Sim.meets.go(rest, List.append(&2, U32, ids, seen), lines, things, level, ts, p, tx, ty, tdx, tdy))

# Whether a meeting goes before a sorted list's head: nearer than it, or
# the list empty.
def Sim.meets.before(+m: Sim.Meet, sorted: List<&2, Sim.Meet>) -> Bool:
  match sorted:
    case []:
      True{}
    case h <> rest:
      U32.is_lt(Sim.Meet.frac(m), Sim.Meet.frac(h))

# A meeting into a list sorted by fraction, after its equals, so the
# first gathered of equals stays first, as Doom's repeated minimum picks
# them.
def Sim.meets.insert(sorted: List<&2, Sim.Meet>, before: Bool, +m: Sim.Meet) -> List<&2, Sim.Meet>:
  match sorted before:
    case _ True{}:
      m <> sorted
    case [] False{}:
      [m]
    case h <> +rest False{}:
      h <> Sim.meets.insert(rest, Sim.meets.before(m, rest), m)

def Sim.meets.sort(meets: List<&2, Sim.Meet>, +sorted: List<&2, Sim.Meet>) -> List<&2, Sim.Meet>:
  match meets:
    case []:
      sorted
    case +m <> rest:
      Sim.meets.sort(rest, Sim.meets.insert(sorted, Sim.meets.before(m, sorted), m))

def Sim.meets.at(+bm: L.Level.Blockmap, +level: L.Level, ts: H.Things, p: Player, lines: Bool, things: Bool,
  +x1: U32, +y1: U32, +x2: U32, +y2: U32) -> List<&2, Sim.Meet>:
  L.Blockmap{words, +ox, +oy, cols, rows} = bm
  +tx = Sim.nudge(x1, ox)
  +ty = Sim.nudge(y1, oy)
  Sim.meets.sort(Sim.meets.go(Sim.ray(ox, oy, tx, ty, x2, y2), [], lines, things, level, ts, p, tx, ty,
    (x2 - tx : U32), (y2 - ty : U32)), [])

# Doom's P_PathTraverse intercepts: what the trace meets in the cells it
# crosses, gathered in the walk's order and sorted by distance. The
# mobjs come from the population, where a move, a spawn and a removal
# write their links.
def Sim.meets(+level: L.Level, ts: H.Things, p: Player, lines: Bool, things: Bool, x1: U32, y1: U32, x2: U32,
  y2: U32) -> List<&2, Sim.Meet>:
  Sim.meets.at(L.Level.blockmap_of(level), level, ts, p, lines, things, x1, y1, x2, y2)

# What a visitor answers: whether the walk stops here, and what it goes
# on carrying. Doom's traverser returns the flag and writes the rest to
# its globals.
type Sim.Answer<a, -A: Kind(a)> is Kind(a):
  Answer{stop: Bool, carry: A}

# Doom's P_TraverseIntercepts: each meeting in turn, the nearest first,
# until the visitor refuses.
def Sim.walk(~A: Data, ~visit: @+level: L.Level -> @m: Sim.Meet -> @c: A -> Sim.Answer<&2, A>,
  ms: List<&2, Sim.Meet>, +level: L.Level, st: Sim.Answer<&2, A>) -> A:
  match ms st:
    case [] Answer{stop, carry}:
      carry
    case _ Answer{True{}, carry}:
      carry
    case m <> rest Answer{False{}, carry}:
      Sim.walk(~A, ~visit, rest, level, visit(level, m, carry))

# Doom's P_PathTraverse: the visitor sees what the ray from (x1, y1) to
# (x2, y2) meets, the nearest first, and ends the walk when it refuses.
def Sim.path(~A: Data, ~visit: @+level: L.Level -> @m: Sim.Meet -> @c: A -> Sim.Answer<&2, A>,
  +level: L.Level, ts: H.Things, p: Player, lines: Bool, things: Bool, x1: U32, y1: U32, x2: U32, y2: U32,
  start: A) -> A:
  Sim.walk(~A, ~visit, Sim.meets(level, ts, p, lines, things, x1, y1, x2, y2), level, Answer{False{}, start})

# Sliding
# -------

# Doom's PTR_SlideTraverse: whether the line stops the slide. A line
# flagged two-sided with no back sector has no opening and blocks.
def Sim.blocks.open(+level: L.Level, +z: U32, +line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, flags, front, +back} = line
  +top = Sim.open_top(level, line)
  +bottom = Sim.open_bottom(level, line)
  Bool.or(U32.is_eq(back, L.Level.none()),
    Bool.or(F.Fixed.lt((top - bottom : U32), Sim.height()),
      Bool.or(F.Fixed.lt((top - z : U32), Sim.height()),
        F.Fixed.gt((bottom - z : U32), Sim.step_up()))))

def Sim.blocks(+level: L.Level, x: U32, y: U32, z: U32, +line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, +flags, front, back} = line
  Bool.pick(Bool, U32.is_zero((flags .&. 4 : U32)),
    Bool.not(Sim.point_side(x, y, line)),
    Sim.blocks.open(level, z, line))

# What PTR_SlideTraverse works from: the sliding player's place, and the
# closest blocking line met so far with its fraction; none is one past a
# whole move.
type Sim.Slide is Data:
  Slide{x: U32, y: U32, z: U32, frac: U32, line: U32}

def Sim.hit.better(closer: Bool, frac: U32, i: U32, s: Sim.Slide) -> Sim.Slide:
  match closer:
    case False{}:
      s
    case True{}:
      Slide{x, y, z, bf, bi} = s
      Slide{x, y, z, frac, i}

def Sim.hit.blocked(blocked: Bool, +frac: U32, i: U32, s: Sim.Slide) -> Sim.Slide:
  match blocked:
    case False{}:
      s
    case True{}:
      Slide{x, y, z, +bf, bi} = s
      Sim.hit.better(U32.is_lt(frac, bf), frac, i, Slide{x, y, z, bf, bi})

def Sim.slide.stop(+blocked: Bool, +frac: U32, i: U32, s: Sim.Slide) -> Sim.Answer<&2, Sim.Slide>:
  Answer{blocked, Sim.hit.blocked(blocked, frac, i, s)}

# The slide's visitor: a line that blocks ends the walk, and is the
# slide's when it is closer than any line an earlier corner's trace met.
def Sim.slide.visit(+level: L.Level, m: Sim.Meet, s: Sim.Slide) -> Sim.Answer<&2, Sim.Slide>:
  Meet{+frac, isline, +i} = m
  Slide{+x, +y, +z, bf, bl} = s
  Sim.slide.stop(Sim.blocks(level, x, y, z, L.Level.line(level, i)), frac, i, Slide{x, y, z, bf, bl})

def Sim.slide.from(+p: Player, best: U32 & U32) -> Sim.Slide:
  (frac, line) = best
  Slide{Player.x(p), Player.y(p), Player.z(p), frac, line}

def Sim.slide.best(s: Sim.Slide) -> U32 & U32:
  Slide{x, y, z, frac, line} = s
  (frac, line)

# Doom's P_PathTraverse with PTR_SlideTraverse over one corner's trace:
# the closest line it meets that blocks, against the best so far.
def Sim.trace(+level: L.Level, ts: H.Things, +p: Player, x1: U32, y1: U32, x2: U32, y2: U32,
  best: U32 & U32) -> U32 & U32:
  Sim.slide.best(Sim.path(~Sim.Slide, ~Sim.slide.visit, level, ts, p, True{}, False{}, x1, y1, x2, y2,
    Sim.slide.from(p, best)))

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
  +newlen = F.Fixed.mul(F.Fixed.approx(mx, my), A.Angle.cos(sine, A.Angle.fine(delta2)))
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

def Sim.stairstep.fin(+level: L.Level, t: Sim.Try) -> Sim.Try:
  match t:
    case Try{True{}, p, things}:
      Try{True{}, p, things}
    case Try{False{}, +p, things}:
      Sim.Try.done(Sim.try_move(level, things, p, (Player.x(p) + Player.momx(p) : U32), Player.y(p)))

# Doom's stairstep: the move along y alone, else along x alone. Either
# way it ends the slide.
def Sim.stairstep(+level: L.Level, things: H.Things, +p: Player) -> Sim.Try:
  Player{+x, +y, z, angle, momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  Sim.stairstep.fin(level, Sim.try_move(level, things, p, x, (y + momy : U32)))

# The remainder of the move, clipped along the wall, becomes the
# momentum and is tried; a failure retries the slide from here.
def Sim.slide.wall.go(+level: L.Level, things: H.Things, +p: Player, m: U32 & U32) -> Sim.Try:
  Player{+x, +y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  (+mx, +my) = m
  Sim.try_move(level, things, Player{x, y, z, angle, mx, my, momz, floorz, ceilz, viewheight, deltaview, viewz,
    crossed, inv, psprites}, (x + mx : U32), (y + my : U32))

def Sim.slide.wall(left: Bool, +level: L.Level, things: H.Things, +p: Player, +frac: U32, i: U32) ->
  Sim.Try:
  match left:
    case False{}:
      Try{True{}, p, things}
    case True{}:
      Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
      Sim.slide.wall.go(level, things, p, Sim.along(level, p, i, F.Fixed.mul(momx, frac),
        F.Fixed.mul(momy, frac)))

# After the move up to the wall: the fraction left, capped at a whole
# move, is slid along the wall if there is any.
def Sim.slide.rest(+level: L.Level, things: H.Things, +p: Player, +frac: U32, i: U32) -> Sim.Try:
  +left = F.Fixed.min(F.Fixed.unit(), (F.Fixed.unit() - frac - 2048 : U32))
  Sim.slide.wall(F.Fixed.gt(left, 0), level, things, p, left, i)

def Sim.slide.upto.fin(+level: L.Level, +frac: U32, i: U32, t: Sim.Try) -> Sim.Try:
  match t:
    case Try{True{}, p, things}:
      Sim.slide.rest(level, things, p, frac, i)
    case Try{False{}, p, things}:
      Sim.stairstep(level, things, p)

# The move up to the wall, a little short of it; a failure stairsteps.
def Sim.slide.upto(some: Bool, +level: L.Level, things: H.Things, +p: Player, +frac: U32, i: U32) ->
  Sim.Try:
  match some:
    case False{}:
      Sim.slide.rest(level, things, p, frac, i)
    case True{}:
      Player{+x, +y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
      Sim.slide.upto.fin(level, frac, i, Sim.try_move(level, things, p,
        (x + F.Fixed.mul(momx, frac) : U32), (y + F.Fixed.mul(momy, frac) : U32)))

# No line hit means the move hit the middle, so stairstep.
def Sim.slide.found(hit: Bool, +level: L.Level, things: H.Things, +p: Player, +frac: U32, i: U32) ->
  Sim.Try:
  match hit:
    case False{}:
      Sim.stairstep(level, things, p)
    case True{}:
      Sim.slide.upto(F.Fixed.gt(frac, 0), level, things, p, frac, i)

def Sim.slide.hit(+level: L.Level, things: H.Things, +p: Player, best: U32 & U32) -> Sim.Try:
  (+frac, i) = best
  Sim.slide.found(U32.is_le(frac, F.Fixed.unit()), level, things, p, (frac - 2048 : U32), i)

def Sim.lead(+v: U32, +mom: U32) -> U32:
  Bool.pick(U32, F.Fixed.gt(mom, 0), (v + Sim.radius() : U32), (v - Sim.radius() : U32))

def Sim.trail(+v: U32, +mom: U32) -> U32:
  Bool.pick(U32, F.Fixed.gt(mom, 0), (v - Sim.radius() : U32), (v + Sim.radius() : U32))

# One try of the slide: the three leading corners are traced along the
# momentum for the closest blocking line.
def Sim.slide.once(+level: L.Level, +things: H.Things, +p: Player) -> Sim.Try:
  Player{+x, +y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  +lx = Sim.lead(x, momx)
  +ly = Sim.lead(y, momy)
  +tx = Sim.trail(x, momx)
  +ty = Sim.trail(y, momy)
  Sim.slide.hit(level, things, p,
    Sim.trace(level, things, p, lx, ty, (lx + momx : U32), (ty + momy : U32),
      Sim.trace(level, things, p, tx, ly, (tx + momx : U32), (ly + momy : U32),
        Sim.trace(level, things, p, lx, ly, (lx + momx : U32), (ly + momy : U32),
          ((F.Fixed.unit() + 1 : U32), 0)))))

def Sim.slide.go(fuel: Nat, +level: L.Level, st: Sim.Try) -> Sim.Try:
  match fuel st:
    case _ Try{True{}, p, things}:
      Try{True{}, p, things}
    case 0n Try{False{}, p, things}:
      Sim.stairstep(level, things, p)
    case 1n+f Try{False{}, p, things}:
      Sim.slide.go(f, level, Sim.slide.once(level, things, p))

# Doom's P_SlideMove: two tries, then stairstep.
def Sim.slide(+level: L.Level, things: H.Things, p: Player) -> Sim.Try:
  Sim.slide.go(2n, level, Try{False{}, p, things})

# XY movement
# -----------

def Sim.xy.tried(+level: L.Level, t: Sim.Try) -> Sim.Try:
  match t:
    case Try{True{}, p, things}:
      Try{True{}, p, things}
    case Try{False{}, p, things}:
      Sim.slide(level, things, p)

def Sim.xy.fin(+level: L.Level, things: H.Things, +p: Player, tx: U32, ty: U32, +xm: U32, +ym: U32) ->
  Sim.Xy:
  Xy{Bool.and(U32.is_zero(xm), U32.is_zero(ym)), Sim.xy.tried(level, Sim.try_move(level, things, p, tx, ty)),
    xm, ym}

# A move past half the most is taken in halves: the half tried is C's
# division, the half kept is the shift, as in Doom.
def Sim.xy.step(big: Bool, +level: L.Level, t: Sim.Try, +xm: U32, +ym: U32) -> Sim.Xy:
  match big:
    case True{}:
      Try{ok, +p, things} = t
      Sim.xy.fin(level, things, p, (Player.x(p) + F.Fixed.half(xm) : U32),
        (Player.y(p) + F.Fixed.half(ym) : U32), F.Fixed.sar(xm), F.Fixed.sar(ym))
    case False{}:
      Try{ok, +p, things} = t
      Sim.xy.fin(level, things, p, (Player.x(p) + xm : U32), (Player.y(p) + ym : U32), 0, 0)

def Sim.big(+xm: U32, +ym: U32) -> Bool:
  Bool.or(F.Fixed.gt(xm, F.Fixed.sar(Sim.maxmove())), F.Fixed.gt(ym, F.Fixed.sar(Sim.maxmove())))

def Sim.xy.go(fuel: Nat, +level: L.Level, st: Sim.Xy) -> Sim.Try:
  match fuel st:
    case _ Xy{True{}, t, xm, ym}:
      t
    case 0n Xy{False{}, t, xm, ym}:
      t
    case 1n+f Xy{False{}, t, +xm, +ym}:
      Sim.xy.go(f, level, Sim.xy.step(Sim.big(xm, ym), level, t, xm, ym))

# Doom's friction on the ground: momentum below the stop speed with no
# move key held stops, else it decays by 0.90625 a tic.
def Sim.slow(stop: Bool, p: Player) -> Player:
  match stop:
    case True{}:
      Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
      Player{x, y, z, angle, 0, 0, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites}
    case False{}:
      Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
      Player{x, y, z, angle, F.Fixed.mul(momx, Sim.decay()), F.Fixed.mul(momy, Sim.decay()),
        momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites}

def Sim.crawling(+mom: U32) -> Bool:
  Bool.and(F.Fixed.gt(mom, F.Fixed.neg(Sim.stopspeed())), F.Fixed.lt(mom, Sim.stopspeed()))

def Sim.friction.ground(+cmd: K.Cmd, +p: Player) -> Player:
  K.Cmd{forward, side, turn, buttons} = cmd
  Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  Sim.slow(Bool.and(Sim.crawling(momx), Bool.and(Sim.crawling(momy),
    Bool.and(U32.is_zero(forward), U32.is_zero(side)))), p)

# No friction in the air.
def Sim.friction(+cmd: K.Cmd, +p: Player) -> Player:
  Bool.pick(Player, Player.onground(p), Sim.friction.ground(cmd, p), p)

def Sim.xy.slowed(+cmd: K.Cmd, t: Sim.Try) -> Sim.Try:
  Try{ok, p, things} = t
  Try{ok, Sim.friction(cmd, p), things}

def Sim.clamp(+mom: U32) -> U32:
  F.Fixed.max(F.Fixed.neg(Sim.maxmove()), F.Fixed.min(mom, Sim.maxmove()))

def Sim.xy.moving(moving: Bool, +level: L.Level, things: H.Things, +cmd: K.Cmd, +p: Player) ->
  Sim.Try:
  match moving:
    case False{}:
      Try{False{}, p, things}
    case True{}:
      Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
      +xm = Sim.clamp(momx)
      +ym = Sim.clamp(momy)
      Sim.xy.slowed(cmd, Sim.xy.go(2n, level, Xy{False{}, Try{False{}, Player{x, y, z, angle, xm, ym, momz, floorz,
        ceilz, viewheight, deltaview, viewz, crossed, inv, psprites}, things}, xm, ym}))

# Doom's P_XYMovement: the momentum, capped, moves the player, in
# halves when large; a blocked move slides; then friction.
def Sim.xy(+level: L.Level, things: H.Things, cmd: K.Cmd, +p: Player) -> Sim.Try:
  Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  Sim.xy.moving(Bool.not(Bool.and(U32.is_zero(momx), U32.is_zero(momy))), level, things, cmd, p)

# The move
# --------

# Doom's P_Thrust: momentum along an angle.
def Sim.thrust(+level: L.Level, p: Player, +angle: U32, +move: U32) -> Player:
  Player{x, y, z, a, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  +sine = L.Level.sine(level)
  +f = A.Angle.fine(angle)
  Player{x, y, z, a, (momx + F.Fixed.mul(move, A.Angle.cos(sine, f)) : U32),
    (momy + F.Fixed.mul(move, A.Angle.sin(sine, f)) : U32), momz, floorz, ceilz, viewheight,
    deltaview, viewz, crossed, inv, psprites}

# A move key thrusts only on the ground.
def Sim.push(+level: L.Level, +p: Player, +angle: U32, +move: U32) -> Player:
  Bool.pick(Player, Bool.or(U32.is_zero(move), Bool.not(Player.onground(p))), p,
    Sim.thrust(level, p, angle, (move * 2048 : U32)))

# Doom's P_MovePlayer: turn, then thrust forward and sideways.
def Sim.move(+level: L.Level, +cmd: K.Cmd, p: Player) -> Player:
  K.Cmd{forward, side, turn, buttons} = cmd
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  +a = (angle + (turn << 16n) : U32)
  Sim.push(level, Sim.push(level, Player{x, y, z, a, momx, momy, momz, floorz, ceilz, viewheight,
    deltaview, viewz, crossed, inv, psprites}, a, forward), (a - A.Angle.ang90() : U32), side)

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
  Player{x, y, +z, angle, momx, momy, momz, floorz, +ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  (+vh, dv) = vd
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, vh, dv,
    F.Fixed.min((z + vh + swing : U32), (ceilz - 262144 : U32)), crossed, inv, psprites}

def Sim.eye.ground(+p: Player, swing: U32) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, +viewheight, +deltaview, viewz, crossed, inv, psprites} = p
  Sim.eye.ground.fin(p, swing, Sim.eye.delta((viewheight + deltaview : U32), deltaview))

# In the air the eye sits at the view height, unbobbed.
def Sim.eye.air(p: Player) -> Player:
  Player{x, y, +z, angle, momx, momy, momz, floorz, ceilz, +viewheight, deltaview, viewz, crossed, inv, psprites} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview,
    (z + viewheight : U32), crossed, inv, psprites}

def Sim.eye.if(onground: Bool, +p: Player, swing: U32) -> Player:
  match onground:
    case True{}:
      Sim.eye.ground(p, swing)
    case False{}:
      Sim.eye.air(p)

# Half of the bob swings the eye on the level's clock, a turn every 20
# tics.
def Sim.eye(+level: L.Level, clock: U32, +p: Player) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  Sim.eye.if(Player.onground(p), p, F.Fixed.mul((Sim.bob(momx, momy) >> 1n : U32),
    A.Angle.sin(L.Level.sine(level), ((409 * clock : U32) .&. 8191 : U32))))

# The vertical move
# -----------------

# Whether the vertical move ends a fall faster than eight units a tic on
# the floor: the landing that dips the view and is heard.
def Sim.lands(p: Player) -> Bool:
  Player{x, y, z, angle, momx, momy, +momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  Bool.and(F.Fixed.le((z + momz : U32), floorz), F.Fixed.lt(momz, F.Fixed.neg((Sim.gravity() << 3n : U32))))

# Below the ceiling: at most 56 under it, no rising momentum.
def Sim.z.ceiling(+z: U32, +momz: U32, +ceilz: U32) -> U32 & U32:
  +hit = F.Fixed.gt((z + Sim.height() : U32), ceilz)
  (Bool.pick(U32, hit, (ceilz - Sim.height() : U32), z),
    Bool.pick(U32, Bool.and(hit, F.Fixed.gt(momz, 0)), 0, momz))

def Sim.z.fin(+p: Player, zm: U32 & U32) -> Player:
  Player{x, y, oz, angle, momx, momy, omomz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  (z, momz) = zm
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites}

# On or under the floor the fall ends there, and a landing dips the view
# by an eighth of the momentum; above it gravity pulls, doubled on the
# first airborne tic.
def Sim.z.clip(+p: Player, +z: U32) -> Player:
  Player{x, y, oz, angle, momx, momy, +momz, +floorz, +ceilz, viewheight, +deltaview, viewz, crossed, inv, psprites} = p
  +floored = F.Fixed.le(z, floorz)
  +falling = F.Fixed.lt(momz, 0)
  +momz2 = Bool.pick(U32, floored, Bool.pick(U32, falling, 0, momz),
    Bool.pick(U32, U32.is_zero(momz), F.Fixed.neg((Sim.gravity() << 1n : U32)),
      (momz - Sim.gravity() : U32)))
  Sim.z.fin(Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight,
    Bool.pick(U32, Sim.lands(p), F.Fixed.sarn(momz, 3n), deltaview), viewz, crossed, inv, psprites},
    Sim.z.ceiling(Bool.pick(U32, floored, floorz, z), momz2, ceilz))

# A floor risen under the player dips the view by the rise, to recover
# by an eighth of the gap a tic.
def Sim.z.step(+p: Player) -> Player:
  Player{x, y, +z, angle, momx, momy, +momz, +floorz, ceilz, +viewheight, deltaview, viewz, crossed, inv, psprites} = p
  +below = F.Fixed.lt(z, floorz)
  +vh = Bool.pick(U32, below, (viewheight - (floorz - z) : U32), viewheight)
  Sim.z.clip(Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, vh,
    Bool.pick(U32, below, F.Fixed.sarn((Sim.viewheight() - vh : U32), 3n), deltaview),
    viewz, crossed, inv, psprites}, (z + momz : U32))

def Sim.z.if(still: Bool, +p: Player) -> Player:
  match still:
    case True{}:
      p
    case False{}:
      Sim.z.step(p)

# Doom's P_ZMovement, run when the player is off the floor or moving
# vertically.
def Sim.z(+p: Player) -> Player:
  Player{x, y, +z, angle, momx, momy, +momz, +floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  Sim.z.if(Bool.and(U32.is_eq(z, floorz), U32.is_zero(momz)), p)

# The state
# ---------

# A step of a mover's plan: its plane moves to a height, down or up, or
# it waits some tics.
type Sim.Step is Data:
  Travel{down: Bool, dest: U32}
  Hold{tics: U32}

# The sounds a mover's sector makes, 0 for none: as it starts, as a wait
# ends, as a travel up or down ends, as something in its way turns it
# back, and every eighth tic of the clock while it travels.
type Sim.Noise is Data:
  Noise{start: U32, wake: U32, up: U32, down: U32, crush: U32, grind: U32}

# Doom's thinkers. A mobj is P_MobjThinker for the mobj an id names, a
# thing's or the player's. A mover is T_VerticalDoor, T_PlatRaise and
# T_MoveFloor in one: a sector's ceiling or floor, a speed, the steps
# left, the whole plan, which a crushed mover starts again, and its
# sounds. A button is a pressed switch waiting to pop back: the side,
# which of its three textures, the texture it showed, and the tics left.
# A blink is
# T_LightFlash and T_StrobeFlash in one: the tics left at the sector's
# light, its dark and bright levels, the time at each, and whether a time
# is the count or the mask of a random one. A glow is T_Glow: the two
# levels and the way it is going.
type Thinker is Data:
  Mobj{id: U32}
  Mover{sector: U32, ceiling: Bool, speed: U32, steps: List<&2, Sim.Step>, plan: List<&2, Sim.Step>,
    noise: Sim.Noise}
  Button{side: U32, slot: U32, texture: U32, tics: U32}
  Blink{sector: U32, count: U32, dark: U32, bright: U32, darktime: U32, brighttime: U32, random: Bool}
  Glow{sector: U32, dark: U32, bright: U32, down: Bool}

# Doom's thinker list, in the order the thinkers were started, which is
# the order they run in: those that have run this tic, the last first,
# and those due, which between tics is all of them. One started while
# they run is due last, so it runs that same tic, as one added to the
# tail of Doom's list does.
type Thinkers is Data:
  Thinkers{ran: List<&2, Thinker>, due: List<&2, Thinker>}

# Everything a tic changes, in one value: the player, the level (its
# sectors' words and its lines' specials), the things alive and their
# links, the sides' texture numbers (top, bottom and middle a side, as
# the graphics number them), the thinkers, the random table's index, the
# clock (Doom's leveltime), whether the level has ended, whether use was
# down on the last tic, the sounds the last tic started and stopped, in
# order, and M_Random's index, the random numbers no demo depends on.
type State is Data:
  State{player: Player, level: L.Level, things: H.Things, sidetex: V.Vec,
    thinkers: Thinkers, rnd: U32, clock: U32, ended: Bool, usedown: Bool,
    sounds: List<&2, Sn.Sound.Event>, mrnd: U32}

def State.player(s: State) -> Player:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  player

def State.level(s: State) -> L.Level:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  level

def State.things(s: State) -> H.Things:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  things

def State.sidetex(s: State) -> V.Vec:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  sidetex

def State.thinkers.of(s: State) -> Thinkers:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  thinkers

# The thinkers in the order they were started.
def State.thinkers(s: State) -> List<&2, Thinker>:
  State{player, level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd} = s
  List.append(&2, Thinker, List.reverse(&2, Thinker, ran), due)

def State.rnd(s: State) -> U32:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  rnd

def State.clock(s: State) -> U32:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  clock

def State.ended(s: State) -> Bool:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  ended

def State.usedown(s: State) -> Bool:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  usedown

def State.sounds(s: State) -> List<&2, Sn.Sound.Event>:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  sounds

def State.mrnd(s: State) -> U32:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  mrnd

# The state with a thinker started, last to run.
def State.thinking(s: State, t: Thinker) -> State:
  State{player, level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd} = s
  State{player, level, things, sidetex, Thinkers{ran, List.append(&2, Thinker, due, [t])}, rnd, clock, ended,
    usedown, sounds, mrnd}

# The state with the thinker whose turn it was kept, to run again next
# tic.
def State.kept(s: State, t: Thinker) -> State:
  State{player, level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd} = s
  State{player, level, things, sidetex, Thinkers{t <> ran, due}, rnd, clock, ended, usedown, sounds, mrnd}

# Sounds
# ------

# The state after the tic reports an event: a start draws from M_Random
# as S_StartSound does.
def State.heard(+e: Sn.Sound.Event, s: State) -> State:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, +mrnd} = s
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown,
    List.append(&2, Sn.Sound.Event, sounds, [e]), Bool.pick(U32, Sn.Sound.Event.draws(e), M.Random.next(mrnd), mrnd)}

def State.told.go(events: List<&2, Sn.Sound.Event>, s: State) -> State:
  match events:
    case []:
      s
    case e <> rest:
      State.told.go(rest, State.heard(e, s))

# The state once it has reported what its things were heard doing.
def State.told(s: State) -> State:
  State{player, level, H.Things{tree, count, you, cells, sectors, heard}, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  State.told.go(heard, State{player, level, H.Things{tree, count, you, cells, sectors, []}, sidetex, thinkers, rnd,
    clock, ended, usedown, sounds, mrnd})

def Sim.sound.spot(xy: U32 & U32) -> Sn.Sound.Source:
  (x, y) = xy
  Sn.Spot{x, y}

# The player hears its own sounds where it stands, and a thing that is
# gone has no place.
def Sim.sound.thing(own: Bool, m: Maybe<&2, H.Thing>) -> Sn.Sound.Source:
  match own m:
    case False{} Some{H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics}}:
      Sn.Spot{x, y}
    case _ _:
      Sn.Nobody{}

# Where a source is: a spot, or nobody for a sound with no place.
def Sim.sound.place(source: Sn.Sound.Source, +s: State) -> Sn.Sound.Source:
  match source:
    case Sn.Thing{+id}:
      Sim.sound.thing(U32.is_eq(id, H.Thing.you()), H.Things.get(State.things(s), id))
    case Sn.Sector{sector}:
      Sim.sound.spot(L.Level.soundorg(State.level(s), sector))
    case other:
      other

# The volume and separation the player hears a place at.
def Sim.sound.params(place: Sn.Sound.Source, +level: L.Level, +p: Player) -> U32 & U32:
  match place:
    case Sn.Spot{x, y}:
      Sn.Sound.adjust(L.Level.sine(level), L.Level.tanto(level), Player.x(p), Player.y(p), Player.angle(p), x, y)
    case _:
      (Sn.Sound.volume(), Sn.Sound.centre())

def Sim.sound.if(audible: Bool, e: Sn.Sound.Event, s: State) -> State:
  match audible:
    case False{}:
      s
    case True{}:
      State.heard(e, s)

def Sim.sound.start(+sfx: U32, source: Sn.Sound.Source, params: U32 & U32, s: State) -> State:
  (+vol, sep) = params
  Sim.sound.if(Bool.not(Bool.or(U32.is_zero(sfx), U32.is_zero(vol))), Sn.Start{sfx, source, vol, sep}, s)

def Sim.sound.told(sfx: U32, +source: Sn.Sound.Source, +s: State) -> State:
  Sim.sound.start(sfx, source, Sim.sound.params(Sim.sound.place(source, s), State.level(s), State.player(s)), s)

# Doom's S_StartSound: a source starts a sound, heard by the player where
# the state has it. What the things were heard doing is reported first,
# so the tic's sounds stay in order. Sound 0 starts nothing, and neither
# does a sound S_AdjustSoundParams finds inaudible, which draws no random
# number either.
def Sim.sound(sfx: U32, source: Sn.Sound.Source, s: State) -> State:
  Sim.sound.told(sfx, source, State.told(s))

# Lights
# ------

def Sim.light(s: State, sector: U32) -> U32:
  L.Level.sector.light(State.level(s), sector)

# A blink goes dark from its bright level, else bright, for that level's
# time, or for a random count under it; put is how it joins the
# thinkers, started or kept.
def Sim.blink.to(~put: @s: State -> @t: Thinker -> State, +lit: Bool, +sector: U32, +dark: U32, +bright: U32,
  +darktime: U32, +brighttime: U32, +random: Bool, s: State) -> State:
  State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd} = s
  +time = Bool.pick(U32, lit, darktime, brighttime)
  +i = Bool.pick(U32, random, M.Random.next(rnd), rnd)
  put(State{player, L.Level.light.put(level, sector, Bool.pick(U32, lit, dark, bright)), things, sidetex,
    thinkers, i, clock, ended, usedown, sounds, mrnd}, Blink{sector, Bool.pick(U32, random,
    ((M.Random.at(i) .&. time : U32) + 1 : U32), time), dark, bright, darktime, brighttime, random})

def Sim.blink(turn: Bool, +sector: U32, count: U32, dark: U32, +bright: U32, darktime: U32, brighttime: U32,
  random: Bool, +s: State) -> State:
  match turn:
    case False{}:
      State.kept(s, Blink{sector, count, dark, bright, darktime, brighttime, random})
    case True{}:
      Sim.blink.to(~State.kept, U32.is_eq(Sim.light(s, sector), bright), sector, dark, bright, darktime, brighttime,
        random, s)

# Doom's T_Glow: 8 a tic, and a step that would reach an end is undone
# and turns the glow.
def Sim.glow(+sector: U32, +dark: U32, +bright: U32, +down: Bool, s: State) -> State:
  State{player, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  +light = L.Level.sector.light(level, sector)
  +next = Bool.pick(U32, down, (light - 8 : U32), (light + 8 : U32))
  +turn = Bool.pick(Bool, down, F.Fixed.le(next, dark), F.Fixed.ge(next, bright))
  State.kept(State{player, L.Level.light.put(level, sector, Bool.pick(U32, turn, light, next)), things, sidetex,
    thinkers, rnd, clock, ended, usedown, sounds, mrnd}, Glow{sector, dark, bright, Bool.xor(down, turn)})

# Movers
# ------

# Doom's P_ThingHeightClip, for the player and every thing: what stood on
# its floor stands on the new one, anything else is lowered under the
# ceiling if it must be.
def Sim.clip(+z: U32, +floorz: U32, +floor: U32, +ceil: U32, +height: U32) -> U32:
  Bool.pick(U32, U32.is_eq(z, floorz), floor, F.Fixed.min(z, (ceil - height : U32)))

def Sim.fits(+floor: U32, +ceil: U32, +height: U32) -> Bool:
  F.Fixed.ge((ceil - floor : U32), height)

# The player clipped again: its position check's pickups, the floor and
# ceiling there, and whether it still fits.
def Sim.reclip.fit(p: Player, touched: I.Inventory & H.Things, f: Sim.Fit) -> Sim.Try:
  Player{x, y, +z, angle, momx, momy, momz, +floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  (held, things) = touched
  Fit{ok, +floor, +ceil} = f
  Try{Sim.fits(floor, ceil, Sim.height()), Player{x, y, Sim.clip(z, floorz, floor, ceil, Sim.height()), angle,
    momx, momy, momz, floor, ceil, viewheight, deltaview, viewz, crossed, held, psprites}, things}

def Sim.reclip.met(+level: L.Level, things: H.Things, +p: Player, m: Sim.Body, +met: Sim.Met) -> Sim.Try:
  Sim.reclip.fit(p, Sim.touch(level, things, p, Player.x(p), Player.y(p), met), Sim.check.met(met, level, m, 1))

def Sim.reclip(+level: L.Level, +things: H.Things, +p: Player) -> Sim.Try:
  Sim.reclip.met(level, things, p, Player.body(p, H.Things.you(things)),
    Sim.met(level, things, p, Player.body(p, H.Things.you(things))))

# A thing clipped again, and whether the mover may go on: a thing that
# no longer fits stops it only when it is shootable, as vanilla's
# PIT_ChangeSector passes over anything else. No map thing is dead or
# dropped, and no E1M1 mover crushes, so nothing is gibbed, removed or
# hurt.
def Sim.reclip.fin(th: H.Thing, m: Sim.Body, f: Sim.Fit) -> Bool & H.Thing:
  H.Thing{id, kind, x, y, +z, +floorz, ceilz, angle, sector, state, tics} = th
  Body{i, mx, my, mz, radius, +height, flags} = m
  Fit{ok, +floor, +ceil} = f
  (Bool.or(Sim.fits(floor, ceil, height), U32.is_zero((flags .&. 4 : U32))),
    H.Thing{id, kind, x, y, Sim.clip(z, floorz, floor, ceil, height), floor, ceil, angle, sector, state, tics})

def Sim.reclip.thing(+level: L.Level, things: H.Things, p: Player, +th: H.Thing) -> Bool & H.Thing:
  Sim.reclip.fin(th, Sim.body.of(th), Sim.check(level, things, p, Sim.body.of(th), 3))

def Sim.change.put(+id: U32, ok: Bool, p: Player, things: H.Things, r: Bool & H.Thing) -> Sim.Try:
  (fits, th) = r
  Try{Bool.and(ok, fits), p, H.Things.put(things, id, Some{th})}

def Sim.change.thing(m: Maybe<&2, H.Thing>, +id: U32, +level: L.Level, ok: Bool, +p: Player, +things: H.Things) ->
  Sim.Try:
  match m:
    case None{}:
      Try{ok, p, things}
    case Some{th}:
      Sim.change.put(id, ok, p, things, Sim.reclip.thing(level, things, p, th))

def Sim.change.player(ok: Bool, t: Sim.Try) -> Sim.Try:
  Try{fits, p, things} = t
  Try{Bool.and(ok, fits), p, things}

# A mobj clipped again: the player's, or a thing's, which has nothing
# to clip once gone.
def Sim.change.one(you: Bool, +id: U32, +level: L.Level, t: Sim.Try) -> Sim.Try:
  match you:
    case True{}:
      Try{ok, +p, things} = t
      Sim.change.player(ok, Sim.reclip(level, things, p))
    case False{}:
      Try{ok, +p, +things} = t
      Sim.change.thing(H.Things.get(things, id), id, level, ok, p, things)

def Sim.change.go(ids: List<&2, U32>, +level: L.Level, +you: U32, t: Sim.Try) -> Sim.Try:
  match ids:
    case []:
      t
    case +id <> rest:
      Sim.change.go(rest, level, you, Sim.change.one(U32.is_eq(id, you), id, level, t))

def Sim.change.box(b: L.Level.Box, +level: L.Level, t: Sim.Try) -> Sim.Try:
  L.Box{+top, +bottom, +left, +right} = b
  Try{ok, p, +things} = t
  Sim.change.go(H.Things.linked(things, L.Level.blockmap_of(level),
    Sim.cells(U32.to_nat(F.Fixed.max((right - left + 1 : U32), 0)),
      U32.to_nat(F.Fixed.max((top - bottom + 1 : U32), 0)), left, bottom)), level, H.Things.you(things),
    Try{ok, p, things})

# Doom's P_ChangeSector: every mobj linked in the cells of the sector's
# block box, touching the sector or not, clipped again in the blockmap's
# order; whether each that must fit does.
def Sim.change(+level: L.Level, +sector: U32, p: Player, things: H.Things) -> Sim.Try:
  Sim.change.box(L.Level.blockbox(level, sector), level, Try{True{}, p, things})

# The state with a try's player and things, in a level.
def State.moved(t: Sim.Try, level: L.Level, s: State) -> State:
  Try{ok, p, got} = t
  State{player, old, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  State{p, level, got, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd}

def Sim.Noise.start(n: Sim.Noise) -> U32:
  Noise{start, wake, up, down, crush, grind} = n
  start

def Sim.Noise.wake(n: Sim.Noise) -> U32:
  Noise{start, wake, up, down, crush, grind} = n
  wake

# A mover with steps left runs again next tic, after those kept so far;
# one with none has ended.
def Sim.mover.kept(sector: U32, ceiling: Bool, speed: U32, steps: List<&2, Sim.Step>,
  plan: List<&2, Sim.Step>, noise: Sim.Noise, s: State) -> State:
  match steps:
    case []:
      s
    case step <> rest:
      State.kept(s, Mover{sector, ceiling, speed, step <> rest, plan, noise})

# A mover's sector heard grinding and then stopping, as T_MoveFloor
# sounds them after its step.
def Sim.mover.heard(+sector: U32, grind: U32, stop: U32, s: State) -> State:
  Sim.sound(stop, Sn.Sector{sector}, Sim.sound(grind, Sn.Sector{sector}, s))

# A step something does not fit is undone, everything clipped again, and
# the mover crushed: it starts its plan again and sounds its crush,
# unless the step was its travel's last, which Doom ends all the same.
def Sim.mover.fitted(t: Sim.Try, +sector: U32, +ceiling: Bool, speed: U32, was: U32, past: Bool,
  +rest: List<&2, Sim.Step>, going: List<&2, Sim.Step>, +plan: List<&2, Sim.Step>, noise: Sim.Noise, grind: U32,
  stop: U32, crush: U32, +s: State) -> State:
  match t:
    case Try{True{}, p, got}:
      Sim.mover.kept(sector, ceiling, speed, going, plan, noise,
        Sim.mover.heard(sector, grind, stop, State.moved(Try{True{}, p, got}, State.level(s), s)))
    case Try{False{}, p, got}:
      +undone = L.Level.plane.put(State.level(s), sector, ceiling, was)
      Sim.mover.kept(sector, ceiling, speed, Bool.pick(List<&2, Sim.Step>, past, rest, plan), plan, noise,
        Sim.mover.heard(sector, grind, crush, State.moved(Sim.change(undone, sector, p, got), undone, s)))

# Doom's T_MovePlane: a step that would pass the destination lands on it
# and ends the travel. A ceiling going up short of its destination does
# not care what fits under it. The sector grinds when the clock's low
# three bits are clear, and a travel's last step sounds its end whether
# or not everything fits.
def Sim.mover.move(+sector: U32, +ceiling: Bool, +speed: U32, +down: Bool, +dest: U32,
  +rest: List<&2, Sim.Step>, plan: List<&2, Sim.Step>, +noise: Sim.Noise, s: State) -> State:
  Noise{start, wake, rose, fell, crush, grind} = noise
  State{+player, +level, +things, sidetex, thinkers, rnd, +clock, ended, usedown, sounds, mrnd} = s
  +was = L.Level.plane(level, sector, ceiling)
  +next = Bool.pick(U32, down, (was - speed : U32), (was + speed : U32))
  +past = Bool.pick(Bool, down, F.Fixed.lt(next, dest), F.Fixed.gt(next, dest))
  +moved = L.Level.plane.put(level, sector, ceiling, Bool.pick(U32, past, dest, next))
  +stop = Bool.pick(U32, past, Bool.pick(U32, down, fell, rose), 0)
  Sim.mover.fitted(Sim.Try.or(Bool.and(ceiling, Bool.not(Bool.or(down, past))),
    Sim.change(moved, sector, player, things)), sector, ceiling, speed, was, past, rest,
    Bool.pick(List<&2, Sim.Step>, past, rest, Travel{down, dest} <> rest), plan, noise,
    Bool.pick(U32, U32.is_zero((clock .&. 7 : U32)), grind, 0), stop, Bool.pick(U32, past, stop, crush),
    State{player, moved, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd})

# Doom's button in P_UpdateSpecials: the tic its count reaches zero the
# side shows its texture again. Vanilla sounds the pop-back from the
# address of the button's origin where it means the origin, and reads a
# place out of the next button's slot: the map's own origin, while that
# slot is free.
def Sim.button(done: Bool, side: U32, slot: U32, texture: U32, tics: U32, s: State) -> State:
  match done:
    case True{}:
      State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
      Sim.sound(Sn.Sound.swtchn(), Sn.Spot{0, 0}, State{player, level, things,
        V.Vec.set(sidetex, (side * 3 + slot : U32), texture), thinkers, rnd, clock, ended, usedown, sounds, mrnd})
    case False{}:
      State.kept(s, Button{side, slot, texture, (tics - 1 : U32)})

# Doom's P_MobjThinker for a thing: its tic through its states. One
# removed has no thing, and its thinker ends here, as Doom's does when
# the run reaches it.
def Sim.thing.tic(m: Maybe<&2, H.Thing>, +id: U32, s: State) -> State:
  match m:
    case None{}:
      s
    case Some{th}:
      State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
      State.kept(State{player, level, H.Things.put(things, id, Some{H.Thing.tic(th)}), sidetex, thinkers, rnd, clock,
        ended, usedown, sounds, mrnd}, Mobj{id})

def Sim.thing(+id: U32, +s: State) -> State:
  Sim.thing.tic(H.Things.get(State.things(s), id), id, s)

# A thinker's tic. A wait counts down, and the tic it reaches zero
# sounds the mover's wake and does nothing else, as Doom's doors and
# lifts turn. A blink turns on the tic its count runs out.
def Sim.think(t: Thinker, s: State) -> State:
  match t:
    case Mobj{id}:
      Sim.thing(id, s)
    case Mover{sector, ceiling, speed, [], plan, noise}:
      s
    case Mover{+sector, ceiling, speed, Hold{+tics} <> +rest, plan, +noise}:
      Sim.mover.kept(sector, ceiling, speed, Bool.pick(List<&2, Sim.Step>, U32.is_eq(tics, 1), rest,
        Hold{(tics - 1 : U32)} <> rest), plan, noise,
        Sim.sound(Bool.pick(U32, U32.is_eq(tics, 1), Sim.Noise.wake(noise), 0), Sn.Sector{sector}, s))
    case Mover{sector, ceiling, speed, Travel{down, dest} <> rest, plan, noise}:
      Sim.mover.move(sector, ceiling, speed, down, dest, rest, plan, noise, s)
    case Button{side, slot, texture, +tics}:
      Sim.button(U32.is_eq(tics, 1), side, slot, texture, tics, s)
    case Blink{sector, +count, dark, bright, darktime, brighttime, random}:
      Sim.blink(U32.is_eq(count, 1), sector, (count - 1 : U32), dark, bright, darktime, brighttime, random, s)
    case Glow{sector, dark, bright, down}:
      Sim.glow(sector, dark, bright, down, s)

# The sectors across a sector's two-sided lines, as Doom's getNextSector
# answers them line by line: the back of a line whose front is the
# sector, else the front.
def Sim.around.of(+sector: U32, line: L.Level.Line, rest: List<&2, U32>) -> List<&2, U32>:
  L.Line{x1, y1, x2, y2, flags, +front, +back} = line
  V.Vec.keep(~U32, Bool.and(Bool.not(U32.is_zero((flags .&. 4 : U32))),
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

# The least or the most of a sector's word over some sectors, from a
# first value: Doom's P_FindLowestCeilingSurrounding and its kin.
def Sim.extreme(~pick: @+a: U32 -> @+b: U32 -> U32, ~read: @+level: L.Level -> @s: U32 -> U32,
  sectors: List<&2, U32>, +level: L.Level, acc: U32) -> U32:
  match sectors:
    case []:
      acc
    case s <> rest:
      Sim.extreme(~pick, ~read, rest, level, pick(acc, read(level, s)))

# Whether a sector has a mover, Doom's specialdata.
def Sim.moving(thinkers: List<&2, Thinker>, +sector: U32) -> Bool:
  match thinkers:
    case []:
      False{}
    case Mover{s, ceiling, speed, steps, plan, noise} <> rest:
      Bool.or(U32.is_eq(s, sector), Sim.moving(rest, sector))
    case _ <> rest:
      Sim.moving(rest, sector)

# A mover begun: at the start of its plan, last to run, its start heard.
def Sim.mover.begin(+sector: U32, ceiling: Bool, speed: U32, +plan: List<&2, Sim.Step>, +noise: Sim.Noise,
  s: State) -> State:
  State.thinking(Sim.sound(Sim.Noise.start(noise), Sn.Sector{sector}, s),
    Mover{sector, ceiling, speed, plan, plan, noise})

# T_VerticalDoor's sounds: the door opens, closes once its wait is over,
# and opens again on what is in its way. The blazing door has its own
# open and close, closes aloud a second time as it shuts, and is turned
# back with the plain door's sound.
def Sim.noise.door() -> Sim.Noise:
  Noise{Sn.Sound.doropn(), Sn.Sound.dorcls(), 0, 0, Sn.Sound.doropn(), 0}

def Sim.noise.blazing() -> Sim.Noise:
  Noise{Sn.Sound.bdopn(), Sn.Sound.bdcls(), 0, Sn.Sound.bdcls(), Sn.Sound.doropn(), 0}

# T_PlatRaise's: the lift starts, stops at either end, starts again
# after its wait, and again when turned back down.
def Sim.noise.lift() -> Sim.Noise:
  Noise{Sn.Sound.pstart(), Sn.Sound.pstart(), Sn.Sound.pstop(), Sn.Sound.pstop(), Sn.Sound.pstart(), 0}

# T_MoveFloor's: the floor grinds as it moves and stops aloud.
def Sim.noise.floor() -> Sim.Noise:
  Noise{0, 0, Sn.Sound.pstop(), Sn.Sound.pstop(), 0, Sn.Sound.stnmov()}

# The level's start
# -----------------

# Doom's P_FindMinSurroundingLight, from the sector's own light.
def Sim.light.low(+s: State, +sector: U32) -> U32:
  Sim.extreme(~F.Fixed.min, ~L.Level.sector.light, Sim.around(State.level(s), sector), State.level(s),
    Sim.light(s, sector))

# The slow strobe's dark level is 0 when no sector around is darker.
def Sim.strobe.dark(+low: U32, light: U32) -> U32:
  Bool.pick(U32, U32.is_eq(low, light), 0, low)

# Doom's P_SpawnSpecials for the sector specials E1M1 carries: 1 blinks
# at random, bright for 1 or 65 tics (the mask is 64) and dark for 1 to
# 8, its first count drawn here; 8 glows; 12 strobes in step with its
# kind, 35 tics dark and 5 bright, dark from its first tic.
def Sim.light.spawn(special: U32, +sector: U32, +s: State) -> State:
  match special:
    case 1:
      Sim.blink.to(~State.thinking, False{}, sector, Sim.light.low(s, sector), Sim.light(s, sector), 7, 64, True{}, s)
    case 8:
      State.thinking(s, Glow{sector, Sim.light.low(s, sector), Sim.light(s, sector), True{}})
    case 12:
      State.thinking(s, Blink{sector, 1, Sim.strobe.dark(Sim.light.low(s, sector), Sim.light(s, sector)),
        Sim.light(s, sector), 35, 5, False{}})
    case _:
      s

def Sim.lights(n: Nat, +sector: U32, +s: State) -> State:
  match n:
    case 0n:
      s
    case 1n+m:
      Sim.lights(m, (sector + 1 : U32),
        Sim.light.spawn(L.Level.sector.special(State.level(s), sector), sector, s))

# A thing entered into a state: in the population, linked where it is,
# its thinker started.
def State.entered(th: H.Thing, s: State) -> State:
  H.Thing{+id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics} = th
  State{player, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  State.thinking(State{player, level, H.Things.entered(things, L.Level.blockmap_of(level),
    H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics}), sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd}, Mobj{id})

def State.entered.all(things: List<&2, H.Thing>, s: State) -> State:
  match things:
    case []:
      s
    case th <> rest:
      State.entered.all(rest, State.entered(th, s))

# The player's mobj entered: linked where the player stands, its thinker
# started.
def State.entered.you(s: State) -> State:
  State{+player, +level, +things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  State.thinking(State{player, level, H.Things.link(things, L.Level.blockmap_of(level), H.Things.you(things),
    Player.x(player), Player.y(player), L.Level.sector_at(level, Player.x(player), Player.y(player))), sidetex,
    thinkers, rnd, clock, ended, usedown, sounds, mrnd}, Mobj{H.Things.you(things)})

# Whether the player's mobj enters before the first of some things: its
# record comes before theirs, or none is left.
def State.you.first(things: List<&2, H.Thing>, you: U32) -> Bool:
  match things:
    case []:
      True{}
    case H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics} <> rest:
      U32.is_lt(you, id)

def State.populated.go(things: List<&2, H.Thing>, first: Bool, +you: U32, s: State) -> State:
  match things first:
    case [] _:
      State.entered.you(s)
    case th <> rest True{}:
      State.entered.all(th <> rest, State.entered.you(s))
    case th <> +rest False{}:
      State.populated.go(rest, State.you.first(rest, you), you, State.entered(th, s))

# No things on a level, the ids under count kept for its records.
def Sim.nothing(bm: L.Level.Blockmap, count: U32, you: U32, nsectors: U32) -> H.Things:
  L.Blockmap{words, ox, oy, cols, rows} = bm
  H.Things.none(count, you, (cols * rows : U32), nsectors)

# A state with other things, their ids under count: the things and the
# player's mobj entered in the order of their ids, which is the order
# Doom spawns a map's records in, so each is linked and thinks as it
# would had it spawned then.
def State.populated(+things: List<&2, H.Thing>, count: U32, s: State) -> State:
  State{player, +level, +old, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  State.populated.go(things, State.you.first(things, H.Things.you(old)), H.Things.you(old),
    State{player, level, Sim.nothing(L.Level.blockmap_of(level), count, H.Things.you(old), L.Level.nsectors(level)),
      sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd})

# Doom's P_SpawnMobj in play: a thing of a type at (x, y) and z, or on
# the floor or under the ceiling for H.Thing.onfloor and
# H.Thing.onceiling. It takes the next id past every one given, draws
# one random number, is linked where it is, and its thinker is started:
# last, so it first thinks the same tic if the thinkers' run is not over,
# as one added to the tail of Doom's list does.
def Sim.spawn(d: H.Thing.Def, x: U32, y: U32, z: U32, s: State) -> State:
  State{player, +level, +things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  State.entered(H.Thing.mobj(d, level, H.Things.count(things), x, y, z), State{player, level,
    H.Things.fresh(things), sidetex, thinkers, M.Random.next(rnd), clock, ended, usedown, sounds, mrnd})

def Sim.remove.thing(m: Maybe<&2, H.Thing>, s: State) -> State:
  match m:
    case None{}:
      s
    case Some{th}:
      State{player, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
      State{player, level, H.Things.removed(things, L.Level.blockmap_of(level), th), sidetex, thinkers, rnd, clock,
        ended, usedown, sounds, mrnd}

# Doom's P_RemoveMobj: the thing unlinked and gone, its id never given
# again, its sound stopped; its thinker ends when its turn comes.
def Sim.remove(id: U32, +s: State) -> State:
  Sim.remove.thing(H.Things.get(State.things(s), id), s)

# The state a level starts in, from the map as loaded, with the player
# at rest at a place, the things spawned with the random numbers they
# draw, and then the lights in sector order. Use counts as down, as
# Doom's G_PlayerReborn leaves it, so a key held since before the level
# does nothing. M_Random's index stands at 64: G_InitNew clears it, and
# the melt that wipes the level in draws once a screen column, 320.
def State.at.spawned(+level: L.Level, place: L.Level.Start, spawn: H.Thing.Spawn) -> State:
  H.Spawn{things, rnd, you} = spawn
  Sim.lights(U32.to_nat(L.Level.nsectors(level)), 0, State.populated(things, L.Level.nthings(level),
    State{Player.at(level, place), level, H.Things.none(0, you, 0, 0), L.Level.sidetex(level), Thinkers{[], []},
      rnd, 0, False{}, True{}, [], 64}))

def State.at(+level: L.Level, place: L.Level.Start) -> State:
  State.at.spawned(level, place, H.Thing.spawn(level))

def State.start(+level: L.Level) -> State:
  State.at(level, L.Level.start_of(level))

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
    case Mover{+s, ceiling, speed, +steps, +plan, noise} <> rest:
      Mover{s, ceiling, speed, Bool.pick(List<&2, Sim.Step>, U32.is_eq(s, sector),
        Sim.door.turned(steps, plan, floor), steps), plan, noise} <> Sim.door.turn(rest, sector, floor)
    case other <> rest:
      other <> Sim.door.turn(rest, sector, floor)

# A door's top: 4 under the lowest ceiling around it.
def Sim.door.top(+level: L.Level, sector: U32) -> U32:
  (Sim.extreme(~F.Fixed.min, ~L.Level.ceil, Sim.around(level, sector), level, 2147483647) - 262144 : U32)

# A door's plan: up to its top, 150 tics open, down to its floor.
def Sim.door.plan(+level: L.Level, +sector: U32) -> List<&2, Sim.Step>:
  [Travel{False{}, Sim.door.top(level, sector)}, Hold{150}, Travel{True{}, L.Level.floor(level, sector)}]

# A door already moving is turned without a sound.
def Sim.door.on(moving: Bool, +sector: U32, speed: U32, noise: Sim.Noise, +s: State) -> State:
  match moving:
    case True{}:
      State{player, +level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd} = s
      State{player, level, things, sidetex, Thinkers{Sim.door.turn(ran, sector, L.Level.floor(level, sector)),
        Sim.door.turn(due, sector, L.Level.floor(level, sector))}, rnd, clock, ended, usedown, sounds, mrnd}
    case False{}:
      Sim.mover.begin(sector, True{}, speed, Sim.door.plan(State.level(s), sector), noise, s)

# Doom's EV_VerticalDoor: the door is the sector behind the line.
def Sim.door(line: L.Level.Line, speed: U32, noise: Sim.Noise, +s: State) -> State:
  L.Line{x1, y1, x2, y2, flags, front, +back} = line
  Sim.door.on(Sim.moving(State.thinkers(s), back), back, speed, noise, s)

# Doom's locked EV_VerticalDoor: without the key it refuses with a grunt
# from nobody; with it, it is the manual door.
def Sim.door.locked(opens: Bool, line: L.Level.Line, s: State) -> State:
  match opens:
    case True{}:
      Sim.door(line, 131072, Sim.noise.door(), s)
    case False{}:
      Sim.sound(Sn.Sound.oof(), Sn.Nobody{}, s)

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
      V.Vec.keep(~U32, Bool.and(U32.is_eq(L.Level.sector.tag(level, s), tag), Bool.not(Sim.moving(thinkers, s))), s,
        Sim.tagged.go(m, level, thinkers, tag, (s + 1 : U32)))

def Sim.tagged(+s: State, line: U32) -> List<&2, U32>:
  Sim.tagged.go(U32.to_nat(L.Level.nsectors(State.level(s))), State.level(s), State.thinkers(s),
    L.Level.tag(State.level(s), line), 0)

# A mover begun for each sector, all against the level as it stood.
def Sim.start(~make: @+level: L.Level -> @+sector: U32 -> @s: State -> State, sectors: List<&2, U32>, +s: State) ->
  State:
  match sectors:
    case []:
      s
    case sector <> rest:
      Sim.start(~make, rest, make(State.level(s), sector, s))

# Doom's lowerFloorToLowest: 1 a tic down to the lowest floor around,
# its own included.
def Sim.floor.low(+level: L.Level, +sector: U32, s: State) -> State:
  Sim.mover.begin(sector, False{}, 65536, [Travel{True{}, Sim.extreme(~F.Fixed.min,
    ~L.Level.floor, Sim.around(level, sector), level, L.Level.floor(level, sector))}], Sim.noise.floor(), s)

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
    case _ <> rest:
      Sim.pressed.side(rest, side)

# P_ChangeSwitchTexture sounds a switch from the first button's origin
# where it means the pressed line's: nobody while no button runs, else
# the sector in front of the running button's line. Vanilla's first
# button is a slot, which can be free while a later one runs; here it is
# the first still running, the same while one runs at a time.
def Sim.switch.origin(thinkers: List<&2, Thinker>, +level: L.Level) -> Sn.Sound.Source:
  match thinkers:
    case []:
      Sn.Nobody{}
    case Button{side, slot, texture, tics} <> rest:
      Sn.Sector{L.Level.side.sector(level, side)}
    case _ <> rest:
      Sim.switch.origin(rest, level)

# A switch that works again starts a button of 35 tics for the texture
# it showed, unless its side has one running.
def Sim.switch.button(start: Bool, side: U32, slot: U32, showed: U32, s: State) -> State:
  match start:
    case False{}:
      s
    case True{}:
      State.thinking(s, Button{side, slot, showed, 35})

# The switch's texture swapped for its partner, with a click. The exit
# switch clicks like any other: vanilla clears a once-only line's special
# before it looks for the exit's, so sfx_swtchx never plays.
def Sim.switch.swap(none: Bool, again: Bool, +side: U32, +slot: U32, s: State) -> State:
  match none:
    case True{}:
      s
    case False{}:
      State{player, +level, things, +sidetex, Thinkers{+ran, +due}, rnd, clock, ended, usedown, sounds, mrnd} = s
      +showed = V.Vec.get(sidetex, (side * 3 + slot : U32))
      +started = List.append(&2, Thinker, List.reverse(&2, Thinker, ran), due)
      Sim.switch.button(Bool.and(again, Bool.not(Sim.pressed.side(started, side))), side, slot, showed,
        Sim.sound(Sn.Sound.swtchn(), Sim.switch.origin(started, level),
          State{player, level, things, V.Vec.set(sidetex, (side * 3 + slot : U32), L.Level.switch(level, showed)),
            Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd}))

# Doom's P_ChangeSwitchTexture on the line's front side.
def Sim.switch(again: Bool, line: U32, +s: State) -> State:
  +side = L.Level.line.side(State.level(s), line, 0)
  +slot = Sim.switch.slot(State.level(s), State.sidetex(s), (side * 3 : U32))
  Sim.switch.swap(U32.is_eq(slot, 3), again, side, slot, s)

# A line that works once has no special afterwards.
def Sim.once(line: U32, s: State) -> State:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  State{player, L.Level.special.put(level, line, 0), things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd}

# Doom's G_ExitLevel: the level ends, and the tic it ends on runs on.
def State.end(s: State) -> State:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  State{player, level, things, sidetex, thinkers, rnd, clock, True{}, usedown, sounds, mrnd}

# A switch that works once: when its tag starts a mover, its texture is
# swapped and its special cleared.
def Sim.use.once(~make: @+level: L.Level -> @+sector: U32 -> @s: State -> State, sectors: List<&2, U32>, +line: U32,
  s: State) -> State:
  match sectors:
    case []:
      s
    case sector <> rest:
      Sim.once(line, Sim.switch(False{}, line, Sim.start(~make, sector <> rest, s)))

# A switch that works again: when its tag starts a mover, its texture is
# swapped for 35 tics.
def Sim.use.again(~make: @+level: L.Level -> @+sector: U32 -> @s: State -> State, sectors: List<&2, U32>, line: U32,
  +s: State) -> State:
  match sectors:
    case []:
      s
    case sector <> rest:
      Sim.switch(True{}, line, Sim.start(~make, sector <> rest, s))

# Doom's downWaitUpStay lift: 4 a tic down to the lowest floor around,
# its own included, 105 tics there, and back up to where it was.
def Sim.lift(+level: L.Level, +sector: U32, s: State) -> State:
  Sim.mover.begin(sector, False{}, 262144, [Travel{True{}, Sim.extreme(~F.Fixed.min,
    ~L.Level.floor, Sim.around(level, sector), level, L.Level.floor(level, sector))}, Hold{105},
    Travel{False{}, L.Level.floor(level, sector)}], Sim.noise.lift(), s)

# Walk-over lines
# ---------------

def Sim.door.open.to(+sector: U32, +top: U32, ceil: U32, s: State) -> State:
  Sim.mover.begin(sector, True{}, 131072, [Travel{False{}, top}],
    Noise{Bool.pick(U32, U32.is_eq(top, ceil), 0, Sn.Sound.doropn()), 0, 0, 0, 0, 0}, s)

# Doom's EV_DoDoor open: up to the door's top, where it stays, heard
# unless it is there already.
def Sim.door.open(+level: L.Level, +sector: U32, s: State) -> State:
  Sim.door.open.to(sector, Sim.door.top(level, sector), L.Level.ceil(level, sector), s)

# Doom's turboLower: 4 a tic down to the highest floor around, plus 8
# when that is not the floor's own height. A travel down to a height
# above lands at once, as Doom's does.
def Sim.floor.turbo.to(+highest: U32, own: U32) -> U32:
  Bool.pick(U32, U32.is_eq(highest, own), highest, (highest + 524288 : U32))

def Sim.floor.turbo(+level: L.Level, +sector: U32, s: State) -> State:
  Sim.mover.begin(sector, False{}, 262144, [Travel{True{}, Sim.floor.turbo.to(Sim.extreme(~F.Fixed.max,
    ~L.Level.floor, Sim.around(level, sector), level, 4262199296), L.Level.floor(level, sector))}],
    Sim.noise.floor(), s)

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

# Doom's P_UseSpecialLine for the specials E1M1 carries: the manual door,
# its blazing twin and its blue locked twin, the switch that lowers
# floors, the lift's, and the exit. Any special Doom does not know does
# nothing.
def Sim.use.special(special: U32, +i: U32, inv: I.Inventory, +s: State) -> State:
  match special:
    case 1:
      Sim.door(L.Level.line(State.level(s), i), 131072, Sim.noise.door(), s)
    case 117:
      Sim.door(L.Level.line(State.level(s), i), 524288, Sim.noise.blazing(), s)
    case 26:
      Sim.door.locked(I.Inventory.blue(inv), L.Level.line(State.level(s), i), s)
    case 23:
      Sim.use.once(~Sim.floor.low, Sim.tagged(s, i), i, s)
    case 62:
      Sim.use.again(~Sim.lift, Sim.tagged(s, i), i, s)
    case 11:
      State.end(Sim.once(i, Sim.switch(False{}, i, s)))
    case _:
      s

# Only the front of a line answers use.
def Sim.use.line(back: Bool, +level: L.Level, +i: U32, inv: I.Inventory, s: State) -> State:
  match back:
    case True{}:
      s
    case False{}:
      Sim.use.special(L.Level.special(level, i), i, inv, s)

# What a use trace reaches: a special line, a wall that ends it, or
# nothing.
type Sim.Reach is Data:
  Special{line: U32}
  Wall{}
  Nothing{}

# The player grunts at a wall.
def Sim.use.hit(hit: Sim.Reach, +p: Player, +s: State) -> State:
  match hit:
    case Nothing{}:
      s
    case Wall{}:
      Sim.sound(Sn.Sound.noway(), Sn.Thing{H.Thing.you()}, s)
    case Special{+i}:
      Sim.use.line(Sim.point_side(Player.x(p), Player.y(p), L.Level.line(State.level(s), i)),
        State.level(s), i, Player.inv(p), s)

# Doom's P_LineOpening leaves no opening in a line with one side.
def Sim.use.shut(+level: L.Level, +line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, flags, front, back} = line
  Bool.or(U32.is_eq(back, L.Level.none()),
    F.Fixed.le((Sim.open_top(level, line) - Sim.open_bottom(level, line) : U32), 0))

def Sim.use.at(special: Bool, shut: Bool, i: U32) -> Sim.Answer<&2, Sim.Reach>:
  match special shut:
    case True{} _:
      Answer{True{}, Special{i}}
    case False{} True{}:
      Answer{True{}, Wall{}}
    case False{} False{}:
      Answer{False{}, Nothing{}}

# Doom's PTR_UseTraverse: the first special line ends the walk whatever
# its special; a line without one ends it at a wall, and is passed when
# its opening is more than nothing.
def Sim.use.visit(+level: L.Level, m: Sim.Meet, reach: Sim.Reach) -> Sim.Answer<&2, Sim.Reach>:
  Meet{frac, isline, +i} = m
  Sim.use.at(Bool.not(U32.is_zero(L.Level.special(level, i))), Sim.use.shut(level, L.Level.line(level, i)), i)

# Doom's P_UseLines, on the press: a trace of 64 units along the facing.
def Sim.use(press: Bool, +s: State) -> State:
  match press:
    case False{}:
      s
    case True{}:
      +p = State.player(s)
      +level = State.level(s)
      +sine = L.Level.sine(level)
      +f = A.Angle.fine(Player.angle(p))
      Sim.use.hit(Sim.path(~Sim.Reach, ~Sim.use.visit, level, State.things(s), p, True{}, False{}, Player.x(p),
        Player.y(p),
        (Player.x(p) + 64 * A.Angle.cos(sine, f) : U32), (Player.y(p) + 64 * A.Angle.sin(sine, f) : U32),
        Nothing{}), p, s)

# The tic
# -------

# Use acts on the tic it goes down, not while it is held.
def Sim.pressed(cmd: K.Cmd, usedown: Bool) -> Bool:
  Bool.and(Bool.not(usedown), K.Cmd.use(cmd))

# The player where it stood before a thinker's turn, as the turn left
# it otherwise, the lines it crossed fired and forgotten.
def Player.held(before: Player, after: Player) -> Player:
  Player{x, y, bz, ba, bmomx, bmomy, bmomz, bfloorz, bceilz, bviewheight, bdeltaview, bviewz, bcrossed, binv, bpsprites} = before
  Player{ax, ay, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = after
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, [], inv, psprites}

# What a turn keeps of the state it began with, whatever it did: the
# geometry, so no tic writes a wall, and the player's place, so nothing
# but the player's own movement moves the player sideways.
def State.held(geo: L.Level.Geo, before: State, after: State) -> State:
  State{was, wlevel, wthings, wsidetex, wthinkers, wrnd, wclock, wended, wusedown, wsounds, wmrnd} = before
  State{player, L.Level{g, sectors, specials}, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = after
  State{Player.held(was, player), L.Level{geo, sectors, specials}, things, sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd}

# P_PlayerThink's counters.
def Sim.counters(p: Player) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed,
    I.Inventory.tic(inv), psprites}

# The player's own landing, heard from the player.
def Sim.mobj.landed(hard: Bool, things: H.Things) -> H.Things:
  match hard:
    case False{}:
      things
    case True{}:
      H.Things.sounded(things, Sn.Sound.plain(Sn.Sound.oof(), Sn.Thing{H.Thing.you()}))

def Sim.mobj.z(t: Sim.Try) -> Sim.Try:
  Try{ok, +p, things} = t
  Try{ok, Sim.z(p), Sim.mobj.landed(Sim.lands(p), things)}

# Doom's P_MobjThinker for the player: the XY movement, with the pickups
# its position checks make, then the vertical, against the level the tic
# began with, whose geometry the wall law reads; the lines that movement
# crossed fire, and the thinker is kept.
def Sim.mobj(+cmd: K.Cmd, +geo: L.Level.Geo, +s: State) -> State:
  +level = {L.Level{geo, L.Level.sectors(State.level(s)), L.Level.specials(State.level(s))} : L.Level}
  +went = State.moved(Sim.mobj.z(Sim.xy(level, State.things(s), cmd, State.player(s))), level, s)
  State.kept(State.held(geo, went, Sim.cross(Player.crossed(State.player(went)), went)),
    Mobj{H.Things.you(State.things(s))})

# Whether a thinker is the player's mobj's.
def Sim.mine(t: Thinker, you: U32) -> Bool:
  match t:
    case Mobj{id}:
      U32.is_eq(id, you)
    case _:
      False{}

# A thinker's turn: the player's mobj moves the player; any other
# thinks, and the state is held where it was.
def Sim.turn(mine: Bool, t: Thinker, cmd: K.Cmd, +geo: L.Level.Geo, +s: State) -> State:
  match mine:
    case True{}:
      Sim.mobj(cmd, geo, s)
    case False{}:
      State.held(geo, s, Sim.think(t, s))

# One run down the thinkers due, its fuel the list of them as it began:
# each in turn, in the order they were started. Those started meanwhile
# are still due when it ends.
def Sim.thinkers.go(fuel: List<&2, Thinker>, +cmd: K.Cmd, +geo: L.Level.Geo, s: State) -> State:
  match fuel s:
    case [] s:
      s
    case f <> rest State{player, level, things, sidetex, Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd}:
      State{player, level, things, sidetex, Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd}
    case f <> rest State{player, level, +things, sidetex, Thinkers{ran, +t <> due}, rnd, clock, ended, usedown, sounds, mrnd}:
      Sim.thinkers.go(rest, cmd, geo, Sim.turn(Sim.mine(t, H.Things.you(things)), t, cmd, geo,
        State{player, level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd}))

# Runs until none is due: the thinkers a run started run in the next, the
# same tic, as those added to the tail of Doom's list do. The fuel is
# how deep that may go; past it they wait a tic.
def Sim.thinkers.all(fuel: Nat, +cmd: K.Cmd, +geo: L.Level.Geo, s: State) -> State:
  match fuel s:
    case 0n s:
      s
    case 1n+f State{player, level, things, sidetex, Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd}:
      State{player, level, things, sidetex, Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd}
    case 1n+f State{player, level, things, sidetex, Thinkers{ran, +t <> +due}, rnd, clock, ended, usedown, sounds, mrnd}:
      Sim.thinkers.all(f, cmd, geo, Sim.thinkers.go(t <> due, cmd, geo,
        State{player, level, things, sidetex, Thinkers{ran, t <> due}, rnd, clock, ended, usedown, sounds, mrnd}))

# The thinkers all due again, in the order they were started.
def State.rested(s: State) -> State:
  State{player, level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd} = s
  State{player, level, things, sidetex, Thinkers{[], List.append(&2, Thinker, List.reverse(&2, Thinker, ran), due)},
    rnd, clock, ended, usedown, sounds, mrnd}

# Doom's P_RunThinkers.
def Sim.thinkers(+cmd: K.Cmd, +geo: L.Level.Geo, s: State) -> State:
  State.rested(Sim.thinkers.all(8n, cmd, geo, s))

# What a live tic makes of the state its thinkers left: the geometry it
# began with, the clock counted, and whether use was down.
def Sim.tic.kept(geo: L.Level.Geo, clock: U32, use: Bool, +after: State) -> State:
  State{State.player(after), L.Level{geo, L.Level.sectors(State.level(after)), L.Level.specials(State.level(after))},
    State.things(after), State.sidetex(after), State.thinkers.of(after), State.rnd(after), (clock + 1 : U32),
    State.ended(after), use, State.sounds(after), State.mrnd(after)}

# One tic in Doom's order: the player thinks (the move, the eye, the
# player sprites, the counters, use on the press), the thinkers run in
# the order they were started (the mobjs of the map's records, the
# player's among them, whose own turn moves the player and fires the
# lines that move crossed, then the lights, then what play started), the
# clock counts. The tic's sounds start from none, and what the things
# were heard doing is reported when its last thinker has run. An ended
# level stands still: no tic runs, so its sounds stay the last live
# tic's, and whoever gathers sounds tic by tic passes over it.
def Sim.tic(+cmd: K.Cmd, s: State) -> State:
  match s:
    case State{player, level, things, sidetex, thinkers, rnd, clock, True{}, usedown, sounds, mrnd}:
      State{player, level, things, sidetex, thinkers, rnd, clock, True{}, usedown, sounds, mrnd}
    case State{player, L.Level{+geo, sectors, specials}, things, sidetex, thinkers, rnd, +clock, False{}, +usedown, sounds, mrnd}:
      +level = {L.Level{geo, sectors, specials} : L.Level}
      +thought = Sim.counters(Sim.psprites(level, clock, Sim.eye(level, clock, Sim.move(level, cmd, player))))
      +before = {State{thought, level, things, sidetex, thinkers, rnd, clock, False{}, usedown, [], mrnd} : State}
      Sim.tic.kept(geo, clock, K.Cmd.use(cmd), State.told(Sim.thinkers(cmd, geo,
        State.held(geo, before, Sim.use(Sim.pressed(cmd, usedown), before)))))

# A tic for each command of the list, in order: a demo.
def Sim.replay(script: List<&2, K.Cmd>, s: State) -> State:
  match script:
    case []:
      s
    case cmd <> rest:
      Sim.replay(rest, Sim.tic(cmd, s))
