# The playsim for one player among things that stand still: Doom's
# P_MovePlayer, P_CalcHeight, P_MovePsprites, P_XYMovement, P_TryMove,
# P_CheckPosition, P_SlideMove and P_ZMovement, as pure functions of the
# level, the things, the tic command and the player, and the tic that
# maps one state of the level to the next, with the sounds that tic
# starts and stops where vanilla calls S_StartSound and S_StopSound.
# The player can be hurt and killed: P_DamageMobj, P_KillMobj,
# P_PlayerInSpecialSector and P_DeathThink, which asks for the level
# again as vanilla's PST_REBORN does.
# Every position the player is moved to has passed Sim.fit, which is what
# Sim.free asks, so the wall law holds by construction.
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

# What a blow leaves on the player: the row of the mobj state its own
# sprite would show, which times its pain and death sounds, the tics left
# in that row, the damage count the palette and the face read, and who
# hit last, none for a blow from nobody or from the player itself, which
# P_DeathThink treats alike.
type Sim.Hurt is Data:
  Hurt{state: U32, tics: U32, damage: U32, attacker: Maybe<&2, U32>}

# Doom's mobj and player_t for one player: the position with its height,
# the angle, the momentum, the floor and ceiling under it, the view
# height and its delta, the eye's height, the special lines this tic's
# moves have crossed, in the order they fire, the inventory, the player
# sprites, and what damage has left.
type Player is Data:
  Player{x: U32, y: U32, z: U32, angle: U32, momx: U32, momy: U32, momz: U32,
    floorz: U32, ceilz: U32, viewheight: U32, deltaview: U32, viewz: U32, crossed: List<&2, U32>,
    inv: I.Inventory, psprites: Psprites, hurt: Sim.Hurt}

# What Doom's P_CheckPosition answers for a box of some radius: whether
# no solid thing overlaps it and no line stops it, and the floor and
# ceiling there. A thing in the way leaves the sector's under the point;
# otherwise each two-sided line the box crosses narrows them, up to the
# first line that stops the box.
type Sim.Fit is Data:
  Fit{ok: Bool, floor: U32, ceil: U32}

# A move that was tried: whether it was taken, the player after, and
# the things left by the pickups its position checks made, taken or
# not. Also the slide loop's state, done when a move along the wall was
# taken.
type Sim.Try is Data:
  Try{ok: Bool, player: Player, things: H.Things}

# The pickup loop's state: whether a solid thing has ended the check,
# and the inventory and things so far.
type Sim.Touch is Data:
  Touch{stop: Bool, inv: I.Inventory, things: H.Things}

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

# The player's mobj at rest and unhurt, as P_SpawnPlayer and
# G_PlayerReborn leave it: its standing state, which lasts.
def Sim.Hurt.start() -> Sim.Hurt:
  Hurt{H.Thing.play(), H.Thing.Row.tics(H.Thing.row(H.Thing.play())), 0, None{}}

# The damage count fades by one a tic, in P_PlayerThink's counters and
# in P_DeathThink.
def Sim.Hurt.fade(h: Sim.Hurt) -> Sim.Hurt:
  Hurt{state, tics, +damage, attacker} = h
  Hurt{state, tics, (damage - I.Inventory.on(damage) : U32), attacker}

def Sim.Hurt.damage(h: Sim.Hurt) -> U32:
  Hurt{state, tics, damage, attacker} = h
  damage

def Sim.Hurt.attacker(h: Sim.Hurt) -> Maybe<&2, U32>:
  Hurt{state, tics, damage, attacker} = h
  attacker

def Player.x(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  x

def Player.y(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  y

def Player.angle(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  angle

def Player.momx(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  momx

def Player.momy(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  momy

def Player.z(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  z

def Player.floorz(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  floorz

def Player.ceilz(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  ceilz

def Player.crossed(+p: Player) -> List<&2, U32>:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  crossed

def Player.viewz(+p: Player) -> U32:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  viewz

def Player.inv(+p: Player) -> I.Inventory:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  inv

def Player.psprites(+p: Player) -> Psprites:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  psprites

def Player.hurt(+p: Player) -> Sim.Hurt:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  hurt

# Doom's PST_DEAD, which P_PlayerThink and P_CalcHeight ask of the
# player and P_TouchSpecialThing of a toucher.
def Player.dead(+p: Player) -> Bool:
  I.Inventory.dead(Player.inv(p))

# The player holding an inventory.
def Player.holding(p: Player, held: I.Inventory) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, held, psprites, hurt}

# On the ground: at or below the floor.
def Player.onground(+p: Player) -> Bool:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  F.Fixed.le(z, floorz)

# The weapon
# ----------

# Doom's WEAPONBOTTOM, WEAPONTOP, RAISESPEED and LOWERSPEED: the screen
# row a weapon starts to rise from, the row it rests at, and its rise and
# its fall a tic, 6 units each.
def Sim.weaponbottom() -> U32:
  8388608

def Sim.weapontop() -> U32:
  2097152

def Sim.raisespeed() -> U32:
  393216

def Sim.lowerspeed() -> U32:
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
  H.Weapon{up, ready, down} = weapon
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

# Doom's A_Lower for a dead player: the sprite sinks 6 a tic and stays
# at the bottom of the screen. Death is the only thing that lowers a
# weapon here, so the branch that brings the next one up has no caller.
def Sim.lower(psp: Psprite) -> Sim.Entering:
  Psprite{state, tics, sx, +sy} = psp
  Entering{None{}, Psprite{state, tics, sx, F.Fixed.min((sy + Sim.lowerspeed() : U32), Sim.weaponbottom())}}

def Sim.psprite.act(action: H.Thing.Action, psp: Psprite, sine: V.Vec, clock: U32, bob: U32,
  weapon: H.Thing.Weapon) -> Sim.Entering:
  match action:
    case H.Raise{}:
      Sim.raise(psp, weapon)
    case H.WeaponReady{}:
      Sim.ready(psp, sine, clock, bob)
    case H.Lower{}:
      Sim.lower(psp)
    case other:
      Entering{None{}, psp}

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
    Psprites{weapon, flash}, hurt} = p
  +sine = L.Level.sine(level)
  +bob = Sim.bob(momx, momy)
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv,
    Sim.psprites.follow(Sim.psprite.tic(weapon, sine, clock, bob, H.Thing.pistol()),
      Sim.psprite.tic(flash, sine, clock, bob, H.Thing.pistol())), hurt}

# Doom's P_SetupPsprites and P_BringUpWeapon: no sprite shows, then the
# weapon enters its raise state at the bottom.
def Psprites.start(+sine: V.Vec, +weapon: H.Thing.Weapon) -> Psprites:
  H.Weapon{up, ready, down} = weapon
  Psprites{Sim.psprite.set(4n, Entering{Some{up}, Psprite{None{}, 0, 0, Sim.weaponbottom()}}, sine, 0, 0, weapon),
    Psprite{None{}, 0, 0, 0}}

def Player.at.fin(+x: U32, +y: U32, angle: U32, +floor: U32, ceil: U32, psprites: Psprites) -> Player:
  Player{x, y, floor, angle, 0, 0, 0, floor, ceil, Sim.viewheight(), 0,
    (floor + Sim.viewheight() : U32), [], I.Inventory.start(), psprites, Sim.Hurt.start()}

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

# What a reader finds in each of some cells of the geometry, in turn.
def Sim.gather(~at: @+geo: L.Level.Geo -> @+c: L.Level.Cell -> List<&2, U32>, cells: List<&2, L.Level.Cell>,
  +geo: L.Level.Geo) -> List<&2, U32>:
  match cells:
    case []:
      []
    case c <> rest:
      List.append(&2, U32, at(geo, c), Sim.gather(~at, rest, geo))

# The lines of the cells a box touches, as one list (a line in two cells
# is listed twice, and line 0 in each).
def Sim.lines(+level: L.Level, x0: U32, y0: U32, x1: U32, y1: U32) -> List<&2, U32>:
  Sim.gather(~L.Level.cell.lines, Sim.box(L.Level.blockmap_of(level), x0, y0, x1, y1), L.Level.geo(level))

# Doom's MAXRADIUS, 32, the largest radius a thing has.
def Sim.maxradius() -> U32:
  2097152

# The things linked in the cells of a box of radius r at (x, y) widened
# by the largest radius, in the blockmap's order: the things Doom's
# P_CheckPosition looks at, since a thing is linked by its centre alone.
def Sim.near(+level: L.Level, +x: U32, +y: U32, +r: U32) -> List<&2, U32>:
  +reach = (r + Sim.maxradius() : U32)
  Sim.gather(~L.Level.cell.things, Sim.box(L.Level.blockmap_of(level), (x - reach : U32), (y - reach : U32),
    (x + reach : U32), (y + reach : U32)), L.Level.geo(level))

# Things
# ------

# Doom's PIT_CheckThing's first test: boxes of radius q at (tx, ty) and
# r at (x, y) meet when their centres are nearer than the two radii
# along both axes.
def Sim.overlap(+q: U32, +tx: U32, +ty: U32, +x: U32, +y: U32, +r: U32) -> Bool:
  +reach = (q + r : U32)
  Bool.and(F.Fixed.lt(F.Fixed.abs((tx - x : U32)), reach), F.Fixed.lt(F.Fixed.abs((ty - y : U32)), reach))

def Sim.blocker.def(d: H.Thing.Def, +tx: U32, +ty: U32, +x: U32, +y: U32, +r: U32, other: Bool) -> Bool:
  H.Def{kind, state, +radius, height, +flags} = d
  Bool.and(Bool.not(U32.is_zero((flags .&. 2 : U32))),
    Bool.and(other, Sim.overlap(F.Fixed.of_map(radius), tx, ty, x, y, r)))

def Sim.blocker.link(link: L.Level.Link, +x: U32, +y: U32, +r: U32, other: Bool) -> Bool:
  L.Link{next, +tx, +ty, +kind} = link
  Sim.blocker.def(H.Thing.info(kind), tx, ty, x, y, r, other)

# Doom's PIT_CheckThing's verdict on thing id for a box of radius r at
# (x, y) that is self's: the thing stops the box when it is solid, not
# self, and its box overlaps. A solid thing is never removed, and none
# is special, so its link alone decides.
def Sim.blocker(+links: L.Level.Things, +x: U32, +y: U32, +r: U32, +self: U32, +id: U32) -> Bool:
  Sim.blocker.link(L.Level.linked.in(links, id), x, y, r, Bool.not(U32.is_eq(id, self)))

def Sim.clear.go(ids: List<&2, U32>, +links: L.Level.Things, +x: U32, +y: U32, +r: U32, +self: U32) -> Bool:
  match ids:
    case []:
      True{}
    case +id <> rest:
      Bool.and(Bool.not(Sim.blocker(links, x, y, r, self, id)), Sim.clear.go(rest, links, x, y, r, self))

# The thing half of Doom's P_CheckPosition: whether the box of radius r
# at (x, y) is clear of every solid thing near it but self's, the
# player's name for the player's box.
def Sim.clear(+level: L.Level, +x: U32, +y: U32, +r: U32, +self: U32) -> Bool:
  Sim.clear.go(Sim.near(level, x, y, r), L.Level.things_of(level), x, y, r, self)

# The floor and ceiling of the sector under a point.
def Sim.fit.start(ok: Bool, +level: L.Level, +x: U32, +y: U32) -> Sim.Fit:
  +sector = L.Level.sector_at(level, x, y)
  Fit{ok, L.Level.floor(level, sector), L.Level.ceil(level, sector)}

# Doom's P_CheckPosition for a box of radius r at (x, y), stopped by the
# mask's lines, after its things gave their verdict: a thing in the way
# ends it at the floor and ceiling of the sector under the point;
# otherwise the lines the box crosses narrow them, until one stops it.
def Sim.fit.at(clear: Bool, +level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32) -> Sim.Fit:
  match clear:
    case False{}:
      Sim.fit.start(False{}, level, x, y)
    case True{}:
      Sim.fit.go(Sim.lines(level, (x - r : U32), (y - r : U32), (x + r : U32), (y + r : U32)), level, x, y, r, mask,
        Sim.fit.start(True{}, level, x, y))

# Doom's P_CheckPosition for the player's box at (x, y).
def Sim.fit(+level: L.Level, +x: U32, +y: U32) -> Sim.Fit:
  Sim.fit.at(Sim.clear(level, x, y, Sim.radius(), H.Thing.you()), level, x, y, Sim.radius(), 1)

def Sim.Fit.ok(f: Sim.Fit) -> Bool:
  Fit{ok, floor, ceil} = f
  ok

# Free: no solid line in the cells the player's box touches crosses the
# box, and no solid thing near it overlaps it. What every move the sim
# takes has passed.
def Sim.free(+level: L.Level, x: U32, y: U32) -> Bool:
  Sim.Fit.ok(Sim.fit(level, x, y))

# Pickups
# -------

# The end of P_TouchSpecialThing: a thing taken is removed, and then
# heard from nobody.
def Sim.touch.took(granted: Maybe<&2, I.Inventory>, counted: Bool, inv: I.Inventory, +id: U32, kind: U32,
  things: H.Things) -> I.Inventory & H.Things:
  match granted:
    case None{}:
      (inv, things)
    case Some{got}:
      (I.Inventory.took(counted, got), H.Things.sounded(H.Things.removed(things, id),
        Sn.Sound.plain(I.Inventory.sound(kind), Sn.Nobody{})))

def Sim.touch.offer(reached: Bool, +id: U32, +kind: U32, counted: Bool, +inv: I.Inventory, things: H.Things) ->
  I.Inventory & H.Things:
  match reached:
    case False{}:
      (inv, things)
    case True{}:
      Sim.touch.took(I.Inventory.grant(kind, inv), counted, inv, id, kind, things)

# P_TouchSpecialThing's reach: the thing's bottom at most 8 under the
# player's feet and at most the player's height over them. A thing
# already gone is not there to take, and a dead toucher takes nothing.
def Sim.touch.alive(m: Maybe<&2, H.Thing>, +id: U32, +kind: U32, counted: Bool, +z: U32, +inv: I.Inventory,
  things: H.Things) -> I.Inventory & H.Things:
  match m:
    case None{}:
      (inv, things)
    case Some{H.Thing{i, k, x, y, +tz, floorz, ceilz, angle, sector, state, tics}}:
      +dz = (tz - z : U32)
      Sim.touch.offer(Bool.and(Bool.not(I.Inventory.dead(inv)),
        Bool.and(F.Fixed.le(dz, Sim.height()), F.Fixed.ge(dz, 4294443008))), id, kind, counted, inv, things)

def Sim.touch.special(hit: Bool, +id: U32, +kind: U32, counted: Bool, +z: U32,
  got: I.Inventory & H.Things) -> I.Inventory & H.Things:
  match hit:
    case False{}:
      got
    case True{}:
      (inv, +things) = got
      Sim.touch.alive(H.Things.get(things, id), id, kind, counted, z, inv, things)

def Sim.touch.stop(stop: Bool, got: I.Inventory & H.Things) -> Sim.Touch:
  (inv, things) = got
  Touch{stop, inv, things}

# Doom's PIT_CheckThing for the player's box at (x, y) with its feet at
# z and a thing near it: a special thing the box overlaps is offered to
# the inventory, and a solid one ends the check.
def Sim.touch.def(d: H.Thing.Def, +id: U32, +tx: U32, +ty: U32, +x: U32, +y: U32, +z: U32,
  got: I.Inventory & H.Things) -> Sim.Touch:
  H.Def{+kind, state, +radius, height, +flags} = d
  +hit = Sim.overlap(F.Fixed.of_map(radius), tx, ty, x, y, Sim.radius())
  Sim.touch.stop(Bool.and(Bool.not(U32.is_zero((flags .&. 2 : U32))), hit),
    Sim.touch.special(Bool.and(Bool.not(U32.is_zero((flags .&. 1 : U32))), hit), id, kind,
      Bool.not(U32.is_zero((flags .&. 8388608 : U32))), z, got))

def Sim.touch.link(link: L.Level.Link, +id: U32, +x: U32, +y: U32, +z: U32, got: I.Inventory & H.Things) ->
  Sim.Touch:
  L.Link{next, +tx, +ty, +kind} = link
  Sim.touch.def(H.Thing.info(kind), id, tx, ty, x, y, z, got)

def Sim.touch.go(ids: List<&2, U32>, st: Sim.Touch, +level: L.Level, +x: U32, +y: U32, +z: U32) ->
  I.Inventory & H.Things:
  match ids st:
    case [] Touch{stop, inv, things}:
      (inv, things)
    case _ Touch{True{}, inv, things}:
      (inv, things)
    case +id <> rest Touch{False{}, inv, things}:
      Sim.touch.go(rest, Sim.touch.link(L.Level.linked.in(L.Level.things_of(level), id), id, x, y, z, (inv, things)),
        level, x, y, z)

# The pickups of the player's position check at (x, y) with its feet at
# z: each special thing near is offered to the inventory in the
# blockmap's order, until a solid thing stops the check; one the grant
# takes is gone, and the things kept keep their names.
def Sim.touch(+level: L.Level, +x: U32, +y: U32, +z: U32, got: I.Inventory & H.Things) ->
  I.Inventory & H.Things:
  Sim.touch.go(Sim.near(level, x, y, Sim.radius()), Sim.touch.stop(False{}, got), level, x, y, z)

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
      Sim.crossings.go(rest, level, ox, oy, x, y, Sim.keep(Bool.and(Sim.crosses(level, ox, oy, x, y, i),
        Bool.not(Sim.member(found, i))), i, found))

def Sim.crossings(+level: L.Level, ox: U32, oy: U32, +x: U32, +y: U32) -> List<&2, U32>:
  Sim.crossings.go(Sim.lines(level, (x - Sim.radius() : U32), (y - Sim.radius() : U32),
    (x + Sim.radius() : U32), (y + Sim.radius() : U32)), level, ox, oy, x, y, [])

def Sim.try_move.fin(go: Bool, p: Player, things: H.Things, x: U32, y: U32, floor: U32, ceil: U32,
  over: List<&2, U32>) -> Sim.Try:
  match go:
    case False{}:
      Try{False{}, p, things}
    case True{}:
      Player{ox, oy, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
      Try{True{}, Player{x, y, z, angle, momx, momy, momz, floor, ceil, viewheight, deltaview, viewz,
        List.append(&2, U32, crossed, over), inv, psprites, hurt}, H.Things.moved(things)}

# The move is taken when the position is free, the opening fits the
# player, the ceiling is high enough from the player's feet, and the
# floor is at most 24 units up; the player's link then heads its cell.
# What the check picked up stays picked up either way.
def Sim.try_move.fit(+p: Player, x: U32, y: U32, touched: I.Inventory & H.Things, f: Sim.Fit,
  over: List<&2, U32>) -> Sim.Try:
  (inv, things) = touched
  Fit{ok, +floor, +ceil} = f
  +z = Player.z(p)
  Sim.try_move.fin(Bool.and(ok, Bool.and(F.Fixed.ge((ceil - floor : U32), Sim.height()),
    Bool.and(F.Fixed.ge((ceil - z : U32), Sim.height()),
      F.Fixed.le((floor - z : U32), Sim.step_up())))), Player.holding(p, inv), things, x, y, floor, ceil, over)

# Doom's P_TryMove: P_CheckPosition touches the things, then checks the
# lines; a move taken adds the special lines it crossed to the player's.
def Sim.try_move(+level: L.Level, things: H.Things, +p: Player, +x: U32, +y: U32) -> Sim.Try:
  Sim.try_move.fit(p, x, y, Sim.touch(level, x, y, Player.z(p), (Player.inv(p), things)), Sim.fit(level, x, y),
    Sim.crossings(level, Player.x(p), Player.y(p), x, y))

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
  Player{+x, +y, z, angle, momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  Sim.stairstep.fin(level, Sim.try_move(level, things, p, x, (y + momy : U32)))

# The remainder of the move, clipped along the wall, becomes the
# momentum and is tried; a failure retries the slide from here.
def Sim.slide.wall.go(+level: L.Level, things: H.Things, +p: Player, m: U32 & U32) -> Sim.Try:
  Player{+x, +y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  (+mx, +my) = m
  Sim.try_move(level, things, Player{x, y, z, angle, mx, my, momz, floorz, ceilz, viewheight, deltaview, viewz,
    crossed, inv, psprites, hurt}, (x + mx : U32), (y + my : U32))

def Sim.slide.wall(left: Bool, +level: L.Level, things: H.Things, +p: Player, +frac: U32, i: U32) ->
  Sim.Try:
  match left:
    case False{}:
      Try{True{}, p, things}
    case True{}:
      Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
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
      Player{+x, +y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
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
def Sim.slide.once(+level: L.Level, things: H.Things, +p: Player) -> Sim.Try:
  Player{+x, +y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  +lx = Sim.lead(x, momx)
  +ly = Sim.lead(y, momy)
  +tx = Sim.trail(x, momx)
  +ty = Sim.trail(y, momy)
  Sim.slide.hit(level, things, p,
    Sim.trace(level, p, lx, ty, (lx + momx : U32), (ty + momy : U32),
      Sim.trace(level, p, tx, ly, (tx + momx : U32), (ly + momy : U32),
        Sim.trace(level, p, lx, ly, (lx + momx : U32), (ly + momy : U32),
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
      Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
      Player{x, y, z, angle, 0, 0, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}
    case False{}:
      Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
      Player{x, y, z, angle, F.Fixed.mul(momx, Sim.decay()), F.Fixed.mul(momy, Sim.decay()),
        momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}

def Sim.crawling(+mom: U32) -> Bool:
  Bool.and(F.Fixed.gt(mom, F.Fixed.neg(Sim.stopspeed())), F.Fixed.lt(mom, Sim.stopspeed()))

def Sim.friction.ground(+cmd: K.Cmd, +p: Player) -> Player:
  K.Cmd{forward, side, turn, buttons} = cmd
  Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
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
      Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
      +xm = Sim.clamp(momx)
      +ym = Sim.clamp(momy)
      Sim.xy.slowed(cmd, Sim.xy.go(2n, level, Xy{False{}, Try{False{}, Player{x, y, z, angle, xm, ym, momz, floorz,
        ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, things}, xm, ym}))

# Doom's P_XYMovement: the momentum, capped, moves the player, in
# halves when large; a blocked move slides; then friction.
def Sim.xy(+level: L.Level, things: H.Things, cmd: K.Cmd, +p: Player) -> Sim.Try:
  Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  Sim.xy.moving(Bool.not(Bool.and(U32.is_zero(momx), U32.is_zero(momy))), level, things, cmd, p)

# The move
# --------

# Doom's P_Thrust: momentum along an angle.
def Sim.thrust(+level: L.Level, p: Player, +angle: U32, +move: U32) -> Player:
  Player{x, y, z, a, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  +sine = L.Level.sine(level)
  +f = A.Angle.fine(angle)
  Player{x, y, z, a, (momx + F.Fixed.mul(move, A.Angle.cos(sine, f)) : U32),
    (momy + F.Fixed.mul(move, A.Angle.sin(sine, f)) : U32), momz, floorz, ceilz, viewheight,
    deltaview, viewz, crossed, inv, psprites, hurt}

# A move key thrusts only on the ground.
def Sim.push(+level: L.Level, +p: Player, +angle: U32, +move: U32) -> Player:
  Bool.pick(Player, Bool.or(U32.is_zero(move), Bool.not(Player.onground(p))), p,
    Sim.thrust(level, p, angle, (move * 2048 : U32)))

# Doom's P_MovePlayer: turn, then thrust forward and sideways.
def Sim.move(+level: L.Level, +cmd: K.Cmd, p: Player) -> Player:
  K.Cmd{forward, side, turn, buttons} = cmd
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  +a = (angle + (turn << 16n) : U32)
  Sim.push(level, Sim.push(level, Player{x, y, z, a, momx, momy, momz, floorz, ceilz, viewheight,
    deltaview, viewz, crossed, inv, psprites, hurt}, a, forward), (a - A.Angle.ang90() : U32), side)

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
  Player{x, y, +z, angle, momx, momy, momz, floorz, +ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  (+vh, dv) = vd
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, vh, dv,
    F.Fixed.min((z + vh + swing : U32), (ceilz - 262144 : U32)), crossed, inv, psprites, hurt}

# The ramp runs for a living player alone: P_CalcHeight leaves a dead
# one's view height and its delta to P_DeathThink, and still bobs the
# eye by what the corpse's momentum left.
def Sim.eye.ramp(live: Bool, +viewheight: U32, +deltaview: U32) -> U32 & U32:
  match live:
    case False{}:
      (viewheight, deltaview)
    case True{}:
      Sim.eye.delta((viewheight + deltaview : U32), deltaview)

def Sim.eye.ground(live: Bool, +p: Player, swing: U32) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, +viewheight, +deltaview, viewz, crossed, inv, psprites, hurt} = p
  Sim.eye.ground.fin(p, swing, Sim.eye.ramp(live, viewheight, deltaview))

# In the air the eye sits at the view height, unbobbed.
def Sim.eye.air(p: Player) -> Player:
  Player{x, y, +z, angle, momx, momy, momz, floorz, ceilz, +viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview,
    (z + viewheight : U32), crossed, inv, psprites, hurt}

def Sim.eye.if(onground: Bool, live: Bool, +p: Player, swing: U32) -> Player:
  match onground:
    case True{}:
      Sim.eye.ground(live, p, swing)
    case False{}:
      Sim.eye.air(p)

# Half of the bob swings the eye on the level's clock, a turn every 20
# tics.
def Sim.eye(+level: L.Level, clock: U32, +p: Player) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  Sim.eye.if(Player.onground(p), Bool.not(Player.dead(p)), p, F.Fixed.mul((Sim.bob(momx, momy) >> 1n : U32),
    A.Angle.sin(L.Level.sine(level), ((409 * clock : U32) .&. 8191 : U32))))

# The vertical move
# -----------------

# Whether the vertical move ends a fall faster than eight units a tic on
# the floor: the landing that dips the view and is heard.
def Sim.lands(p: Player) -> Bool:
  Player{x, y, z, angle, momx, momy, +momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  Bool.and(F.Fixed.le((z + momz : U32), floorz), F.Fixed.lt(momz, F.Fixed.neg((Sim.gravity() << 3n : U32))))

# Below the ceiling: at most 56 under it, no rising momentum.
def Sim.z.ceiling(+z: U32, +momz: U32, +ceilz: U32) -> U32 & U32:
  +hit = F.Fixed.gt((z + Sim.height() : U32), ceilz)
  (Bool.pick(U32, hit, (ceilz - Sim.height() : U32), z),
    Bool.pick(U32, Bool.and(hit, F.Fixed.gt(momz, 0)), 0, momz))

def Sim.z.fin(+p: Player, zm: U32 & U32) -> Player:
  Player{x, y, oz, angle, momx, momy, omomz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  (z, momz) = zm
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}

# On or under the floor the fall ends there, and a landing dips the view
# by an eighth of the momentum; above it gravity pulls, doubled on the
# first airborne tic.
def Sim.z.clip(+p: Player, +z: U32) -> Player:
  Player{x, y, oz, angle, momx, momy, +momz, +floorz, +ceilz, viewheight, +deltaview, viewz, crossed, inv, psprites, hurt} = p
  +floored = F.Fixed.le(z, floorz)
  +falling = F.Fixed.lt(momz, 0)
  +momz2 = Bool.pick(U32, floored, Bool.pick(U32, falling, 0, momz),
    Bool.pick(U32, U32.is_zero(momz), F.Fixed.neg((Sim.gravity() << 1n : U32)),
      (momz - Sim.gravity() : U32)))
  Sim.z.fin(Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight,
    Bool.pick(U32, Sim.lands(p), F.Fixed.sarn(momz, 3n), deltaview), viewz, crossed, inv, psprites, hurt},
    Sim.z.ceiling(Bool.pick(U32, floored, floorz, z), momz2, ceilz))

# A floor risen under the player dips the view by the rise, to recover
# by an eighth of the gap a tic.
def Sim.z.step(+p: Player) -> Player:
  Player{x, y, +z, angle, momx, momy, +momz, +floorz, ceilz, +viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  +below = F.Fixed.lt(z, floorz)
  +vh = Bool.pick(U32, below, (viewheight - (floorz - z) : U32), viewheight)
  Sim.z.clip(Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, vh,
    Bool.pick(U32, below, F.Fixed.sarn((Sim.viewheight() - vh : U32), 3n), deltaview),
    viewz, crossed, inv, psprites, hurt}, (z + momz : U32))

def Sim.z.if(still: Bool, +p: Player) -> Player:
  match still:
    case True{}:
      p
    case False{}:
      Sim.z.step(p)

# Doom's P_ZMovement, run when the player is off the floor or moving
# vertically.
def Sim.z(+p: Player) -> Player:
  Player{x, y, +z, angle, momx, momy, +momz, +floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
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

# Doom's thinkers. A mover is T_VerticalDoor, T_PlatRaise and T_MoveFloor
# in one: a sector's ceiling or floor, a speed, the steps left, the
# whole plan, which a crushed mover starts again, and its sounds. A
# button is a pressed switch waiting to pop back: the side, which of its
# three textures, the texture it showed, and the tics left. A blink is
# T_LightFlash and T_StrobeFlash in one: the tics left at the sector's
# light, its dark and bright levels, the time at each, and whether a time
# is the count or the mask of a random one. A glow is T_Glow: the two
# levels and the way it is going.
type Thinker is Data:
  Mover{sector: U32, ceiling: Bool, speed: U32, steps: List<&2, Sim.Step>, plan: List<&2, Sim.Step>,
    noise: Sim.Noise}
  Button{side: U32, slot: U32, texture: U32, tics: U32}
  Blink{sector: U32, count: U32, dark: U32, bright: U32, darktime: U32, brighttime: U32, random: Bool}
  Glow{sector: U32, dark: U32, bright: U32, down: Bool}

# Everything a tic changes, in one value: the player, the level (its
# sectors' words and its lines' specials), the things alive, the sides'
# texture numbers (top, bottom and middle a side, as the graphics number
# them), the thinkers in the order they run, the random table's index,
# the clock (Doom's leveltime), whether the level has ended, whether
# use was down on the last tic, the sounds the last tic started and
# stopped, in order, M_Random's index, the random numbers no demo
# depends on, and whether the state asks to be built again, which
# P_DeathThink sets as vanilla's PST_REBORN and whoever runs the tics
# answers, since a fresh state comes from the map as loaded.
type State is Data:
  State{player: Player, level: L.Level, things: H.Things, sidetex: V.Vec,
    thinkers: List<&2, Thinker>, rnd: U32, clock: U32, ended: Bool, usedown: Bool,
    sounds: List<&2, Sn.Sound.Event>, mrnd: U32, reborn: Bool}

def State.player(s: State) -> Player:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  player

def State.level(s: State) -> L.Level:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  level

def State.things(s: State) -> H.Things:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  things

def State.sidetex(s: State) -> V.Vec:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  sidetex

def State.thinkers(s: State) -> List<&2, Thinker>:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  thinkers

def State.rnd(s: State) -> U32:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  rnd

def State.clock(s: State) -> U32:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  clock

def State.ended(s: State) -> Bool:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  ended

def State.usedown(s: State) -> Bool:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  usedown

def State.sounds(s: State) -> List<&2, Sn.Sound.Event>:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  sounds

def State.mrnd(s: State) -> U32:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  mrnd

def State.reborn(s: State) -> Bool:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  reborn

# The state with another player, which the player's think leaves.
def State.player.put(s: State, p: Player) -> State:
  State{was, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{p, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}

# The state with a thinker more, last to run.
def State.thinking(s: State, t: Thinker) -> State:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, level, things, sidetex, List.append(&2, Thinker, thinkers, [t]), rnd, clock, ended, usedown, sounds, mrnd, reborn}

# Sounds
# ------

# The state after the tic reports an event: a start draws from M_Random
# as S_StartSound does.
def State.heard(+e: Sn.Sound.Event, s: State) -> State:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, +mrnd, reborn} = s
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown,
    List.append(&2, Sn.Sound.Event, sounds, [e]), Bool.pick(U32, Sn.Sound.Event.draws(e), M.Random.next(mrnd), mrnd),
    reborn}

def State.told.go(events: List<&2, Sn.Sound.Event>, s: State) -> State:
  match events:
    case []:
      s
    case e <> rest:
      State.told.go(rest, State.heard(e, s))

# The state once it has reported what its things were heard doing.
def State.told(s: State) -> State:
  State{player, level, H.Things{tree, count, you, heard}, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State.told.go(heard, State{player, level, H.Things{tree, count, you, []}, sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd, reborn})

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
# time, or for a random count under it.
def Sim.blink.to(+lit: Bool, +sector: U32, +dark: U32, +bright: U32, +darktime: U32, +brighttime: U32,
  +random: Bool, s: State) -> State:
  State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  +time = Bool.pick(U32, lit, darktime, brighttime)
  +i = Bool.pick(U32, random, M.Random.next(rnd), rnd)
  State.thinking(State{player, L.Level.light.put(level, sector, Bool.pick(U32, lit, dark, bright)), things, sidetex,
    thinkers, i, clock, ended, usedown, sounds, mrnd, reborn}, Blink{sector, Bool.pick(U32, random,
    ((M.Random.at(i) .&. time : U32) + 1 : U32), time), dark, bright, darktime, brighttime, random})

def Sim.blink(turn: Bool, +sector: U32, count: U32, dark: U32, +bright: U32, darktime: U32, brighttime: U32,
  random: Bool, +s: State) -> State:
  match turn:
    case False{}:
      State.thinking(s, Blink{sector, count, dark, bright, darktime, brighttime, random})
    case True{}:
      Sim.blink.to(U32.is_eq(Sim.light(s, sector), bright), sector, dark, bright, darktime, brighttime,
        random, s)

# Doom's T_Glow: 8 a tic, and a step that would reach an end is undone
# and turns the glow.
def Sim.glow(+sector: U32, +dark: U32, +bright: U32, +down: Bool, s: State) -> State:
  State{player, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  +light = L.Level.sector.light(level, sector)
  +next = Bool.pick(U32, down, (light - 8 : U32), (light + 8 : U32))
  +turn = Bool.pick(Bool, down, F.Fixed.le(next, dark), F.Fixed.ge(next, bright))
  State.thinking(State{player, L.Level.light.put(level, sector, Bool.pick(U32, turn, light, next)), things, sidetex,
    thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}, Glow{sector, dark, bright, Bool.xor(down, turn)})

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
  Player{x, y, +z, angle, momx, momy, momz, +floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  (held, things) = touched
  Fit{ok, +floor, +ceil} = f
  Try{Sim.fits(floor, ceil, Sim.height()), Player{x, y, Sim.clip(z, floorz, floor, ceil, Sim.height()), angle,
    momx, momy, momz, floor, ceil, viewheight, deltaview, viewz, crossed, held, psprites, hurt}, things}

def Sim.reclip(+level: L.Level, things: H.Things, +p: Player) -> Sim.Try:
  Sim.reclip.fit(p, Sim.touch(level, Player.x(p), Player.y(p), Player.z(p), (Player.inv(p), things)),
    Sim.fit(level, Player.x(p), Player.y(p)))

# A thing clipped again, and whether the mover may go on: a thing that
# no longer fits stops it only when it is shootable, as vanilla's
# PIT_ChangeSector passes over anything else. No map thing is dead or
# dropped, and no E1M1 mover crushes, so nothing is gibbed, removed or
# hurt.
def Sim.reclip.fin(th: H.Thing, +height: U32, +shootable: Bool, f: Sim.Fit) -> Bool & H.Thing:
  H.Thing{id, kind, x, y, +z, +floorz, ceilz, angle, sector, state, tics} = th
  Fit{ok, +floor, +ceil} = f
  (Bool.or(Sim.fits(floor, ceil, height), Bool.not(shootable)),
    H.Thing{id, kind, x, y, Sim.clip(z, floorz, floor, ceil, height), floor, ceil, angle, sector, state, tics})

# A thing's position check: stopped by any solid thing its box overlaps,
# the player's included, and by lines that block monsters as well.
def Sim.reclip.def(d: H.Thing.Def, +level: L.Level, +p: Player, th: H.Thing) -> Bool & H.Thing:
  H.Def{kind, state, +radius, height, +flags} = d
  H.Thing{+id, k, +x, +y, z, floorz, ceilz, angle, sector, st, tics} = th
  +r = F.Fixed.of_map(radius)
  Sim.reclip.fin(H.Thing{id, k, x, y, z, floorz, ceilz, angle, sector, st, tics}, F.Fixed.of_map(height),
    Bool.not(U32.is_zero((flags .&. 4 : U32))),
    Sim.fit.at(Bool.and(Sim.clear(level, x, y, r, id),
      Bool.not(Sim.overlap(Sim.radius(), Player.x(p), Player.y(p), x, y, r))), level, x, y, r, 3))

def Sim.reclip.thing(+level: L.Level, +p: Player, th: H.Thing) -> Bool & H.Thing:
  H.Thing{id, +kind, x, y, z, floorz, ceilz, angle, sector, state, tics} = th
  Sim.reclip.def(H.Thing.info(kind), level, p,
    H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics})

def Sim.change.put(+id: U32, ok: Bool, p: Player, things: H.Things, r: Bool & H.Thing) -> Sim.Try:
  (fits, th) = r
  Try{Bool.and(ok, fits), p, H.Things.put(things, id, Some{th})}

def Sim.change.thing(m: Maybe<&2, H.Thing>, +id: U32, +level: L.Level, ok: Bool, +p: Player, things: H.Things) ->
  Sim.Try:
  match m:
    case None{}:
      Try{ok, p, things}
    case Some{th}:
      Sim.change.put(id, ok, p, things, Sim.reclip.thing(level, p, th))

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

def Sim.change.go(ids: List<&2, U32>, +level: L.Level, t: Sim.Try) -> Sim.Try:
  match ids:
    case []:
      t
    case +id <> rest:
      Sim.change.go(rest, level, Sim.change.one(U32.is_eq(id, H.Thing.you()), id, level, t))

# Whether the player's link goes before a cell's things: before the
# first linked before it, whose id is under its rank.
def Sim.you.before(ids: List<&2, U32>, +you: U32) -> Bool:
  match ids:
    case []:
      True{}
    case h <> rest:
      U32.is_lt(h, you)

def Sim.you.go(ids: List<&2, U32>, first: Bool, +you: U32) -> List<&2, U32>:
  match ids first:
    case [] _:
      [H.Thing.you()]
    case h <> rest True{}:
      H.Thing.you() <> h <> rest
    case h <> +rest False{}:
      h <> Sim.you.go(rest, Sim.you.before(rest, you), you)

# A cell's things, with the player's link among them in the player's
# cell.
def Sim.you.in(here: Bool, +ids: List<&2, U32>, +you: U32) -> List<&2, U32>:
  match here:
    case False{}:
      ids
    case True{}:
      Sim.you.go(ids, Sim.you.before(ids, you), you)

def Sim.change.cells(cells: List<&2, L.Level.Cell>, +geo: L.Level.Geo, +pc: L.Level.Cell, +you: U32) ->
  List<&2, U32>:
  match cells:
    case []:
      []
    case +c <> rest:
      List.append(&2, U32, Sim.you.in(L.Level.cell.is(c, pc), L.Level.cell.things(geo, c), you),
        Sim.change.cells(rest, geo, pc, you))

def Sim.change.box(b: L.Level.Box, +level: L.Level, t: Sim.Try) -> Sim.Try:
  L.Box{+top, +bottom, +left, +right} = b
  Try{ok, +p, +things} = t
  Sim.change.go(Sim.change.cells(Sim.cells(U32.to_nat(F.Fixed.max((right - left + 1 : U32), 0)),
    U32.to_nat(F.Fixed.max((top - bottom + 1 : U32), 0)), left, bottom), L.Level.geo(level),
    L.Level.cell_of(L.Level.blockmap_of(level), Player.x(p), Player.y(p)), H.Things.you(things)), level,
    Try{ok, p, things})

# Doom's P_ChangeSector: the player and every thing linked in the cells
# of the sector's block box, touching the sector or not, clipped again
# in the blockmap's order; whether each that must fit does.
def Sim.change(+level: L.Level, +sector: U32, p: Player, things: H.Things) -> Sim.Try:
  Sim.change.box(L.Level.blockbox(level, sector), level, Try{True{}, p, things})

# The state with a try's player and things, in a level.
def State.moved(t: Sim.Try, level: L.Level, s: State) -> State:
  Try{ok, p, got} = t
  State{player, old, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{p, level, got, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}

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
      State.thinking(s, Mover{sector, ceiling, speed, step <> rest, plan, noise})

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
  State{+player, +level, +things, sidetex, thinkers, rnd, +clock, ended, usedown, sounds, mrnd, reborn} = s
  +was = L.Level.plane(level, sector, ceiling)
  +next = Bool.pick(U32, down, (was - speed : U32), (was + speed : U32))
  +past = Bool.pick(Bool, down, F.Fixed.lt(next, dest), F.Fixed.gt(next, dest))
  +moved = L.Level.plane.put(level, sector, ceiling, Bool.pick(U32, past, dest, next))
  +stop = Bool.pick(U32, past, Bool.pick(U32, down, fell, rose), 0)
  Sim.mover.fitted(Sim.Try.or(Bool.and(ceiling, Bool.not(Bool.or(down, past))),
    Sim.change(moved, sector, player, things)), sector, ceiling, speed, was, past, rest,
    Bool.pick(List<&2, Sim.Step>, past, rest, Travel{down, dest} <> rest), plan, noise,
    Bool.pick(U32, U32.is_zero((clock .&. 7 : U32)), grind, 0), stop, Bool.pick(U32, past, stop, crush),
    State{player, moved, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn})

# Doom's button in P_UpdateSpecials: the tic its count reaches zero the
# side shows its texture again. Vanilla sounds the pop-back from the
# address of the button's origin where it means the origin, and reads a
# place out of the next button's slot: the map's own origin, while that
# slot is free.
def Sim.button(done: Bool, side: U32, slot: U32, texture: U32, tics: U32, s: State) -> State:
  match done:
    case True{}:
      State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
      Sim.sound(Sn.Sound.swtchn(), Sn.Spot{0, 0}, State{player, level, things,
        V.Vec.set(sidetex, (side * 3 + slot : U32), texture), thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn})
    case False{}:
      State.thinking(s, Button{side, slot, texture, (tics - 1 : U32)})

# A thinker's tic. A wait counts down, and the tic it reaches zero
# sounds the mover's wake and does nothing else, as Doom's doors and
# lifts turn. A blink turns on the tic its count runs out.
def Sim.think(t: Thinker, s: State) -> State:
  match t:
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

# Doom's P_RunThinkers: each in turn, in the order they were started,
# the state's list being those kept so far. The things spawned before
# the level's lights and movers, so their tics come first.
def Sim.thinkers.go(todo: List<&2, Thinker>, s: State) -> State:
  match todo:
    case []:
      s
    case t <> rest:
      Sim.thinkers.go(rest, Sim.think(t, s))

def Sim.thinkers(s: State) -> State:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  Sim.thinkers.go(thinkers, State{player, level, H.Things.tics(things), sidetex, [], rnd, clock, ended, usedown, sounds, mrnd, reborn})

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
      Sim.blink.to(False{}, sector, Sim.light.low(s, sector), Sim.light(s, sector), 7, 64, True{}, s)
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

# A state with other things, their ids under count, linked in its
# level's blockmap as they come, the player's link where it was.
def State.populated(+things: List<&2, H.Thing>, +count: U32, s: State) -> State:
  State{player, +level, old, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, H.Thing.linked(level, things, count), H.Things.of(things, count, H.Things.you(old)), sidetex,
    thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}

# The state a level starts in, from the map as loaded, with the player
# at rest at a place, the things spawned with the random numbers they
# draw, and then the lights in sector order. Use counts as down, as
# Doom's G_PlayerReborn leaves it, so a key held since before the level
# does nothing. M_Random's index stands at 64: G_InitNew clears it, and
# the melt that wipes the level in draws once a screen column, 320.
def State.at.spawned(+level: L.Level, place: L.Level.Start, spawn: H.Thing.Spawn) -> State:
  H.Spawn{things, rnd, you} = spawn
  Sim.lights(U32.to_nat(L.Level.nsectors(level)), 0, State.populated(things, L.Level.nthings(level),
    State{Player.at(level, place), level, H.Things.of([], 0, you), L.Level.sidetex(level), [], rnd, 0, False{},
      True{}, [], 64, False{}}))

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
      State{player, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
      State{player, level, things, sidetex, Sim.door.turn(thinkers, sector, L.Level.floor(level, sector)), rnd,
        clock, ended, usedown, sounds, mrnd, reborn}
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
      Sim.keep(Bool.and(U32.is_eq(L.Level.sector.tag(level, s), tag), Bool.not(Sim.moving(thinkers, s))), s,
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
      State{player, +level, things, +sidetex, +thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
      +showed = V.Vec.get(sidetex, (side * 3 + slot : U32))
      Sim.switch.button(Bool.and(again, Bool.not(Sim.pressed.side(thinkers, side))), side, slot, showed,
        Sim.sound(Sn.Sound.swtchn(), Sim.switch.origin(thinkers, level),
          State{player, level, things, V.Vec.set(sidetex, (side * 3 + slot : U32), L.Level.switch(level, showed)),
            thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}))

# Doom's P_ChangeSwitchTexture on the line's front side.
def Sim.switch(again: Bool, line: U32, +s: State) -> State:
  +side = L.Level.line.side(State.level(s), line, 0)
  +slot = Sim.switch.slot(State.level(s), State.sidetex(s), (side * 3 : U32))
  Sim.switch.swap(U32.is_eq(slot, 3), again, side, slot, s)

# A line that works once has no special afterwards.
def Sim.once(line: U32, s: State) -> State:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, L.Level.special.put(level, line, 0), things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}

# Doom's G_ExitLevel: the level ends, and the tic it ends on runs on.
def State.end(s: State) -> State:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, level, things, sidetex, thinkers, rnd, clock, True{}, usedown, sounds, mrnd, reborn}

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

def Sim.use.first.pick(special: Bool, shut: Bool, i: U32, later: Sim.Reach) -> Sim.Reach:
  match special shut:
    case True{} _:
      Special{i}
    case False{} True{}:
      Wall{}
    case False{} False{}:
      later

# Doom's PTR_UseTraverse along the sorted meets: the first special line
# ends the trace whatever its special; a line without one lets it go on
# when its opening is more than nothing.
def Sim.use.first(sorted: List<&2, Sim.Meet>, +level: L.Level) -> Sim.Reach:
  match sorted:
    case []:
      Nothing{}
    case Meet{frac, +i} <> rest:
      Sim.use.first.pick(Bool.not(U32.is_zero(L.Level.special(level, i))),
        Sim.use.shut(level, L.Level.line(level, i)), i, Sim.use.first(rest, level))

def Sim.Meet.frac(m: Sim.Meet) -> U32:
  Meet{frac, line} = m
  frac

# Whether a meet goes before a sorted list's head: nearer than it, or
# the list empty.
def Sim.use.before(+m: Sim.Meet, sorted: List<&2, Sim.Meet>) -> Bool:
  match sorted:
    case []:
      True{}
    case h <> rest:
      U32.is_lt(Sim.Meet.frac(m), Sim.Meet.frac(h))

# A meet into a list sorted by fraction, after its equals, so the first
# gathered of equals stays first, as Doom picks them.
def Sim.use.insert(sorted: List<&2, Sim.Meet>, before: Bool, +m: Sim.Meet) -> List<&2, Sim.Meet>:
  match sorted before:
    case _ True{}:
      m <> sorted
    case [] False{}:
      [m]
    case h <> +rest False{}:
      h <> Sim.use.insert(rest, Sim.use.before(m, rest), m)

def Sim.use.sort(meets: List<&2, Sim.Meet>, +sorted: List<&2, Sim.Meet>) -> List<&2, Sim.Meet>:
  match meets:
    case []:
      sorted
    case +m <> rest:
      Sim.use.sort(rest, Sim.use.insert(sorted, Sim.use.before(m, sorted), m))

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
      Sim.use.hit(Sim.use.first(Sim.use.sort(Sim.meets(level, Player.x(p), Player.y(p),
        (Player.x(p) + 64 * A.Angle.cos(sine, f) : U32), (Player.y(p) + 64 * A.Angle.sin(sine, f) : U32)), []),
        level), p, s)

# Damage
# ------

# Doom's P_Random: the state with its index stepped, and the number
# drawn there.
def Sim.drawn(s: State) -> State & U32:
  State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  +i = M.Random.next(rnd)
  (State{player, level, things, sidetex, thinkers, i, clock, ended, usedown, sounds, mrnd, reborn},
    M.Random.at(i))

# A thing named by a blow: none for nobody, for the player, whose name
# no thing in the population carries, or for a thing since gone.
def Sim.named.of(self: Bool, +things: H.Things, +id: U32) -> Maybe<&2, H.Thing>:
  match self:
    case True{}:
      None{}
    case False{}:
      H.Things.get(things, id)

def Sim.named(m: Maybe<&2, U32>, +things: H.Things) -> Maybe<&2, H.Thing>:
  match m:
    case None{}:
      None{}
    case Some{+id}:
      Sim.named.of(U32.is_eq(id, H.Thing.you()), things, id)

# Doom's A_Pain and A_PlayerScream, the sounds the player's mobj states
# start, heard from the player. A_Fall, which the third death state
# runs, clears a flag P_KillMobj has cleared already.
def Sim.mobj.act(action: H.Thing.Action, s: State) -> State:
  match action:
    case H.Pain{}:
      Sim.sound(Sn.Sound.plpain(), Sn.Thing{H.Thing.you()}, s)
    case H.Scream{}:
      Sim.sound(Sn.Sound.pldeth(), Sn.Thing{H.Thing.you()}, s)
    case other:
      s

# The player's mobj in a state, for that state's tics.
def Player.entering(+state: U32, p: Player) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites,
    Hurt{was, tics, damage, attacker}} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites,
    Hurt{state, H.Thing.Row.tics(H.Thing.row(state)), damage, attacker}}

# Doom's P_SetMobjState for the player's mobj: it enters the state for
# that state's tics and the state's action runs. No state of the
# player's has 0 tics, so none chains into the next.
def Sim.mobj.enter(+state: U32, +s: State) -> State:
  Sim.mobj.act(H.Thing.Row.action(H.Thing.row(state)),
    State.player.put(s, Player.entering(state, State.player(s))))

# The player's mobj some tics further into the state it stands in: one
# for P_MobjThinker's count down, a random 0 to 3 for the shortened
# death P_KillMobj starts.
def Player.counted(+n: U32, p: Player) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites,
    Hurt{state, +tics, damage, attacker}} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites,
    Hurt{state, (tics - n : U32), damage, attacker}}

def Sim.mobj.step(lasting: Bool, out: Bool, +next: U32, +s: State) -> State:
  match lasting out:
    case True{} _:
      s
    case False{} True{}:
      Sim.mobj.enter(next, s)
    case False{} False{}:
      State.player.put(s, Player.counted(1, State.player(s)))

# Doom's P_MobjThinker's state cycle for the player's mobj, which times
# its pain and its death: the standing state lasts, and any other counts
# its tics down and enters the next as they run out.
def Sim.mobj.state(row: Sim.Hurt, +s: State) -> State:
  Hurt{+state, +tics, damage, attacker} = row
  Sim.mobj.step(U32.is_eq(tics, 4294967295), U32.is_eq(tics, 1), H.Thing.Row.next(H.Thing.row(state)), s)

def Sim.mobj.tics(+s: State) -> State:
  Sim.mobj.state(Player.hurt(State.player(s)), s)

# Doom's P_DropWeapon: the ready weapon enters its down state, whose
# A_Lower runs as it does.
def Player.dropped(+sine: V.Vec, +clock: U32, p: Player) -> Player:
  Player{x, y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv,
    Psprites{weapon, flash}, hurt} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv,
    Psprites{Sim.psprite.set(4n, Entering{Some{H.Thing.Weapon.down(H.Thing.pistol())}, weapon}, sine, clock,
      Sim.bob(momx, momy), H.Thing.pistol()), flash}, hurt}

def Sim.drop(+s: State) -> State:
  State.player.put(s, Player.dropped(L.Level.sine(State.level(s)), State.clock(s), State.player(s)))

# The death state's tics, less the random 0 to 3 P_KillMobj takes off.
# Its 10 never reach vanilla's floor of 1.
def Sim.kill.tics(got: State & U32) -> State:
  (+s, drawn) = got
  State.player.put(s, Player.counted((drawn .&. 3 : U32), State.player(s)))

# Doom's P_KillMobj for the player: the weapon drops away and the mobj
# enters its death state, whose tics lose a random 0 to 3. The flags
# vanilla clears leave the sim nothing to do: a dead player takes no
# more damage, since P_DamageMobj asks its health; no mover in either
# map crushes what no longer fits; and the player's own sprite is never
# drawn, so the quartered height and the cleared solid flag have no
# reader. The gib death needs damage past the player's spawn health,
# which nothing here deals.
def Sim.kill(+s: State) -> State:
  Sim.kill.tics(Sim.drawn(Sim.mobj.enter(H.Thing.play.death(), Sim.drop(s))))

def Sim.damage.flinch(flinches: Bool, +s: State) -> State:
  match flinches:
    case False{}:
      s
    case True{}:
      Sim.mobj.enter(H.Thing.play.pain(), s)

# The pain roll: a draw under the player's pain chance of 255, which
# only a draw of 255 fails, sends the mobj into its pain state, where
# the next state's A_Pain is heard three tics on.
def Sim.damage.pain(got: State & U32) -> State:
  (s, +drawn) = got
  Sim.damage.flinch(U32.is_lt(drawn, 255), s)

def Sim.damage.done(dead: Bool, +s: State) -> State:
  match dead:
    case True{}:
      Sim.kill(s)
    case False{}:
      Sim.damage.pain(Sim.drawn(s))

# The end of P_DamageMobj's player branch: the inventory the armour and
# the health left, the damage count grown by what reached the player and
# held at 100, and the blow's source kept as the attacker.
def Player.took(p: Player, inv: I.Inventory, +left: U32, source: Maybe<&2, U32>) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, was, psprites,
    Hurt{state, tics, +damage, old}} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites,
    Hurt{state, tics, U32.min((damage + left : U32), 100), source}}

def Sim.damage.taken(hurt: I.Inventory & U32, source: Maybe<&2, U32>, +s: State) -> State:
  (+inv, +left) = hurt
  Sim.damage.done(I.Inventory.dead(inv),
    State.player.put(s, Player.took(State.player(s), inv, left, source)))

# P_DamageMobj's player branch: the armour takes its share and the
# health the rest, which kills where the health it leaves runs out,
# since vanilla holds the player's health at 0 exactly there. The god
# and skill branches are left out, since no cheat is ported and the game
# is Hurt Me Plenty, and so is the hack for sectors with special 11,
# which neither map carries.
def Sim.damage.player(+damage: U32, source: Maybe<&2, U32>, +s: State) -> State:
  Sim.damage.taken(I.Inventory.hurt(Player.inv(State.player(s)), damage), source, s)

def Sim.blow.thrown(+level: L.Level, p: Player, +angle: U32, +thrust: U32, back: Bool) -> Player:
  match back:
    case False{}:
      Sim.thrust(level, p, angle, thrust)
    case True{}:
      Sim.thrust(level, p, (angle + A.Angle.ang180() : U32), (thrust * 4 : U32))

# Doom's P_DamageMobj's thrust: the blow pushes the player away from the
# inflictor, a hundred times an eighth of a unit a point of damage over
# the player's mass, which is a hundred. A lethal blow under 40 points
# from an inflictor more than 64 units below throws the player the other
# way, four times as hard, on an odd random number, which is drawn only
# where the other three tests pass, as C's && leaves it.
def Sim.blow(+ix: U32, +iy: U32, +iz: U32, +damage: U32, s: State) -> State:
  State{+player, +level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  +rolls = Bool.and(U32.is_lt(damage, 40),
    Bool.and(F.Fixed.gt(damage, I.Inventory.health(Player.inv(player))),
      F.Fixed.gt((Player.z(player) - iz : U32), 4194304)))
  +i = Bool.pick(U32, rolls, M.Random.next(rnd), rnd)
  State{Sim.blow.thrown(level, player, A.Angle.of(L.Level.tanto(level), (Player.x(player) - ix : U32),
      (Player.y(player) - iy : U32)), (damage * 8192 : U32),
      Bool.and(rolls, Bool.not(U32.is_zero((M.Random.at(i) .&. 1 : U32))))),
    level, things, sidetex, thinkers, i, clock, ended, usedown, sounds, mrnd, reborn}

def Sim.damage.hit(m: Maybe<&2, H.Thing>, +damage: U32, source: Maybe<&2, U32>, s: State) -> State:
  match m:
    case None{}:
      Sim.damage.player(damage, source, s)
    case Some{H.Thing{id, kind, +x, +y, +z, floorz, ceilz, angle, sector, state, tics}}:
      Sim.damage.player(damage, source, Sim.blow(x, y, z, damage, s))

def Sim.damage.if(dead: Bool, +damage: U32, inflictor: Maybe<&2, U32>, source: Maybe<&2, U32>, +s: State) ->
  State:
  match dead:
    case True{}:
      s
    case False{}:
      Sim.damage.hit(Sim.named(inflictor, State.things(s)), damage, source, s)

# Doom's P_DamageMobj for the player, the one function everything that
# hurts the player calls: how much, the thing that dealt the blow and
# the thing to blame for it, both absent for the nukage. A blow with an
# inflictor thrusts the player away from it; the armour then takes its
# share of the damage and the player takes the rest. A player already
# dead takes none. The chainsaw's exemption from the thrust waits for a
# ready weapon to read.
def Sim.damage(damage: U32, inflictor: Maybe<&2, U32>, source: Maybe<&2, U32>, +s: State) -> State:
  Sim.damage.if(Player.dead(State.player(s)), damage, inflictor, source, s)

# The sector's special
# --------------------

def Sim.sector.hurt(due: Bool, damage: U32, s: State) -> State:
  match due:
    case False{}:
      s
    case True{}:
      Sim.damage(damage, None{}, None{}, s)

# Doom's P_PlayerInSpecialSector for the specials E1M1 carries: 7 is
# nukage, 5 health every 32 tics of the level's clock. Neither map
# spawns a radiation suit on this skill, so the suit's protection has no
# code.
def Sim.sector.special(special: U32, +clock: U32, s: State) -> State:
  match special:
    case 7:
      Sim.sector.hurt(U32.is_zero((clock .&. 31 : U32)), 5, s)
    case _:
      s

def Sim.sector.floored(floored: Bool, +sector: U32, +clock: U32, +s: State) -> State:
  match floored:
    case False{}:
      s
    case True{}:
      Sim.sector.special(L.Level.sector.special(State.level(s), sector), clock, s)

# P_PlayerThink's call on the sector under the player, which only acts
# while the player's feet are at that sector's floor.
def Sim.sector(+level: L.Level, +clock: U32, +s: State) -> State:
  +sector = L.Level.sector_at(level, Player.x(State.player(s)), Player.y(State.player(s)))
  Sim.sector.floored(U32.is_eq(Player.z(State.player(s)), L.Level.floor(level, sector)), sector, clock, s)

# Dying
# -----

# Doom's ANG5, a turn of 90 degrees over 18.
def Sim.ang5() -> U32:
  59652323

# P_DeathThink's fall: the view sinks a unit a tic to 6 units over the
# floor, with no ramp left in it for P_CalcHeight to run.
def Player.sinking(p: Player) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, +viewheight, deltaview, viewz, crossed, inv, psprites,
    hurt} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz,
    F.Fixed.max(Bool.pick(U32, F.Fixed.gt(viewheight, 393216), (viewheight - F.Fixed.unit() : U32), viewheight),
      393216), 0, viewz, crossed, inv, psprites, hurt}

# P_DeathThink's turn: within 5 degrees of the attacker the facing snaps
# to it and the damage count fades; otherwise the facing turns 5 degrees
# the shorter way round and the count holds.
def Player.turned(+near: Bool, +to: U32, +delta: U32, p: Player) -> Player:
  Player{x, y, z, +angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites,
    +hurt} = p
  Player{x, y, z, Bool.pick(U32, near, to, Bool.pick(U32, U32.is_lt(delta, A.Angle.ang180()),
      (angle + Sim.ang5() : U32), (angle - Sim.ang5() : U32))),
    momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites,
    Bool.pick(Sim.Hurt, near, Sim.Hurt.fade(hurt), hurt)}

# Who the dying view turns to: the attacker, or, with none to turn to,
# its own facing, which leaves the view where it is and fades the count,
# as P_DeathThink's other branch does.
def Sim.death.faced(m: Maybe<&2, H.Thing>, +level: L.Level, +p: Player) -> Player:
  match m:
    case None{}:
      Player.turned(True{}, Player.angle(p), 0, p)
    case Some{H.Thing{id, kind, +x, +y, z, floorz, ceilz, angle, sector, state, tics}}:
      +to = A.Angle.of(L.Level.tanto(level), (x - Player.x(p) : U32), (y - Player.y(p) : U32))
      +delta = (to - Player.angle(p) : U32)
      Player.turned(Bool.or(U32.is_lt(delta, Sim.ang5()), U32.is_gt(delta, F.Fixed.neg(Sim.ang5()))), to, delta, p)

# A press of use asks for the level again: Doom's PST_REBORN, which
# G_DoReborn answers outside the playsim by loading the level, and which
# holds until it is answered.
def Sim.death.asked(use: Bool, s: State) -> State:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, Bool.or(reborn, use)}

# Doom's P_DeathThink: the player sprites move, the view sinks and is
# worked out again, the facing turns to the attacker, and use asks for
# the level again. Nothing else of P_PlayerThink runs: no move, no
# sector special, no use of a line and no counters, so the damage count
# fades here alone.
def Sim.death(+level: L.Level, +clock: U32, use: Bool, +s: State) -> State:
  Sim.death.asked(use, State.player.put(s, Sim.death.faced(
    Sim.named(Sim.Hurt.attacker(Player.hurt(State.player(s))), State.things(s)), level,
    Sim.eye(level, clock, Player.sinking(Sim.psprites(level, clock, State.player(s)))))))

# The tic
# -------

# Use acts on the tic it goes down, not while it is held.
def Sim.pressed(cmd: K.Cmd, usedown: Bool) -> Bool:
  Bool.and(Bool.not(usedown), K.Cmd.use(cmd))

# The player as moved, at the height, floor and ceiling a mover left,
# holding what its re-clip picked up and what its mobj's state left, the
# lines it crossed fired and forgotten.
def Player.stood(moved: Player, +q: Player) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, was} = moved
  Player{x, y, Player.z(q), angle, momx, momy, momz, Player.floorz(q), Player.ceilz(q), viewheight,
    deltaview, viewz, [], Player.inv(q), psprites, Player.hurt(q)}

# What a live tic keeps of the state it began with, whatever the
# thinkers did: the geometry, so no tic writes a wall, and the place the
# movement left the player, so no mover pushes the player sideways.
def Sim.tic.kept(geo: L.Level.Geo, moved: Player, clock: U32, use: Bool, +after: State) -> State:
  State{Player.stood(moved, State.player(after)), L.Level{geo, L.Level.sectors(State.level(after)), L.Level.specials(State.level(after))},
    State.things(after), State.sidetex(after), State.thinkers(after), State.rnd(after), (clock + 1 : U32),
    State.ended(after), use, State.sounds(after), State.mrnd(after), State.reborn(after)}

# P_PlayerThink's counters, the damage count's fade among them.
def Sim.counters(p: Player) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed,
    I.Inventory.tic(inv), psprites, Sim.Hurt.fade(hurt)}

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
# began with, whose geometry the wall law reads.
def Sim.mobj(cmd: K.Cmd, +level: L.Level, +s: State) -> State:
  State.moved(Sim.mobj.z(Sim.xy(level, State.things(s), cmd, State.player(s))), State.level(s), s)

# Doom's P_PlayerThink for a living player, in its order: the move, the
# eye, the sector's special, use on the press, the player sprites and
# the counters.
def Sim.player.live(+cmd: K.Cmd, +level: L.Level, +clock: U32, press: Bool, +s: State) -> State:
  +walked = State.player.put(s, Sim.eye(level, clock, Sim.move(level, cmd, State.player(s))))
  +acted = Sim.use(press, Sim.sector(level, clock, walked))
  State.player.put(acted, Sim.counters(Sim.psprites(level, clock, State.player(acted))))

# Doom's P_PlayerThink: a dead player thinks of dying alone.
def Sim.player(dead: Bool, +cmd: K.Cmd, +level: L.Level, +clock: U32, usedown: Bool, s: State) -> State:
  match dead:
    case True{}:
      Sim.death(level, clock, K.Cmd.use(cmd), s)
    case False{}:
      Sim.player.live(cmd, level, clock, Sim.pressed(cmd, usedown), s)

# One tic in Doom's order: the player thinks, its mobj moves, the lines
# that movement crossed fire, the mobj goes through its own states, the
# things go through theirs, the thinkers run in the order they were
# started, the clock counts. The tic's sounds start from none. An ended
# level stands still: no tic runs, so its sounds stay the last live
# tic's, and whoever gathers sounds tic by tic passes over it.
def Sim.tic(+cmd: K.Cmd, s: State) -> State:
  match s:
    case State{player, level, things, sidetex, thinkers, rnd, clock, True{}, usedown, sounds, mrnd, reborn}:
      State{player, level, things, sidetex, thinkers, rnd, clock, True{}, usedown, sounds, mrnd, reborn}
    case State{+player, L.Level{+geo, sectors, specials}, things, sidetex, thinkers, rnd, +clock, False{}, +usedown, sounds, mrnd, reborn}:
      +level = {L.Level{geo, sectors, specials} : L.Level}
      +went = Sim.mobj(cmd, level, Sim.player(Player.dead(player), cmd, level, clock, usedown,
        State{player, level, things, sidetex, thinkers, rnd, clock, False{}, usedown, [], mrnd, reborn}))
      Sim.tic.kept(geo, State.player(went), clock, K.Cmd.use(cmd), State.told(Sim.thinkers(Sim.mobj.tics(
        Sim.cross(Player.crossed(State.player(went)), went)))))

# A tic for each command of the list, in order: a demo.
def Sim.replay(script: List<&2, K.Cmd>, s: State) -> State:
  match script:
    case []:
      s
    case cmd <> rest:
      Sim.replay(rest, Sim.tic(cmd, s))
