# The playsim for one player among things: Doom's P_MovePlayer,
# P_CalcHeight, P_MovePsprites, P_XYMovement, P_TryMove,
# P_CheckPosition, P_SlideMove and P_ZMovement, as pure functions of the
# level, the things, the tic command and the player, and the tic that
# maps one state of the level to the next, with the sounds that tic
# starts and stops where vanilla calls S_StartSound and S_StopSound.
# The player can be hurt and killed: P_DamageMobj, P_KillMobj,
# P_PlayerInSpecialSector and P_DeathThink, which asks for the level
# again as vanilla's PST_REBORN does.
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

# What a blow leaves on the player, four counts in a vector as the
# powers are: the row of the mobj state its own sprite would show, which
# times its pain and death sounds, the tics left in that row, the damage
# count the palette and the face read, and who hit last, the player's own
# name for a blow from nobody or from the player itself, which
# P_DeathThink treats alike.
def Sim.hurt.state() -> U32:
  0

def Sim.hurt.tics() -> U32:
  1

def Sim.hurt.damage() -> U32:
  2

def Sim.hurt.attacker() -> U32:
  3

# Doom's player->refire, how many shots the held attack has taken: in
# the same vector, since a record's width is a budget the whole program
# shares (docs/bend.md).
def Sim.hurt.refire() -> U32:
  4

# Doom's mobj and player_t for one player: the position with its height,
# the angle, the momentum, the floor and ceiling under it, the view
# height and its delta, the eye's height, the special lines this tic's
# moves have crossed, in the order they fire, the inventory, the player
# sprites, and what damage has left.
type Player is Data:
  Player{x: U32, y: U32, z: U32, angle: U32, momx: U32, momy: U32, momz: U32,
    floorz: U32, ceilz: U32, viewheight: U32, deltaview: U32, viewz: U32, crossed: List<&2, U32>,
    inv: I.Inventory, psprites: Psprites, hurt: V.Vec}

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

# The player's mobj at rest and unhurt, as P_SpawnPlayer and
# G_PlayerReborn leave it: its standing state, which lasts.
def Sim.Hurt.start() -> V.Vec:
  V.Vec.of_list([H.Thing.play(), H.Thing.Row.tics(H.Thing.row(H.Thing.play())), 0, H.Thing.you(), 0], 5)

def Sim.Hurt.state(+h: V.Vec) -> U32:
  V.Vec.get(h, Sim.hurt.state())

def Sim.Hurt.tics(+h: V.Vec) -> U32:
  V.Vec.get(h, Sim.hurt.tics())

def Sim.Hurt.attacker(+h: V.Vec) -> U32:
  V.Vec.get(h, Sim.hurt.attacker())

def Sim.Hurt.refire(+h: V.Vec) -> U32:
  V.Vec.get(h, Sim.hurt.refire())

# The damage count fades by one a tic, in P_PlayerThink's counters and
# in P_DeathThink.
def Sim.Hurt.damage(+h: V.Vec) -> U32:
  V.Vec.get(h, Sim.hurt.damage())

def Sim.Hurt.fade(+h: V.Vec) -> V.Vec:
  V.Vec.set(h, Sim.hurt.damage(),
    (Sim.Hurt.damage(h) - I.Inventory.on(Sim.Hurt.damage(h)) : U32))

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

def Player.hurt(+p: Player) -> V.Vec:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  hurt

# Doom's PST_DEAD, which P_PlayerThink and P_CalcHeight ask of the
# player and P_TouchSpecialThing of a toucher.
def Player.dead(+p: Player) -> Bool:
  I.Inventory.dead(Player.inv(p))

# Doom's weaponinfo[player->readyweapon]: the weapon in the player's
# hands, which the status bar counts ammo for. The pistol until a weapon
# can be chosen.
def Player.ready(+p: Player) -> H.Thing.Weapon:
  H.Thing.pistol()

# The player carrying another wound.
def Player.hurting(p: Player, hurt: V.Vec) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, was} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}

# The player showing some sprites.
def Player.showing(p: Player, shown: Psprites) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, shown, hurt}

# Doom's player->refire: how many shots the held attack has taken.
def Player.refire(+p: Player) -> U32:
  Sim.Hurt.refire(Player.hurt(p))

# The player with another count of shots taken.
def Player.firing(+p: Player, shots: U32) -> Player:
  Player.hurting(p, V.Vec.set(Player.hurt(p), Sim.hurt.refire(), shots))

# The player holding an inventory.
def Player.holding(p: Player, held: I.Inventory) -> Player:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, held, psprites, hurt}

# On the ground: at or below the floor.
def Player.onground(+p: Player) -> Bool:
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
  F.Fixed.le(z, floorz)

# The face
# --------

# ST_updateFaceWidget's statics and ST_initData's, in one vector as the
# wound is, since a record's width is a budget the whole program shares
# (docs/bend.md): the index of the face w_faces draws, the tics that
# face has left, the priority of whatever put it there, the health
# ST_Ticker saw on the tic before, the count of tics fire has been held,
# and the weapons owned when the grin last looked. The two counts that
# start below zero hold the word C's -1 is, so its arithmetic carries
# over unchanged. M_Random's index shares the vector rather than a field
# of its own, for the same budget: the state has no word to spare, and
# ST_Ticker draws from it for the face's glance.
def Sim.face.index() -> U32:
  0

def Sim.face.count() -> U32:
  1

def Sim.face.priority() -> U32:
  2

def Sim.face.oldhealth() -> U32:
  3

def Sim.face.lastattack() -> U32:
  4

def Sim.face.weapons() -> U32:
  5

def Sim.face.mrnd() -> U32:
  6

# ST_initData at a fresh game, with M_Random's index where the caller
# says: the face index, its count and the priority are what the program
# started with, the health seen last is -1, and the weapons owned are
# the ones G_PlayerReborn hands out.
def Sim.Face.start(+mrnd: U32) -> V.Vec:
  V.Vec.of_list([0, 0, 0, 4294967295, 4294967295, I.Inventory.weapons(I.Inventory.start()), mrnd], 7)

def Sim.Face.index(+f: V.Vec) -> U32:
  V.Vec.get(f, Sim.face.index())

def Sim.Face.count(+f: V.Vec) -> U32:
  V.Vec.get(f, Sim.face.count())

def Sim.Face.mrnd(+f: V.Vec) -> U32:
  V.Vec.get(f, Sim.face.mrnd())

# The vector once a sound has drawn its pitch from M_Random, and as it
# was where that sound drew none.
def Sim.Face.drew(draws: Bool, +f: V.Vec) -> V.Vec:
  match draws:
    case False{}:
      f
    case True{}:
      V.Vec.set(f, Sim.face.mrnd(), M.Random.next(Sim.Face.mrnd(f)))

# Doom's ST_calcPainOffset: the first of the eight faces of the pain
# level a health falls in, five levels over 101 points. Its static cache
# answers the same offset for the same health, so nothing is kept for
# it.
def Sim.face.pain(+health: U32) -> U32:
  ((100 - U32.min(health, 100)) * 5 / 101 * 8 : U32)

def Sim.face.put(+priority: U32, +index: U32, +count: U32, f: V.Vec) -> V.Vec:
  V.Vec.set(V.Vec.set(V.Vec.set(f, Sim.face.priority(), priority), Sim.face.index(), index),
    Sim.face.count(), count)

# The face a stage chose where its test passed, and the one standing
# where it did not.
def Sim.face.chose(take: Bool, +priority: U32, +index: U32, +count: U32, +f: V.Vec) -> V.Vec:
  match take:
    case False{}:
      f
    case True{}:
      Sim.face.put(priority, index, count, f)

# A stage runs while nothing of a higher priority holds the face.
def Sim.face.under(+f: V.Vec, +priority: U32) -> Bool:
  U32.is_lt(V.Vec.get(f, Sim.face.priority()), priority)

# ST_DEADFACE, chosen afresh every tic the player has no health.
def Sim.face.dead(+health: U32, +f: V.Vec) -> V.Vec:
  Sim.face.chose(Bool.and(Sim.face.under(f, 10), U32.is_zero(health)), 9, 41, 1, f)

def Sim.face.grin.took(grins: Bool, +weapons: U32, +health: U32, +f: V.Vec) -> V.Vec:
  match grins:
    case False{}:
      f
    case True{}:
      V.Vec.set(Sim.face.put(8, (Sim.face.pain(health) + 6 : U32), 70, f), Sim.face.weapons(), weapons)

# ST_EVILGRINOFFSET for ST_EVILGRINCOUNT tics: while the pickup flash is
# on and the weapons owned differ from the ones the grin last looked at,
# which it then remembers. A flash that is out leaves them unlooked at,
# so a weapon taken while a higher priority holds the face is grinned at
# as soon as the flash allows.
def Sim.face.grin(+bonus: U32, +weapons: U32, +health: U32, +f: V.Vec) -> V.Vec:
  Sim.face.grin.took(Bool.and(Sim.face.under(f, 9), Bool.and(Bool.not(U32.is_zero(bonus)),
    Bool.not(U32.is_eq(V.Vec.get(f, Sim.face.weapons()), weapons)))), weapons, health, f)

# Vanilla's ouch test, with the bug it still carries: the subtraction is
# the wrong way round, so the face winces at a health that has RISEN by
# more than ST_MUCHPAIN since the tic before. C compares signed, which
# adding the twenty to the older health says in words, and the -1 of the
# first tic wraps to 19 exactly as C's arithmetic leaves it.
def Sim.face.ouch(+health: U32, +oldhealth: U32) -> Bool:
  U32.is_lt((oldhealth + 20 : U32), health)

# The side the face turns: an attacker within ANG45 of dead ahead takes
# the rampage face instead of a turn.
def Sim.face.turn(+diff: U32, right: Bool, +health: U32) -> U32:
  (Sim.face.pain(health) + Bool.pick(U32, U32.is_lt(diff, A.Angle.ang45()), 7,
    (3 + Bool.to_u32(Bool.not(right)) : U32)) : U32)

# ST_updateFaceWidget's turn, confusing as its own comment says it is:
# the angle to the attacker against the player's facing, the difference
# taken the way round that keeps it positive, and the side read off
# whether that difference passed ANG180.
def Sim.face.wince(gt: Bool, +bad: U32, +facing: U32, +health: U32) -> U32:
  match gt:
    case True{}:
      +diff = (bad - facing : U32)
      Sim.face.turn(diff, U32.is_gt(diff, A.Angle.ang180()), health)
    case False{}:
      +diff = (facing - bad : U32)
      Sim.face.turn(diff, Bool.not(U32.is_gt(diff, A.Angle.ang180())), health)

def Sim.face.hit.index(ouch: Bool, +bad: U32, +facing: U32, +health: U32) -> U32:
  match ouch:
    case True{}:
      (Sim.face.pain(health) + 5 : U32)
    case False{}:
      Sim.face.wince(U32.is_gt(bad, facing), bad, facing, health)

def Sim.face.hit.at(m: Maybe<&2, H.Thing>, +level: L.Level, +p: Player, +health: U32, +oldhealth: U32,
  +f: V.Vec) -> V.Vec:
  match m:
    case None{}:
      f
    case Some{H.Thing{id, kind, +x, +y, z, floorz, ceilz, angle, sector, state, tics, momz}}:
      Sim.face.put(7, Sim.face.hit.index(Sim.face.ouch(health, oldhealth),
        A.Angle.of(L.Level.tanto(level), (x - Player.x(p) : U32), (y - Player.y(p) : U32)),
        Player.angle(p), health), 35, f)

# The thing the face winces at: the wound's attacker, unless the stage
# does not run or the attacker is the player's own mobj, which is how
# this sim says nobody hit.
def Sim.face.attacker(runs: Bool, +things: H.Things, +p: Player) -> Maybe<&2, H.Thing>:
  match runs:
    case False{}:
      None{}
    case True{}:
      H.Things.get(things, Sim.Hurt.attacker(Player.hurt(p)))

# "Being attacked": a damage count with somebody to blame turns the face
# that way for ST_TURNCOUNT tics, or puts up the ouch face.
def Sim.face.hit(+level: L.Level, +things: H.Things, +p: Player, +health: U32, +oldhealth: U32,
  +f: V.Vec) -> V.Vec:
  Sim.face.hit.at(Sim.face.attacker(Bool.and(Sim.face.under(f, 8),
    Bool.and(Bool.not(U32.is_zero(Sim.Hurt.damage(Player.hurt(p)))),
      Bool.not(U32.is_eq(Sim.Hurt.attacker(Player.hurt(p)), H.Thing.you())))), things, p),
    level, p, health, oldhealth, f)

def Sim.face.own.at(runs: Bool, ouch: Bool, +health: U32, +f: V.Vec) -> V.Vec:
  match runs ouch:
    case False{} _:
      f
    case True{} True{}:
      Sim.face.put(7, (Sim.face.pain(health) + 5 : U32), 35, f)
    case True{} False{}:
      Sim.face.put(6, (Sim.face.pain(health) + 7 : U32), 35, f)

# "Getting hurt because of your own damn stupidity": a damage count with
# nobody to blame, which the nukage leaves, takes the ouch face or the
# rampage face.
def Sim.face.own(+damage: U32, +health: U32, +oldhealth: U32, +f: V.Vec) -> V.Vec:
  Sim.face.own.at(Bool.and(Sim.face.under(f, 7), Bool.not(U32.is_zero(damage))),
    Sim.face.ouch(health, oldhealth), health, f)

def Sim.face.rampage.due(due: Bool, +last: U32, +health: U32, +f: V.Vec) -> V.Vec:
  match due:
    case False{}:
      V.Vec.set(f, Sim.face.lastattack(), last)
    case True{}:
      Sim.face.put(5, (Sim.face.pain(health) + 7 : U32), 1, V.Vec.set(f, Sim.face.lastattack(), 1))

def Sim.face.rampage.count(first: Bool, +last: U32, +health: U32, +f: V.Vec) -> V.Vec:
  match first:
    case True{}:
      V.Vec.set(f, Sim.face.lastattack(), 70)
    case False{}:
      Sim.face.rampage.due(U32.is_zero((last - 1 : U32)), (last - 1 : U32), health, f)

def Sim.face.rampage.held(fires: Bool, +last: U32, +health: U32, +f: V.Vec) -> V.Vec:
  match fires:
    case False{}:
      V.Vec.set(f, Sim.face.lastattack(), 4294967295)
    case True{}:
      Sim.face.rampage.count(U32.is_eq(last, 4294967295), last, health, f)

def Sim.face.rampage.runs(runs: Bool, +attack: Bool, +health: U32, +f: V.Vec) -> V.Vec:
  match runs:
    case False{}:
      f
    case True{}:
      Sim.face.rampage.held(attack, V.Vec.get(f, Sim.face.lastattack()), health, f)

# ST_RAMPAGEDELAY tics of held fire and the face grimaces, once a tic
# from then on. Vanilla's priority test wraps the count as well as the
# face, so a stage above this one stops it running at all, and a tic
# with fire up clears it.
def Sim.face.rampage(+attack: Bool, +health: U32, +f: V.Vec) -> V.Vec:
  Sim.face.rampage.runs(Sim.face.under(f, 6), attack, health, f)

def Sim.face.glance.at(timed: Bool, +rnd: U32, +health: U32, +f: V.Vec) -> V.Vec:
  match timed:
    case False{}:
      f
    case True{}:
      Sim.face.put(0, (Sim.face.pain(health) + (rnd % 3) : U32), 17, f)

# The idle glance: with the face's count run out, one of the pain
# level's three straight faces, chosen by the tic's own M_Random draw,
# for ST_STRAIGHTFACECOUNT tics.
def Sim.face.glance(+rnd: U32, +health: U32, +f: V.Vec) -> V.Vec:
  Sim.face.glance.at(U32.is_zero(Sim.Face.count(f)), rnd, health, f)

def Sim.face.ticked(+f: V.Vec) -> V.Vec:
  V.Vec.set(f, Sim.face.count(), (Sim.Face.count(f) - 1 : U32))

# ST_Ticker's last line: the health the next tic's ouch test looks back
# at.
def Sim.face.seen(+health: U32, f: V.Vec) -> V.Vec:
  V.Vec.set(f, Sim.face.oldhealth(), health)

# Doom's ST_updateFaceWidget: each priority in its order, dead first,
# then the grin at a weapon picked up, the wince toward whoever hit, the
# pain of a blow with nobody to blame, the grimace of held fire and, if
# the face standing has timed out, the idle glance; then the face's
# count comes down by one. Invulnerability has no stage: this game has
# no cheat and no sphere, so vanilla's test there is never true.
def Sim.face.widget(+attack: Bool, +level: L.Level, +things: H.Things, +p: Player, +rnd: U32, +health: U32,
  +oldhealth: U32, f: V.Vec) -> V.Vec:
  Sim.face.ticked(Sim.face.glance(rnd, health, Sim.face.rampage(attack, health,
    Sim.face.own(Sim.Hurt.damage(Player.hurt(p)), health, oldhealth,
      Sim.face.hit(level, things, p, health, oldhealth,
        Sim.face.grin(I.Inventory.bonus(Player.inv(p)), I.Inventory.weapons(Player.inv(p)), health,
          Sim.face.dead(health, f)))))))

# The rest of ST_Ticker once M_Random has been drawn: the face widget
# over the number that draw left, then the health the next tic's ouch
# test looks back at.
def Sim.face.tic(+attack: Bool, +level: L.Level, +things: H.Things, +p: Player, +f: V.Vec) -> V.Vec:
  Sim.face.seen(I.Inventory.health(Player.inv(p)),
    Sim.face.widget(attack, level, things, p, M.Random.at(Sim.Face.mrnd(f)),
      I.Inventory.health(Player.inv(p)), V.Vec.get(f, Sim.face.oldhealth()), f))

# The weapon's rows
# -----------------

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

# Doom's P_SetupPsprites' first half: no sprite shows.
def Psprites.none() -> Psprites:
  Psprites{Psprite{None{}, 0, 0, 0}, Psprite{None{}, 0, 0, 0}}

# Doom's player->extralight, the light a muzzle flash lends the whole
# view: the flash sprite's row says it. Vanilla sets it from A_Light0,
# A_Light1 and A_Light2, which sit on flash states alone and run as
# those states are entered, so what it holds between tics is exactly the
# resident flash row's light, and no field keeps it.
def Psprite.light(psp: Psprite) -> U32:
  match psp:
    case Psprite{None{}, tics, sx, sy}:
      0
    case Psprite{Some{+state}, tics, sx, sy}:
      H.Thing.Row.light(H.Thing.row(state))

def Psprites.light(ps: Psprites) -> U32:
  Psprites{weapon, flash} = ps
  Psprite.light(flash)

# Doom's player->extralight.
def Player.extralight(+p: Player) -> U32:
  Psprites.light(Player.psprites(p))

def Player.at.fin(+x: U32, +y: U32, angle: U32, +floor: U32, ceil: U32) -> Player:
  Player{x, y, floor, angle, 0, 0, 0, floor, ceil, Sim.viewheight(), 0,
    (floor + Sim.viewheight() : U32), [], I.Inventory.start(), Psprites.none(), Sim.Hurt.start()}

def Player.at(+level: L.Level, s: L.Level.Start) -> Player:
  L.Start{+x, +y, angle} = s
  +sector = L.Level.sector_at(level, x, y)
  Player.at.fin(x, y, angle, L.Level.floor(level, sector), L.Level.ceil(level, sector))

# The player at the level's start, on its floor, its eye at rest, with
# the inventory Doom's G_PlayerReborn gives and no weapon showing yet:
# the state brings the pistol up, as P_SetupPsprites does.
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

# Doom's ML_TWOSIDED: the flag that says a line has an opening at all.
def Sim.twosided(+line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, +flags, front, back} = line
  Bool.not(U32.is_zero((flags .&. 4 : U32)))

# Doom's P_LineOpening leaves no opening in a line with one side. A line
# flagged two-sided with no back sector is one, and neither E1M1 has
# one, so vanilla's stale opening after such a line is never read.
def Sim.shut(+level: L.Level, +line: L.Level.Line) -> Bool:
  L.Line{x1, y1, x2, y2, flags, front, +back} = line
  Bool.or(U32.is_eq(back, L.Level.none()),
    F.Fixed.le((Sim.open_top(level, line) - Sim.open_bottom(level, line) : U32), 0))

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
  H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz} = th
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
  H.Thing{id, k, +tx, +ty, tz, floorz, ceilz, angle, sector, st, tics, momz} = th
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
    case Some{H.Thing{id, +kind, tx, ty, tz, floorz, ceilz, angle, sector, state, tics, momz}}:
      Sim.touch.def(H.Thing.info(kind), H.Thing{id, kind, tx, ty, tz, floorz, ceilz, angle, sector, state, tics, momz}, x, y,
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

# P_TouchSpecialThing's dead toucher, which can happen with a sliding
# corpse: it takes nothing, whatever it is met by.
def Sim.touch.live(live: Bool, ids: List<&2, U32>, +x: U32, +y: U32, +z: U32, +bm: L.Level.Blockmap,
  got: I.Inventory & H.Things) -> I.Inventory & H.Things:
  match live:
    case False{}:
      got
    case True{}:
      Sim.touch.go(ids, x, y, z, bm, got)

# The pickups of the player's position check with its box at (x, y):
# each special thing met before the one that stops the box is offered to
# the inventory, in the blockmap's order; one the grant takes is removed,
# and the things kept keep their ids.
def Sim.touch(+level: L.Level, things: H.Things, +p: Player, x: U32, y: U32, met: Sim.Met) ->
  I.Inventory & H.Things:
  Met{before, hit} = met
  Sim.touch.live(Bool.not(Player.dead(p)), before, x, y, Player.z(p), L.Level.blockmap_of(level),
    (Player.inv(p), things))

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
  H.Things.link(H.Things.unlink(things, L.Level.blockmap_of(level), False{}, H.Things.you(things), ox, oy,
    L.Level.sector_at(level, ox, oy)), L.Level.blockmap_of(level), False{}, H.Things.you(things), x, y,
    L.Level.sector_at(level, x, y))

def Sim.try_move.fin(go: Bool, +level: L.Level, p: Player, things: H.Things, +x: U32, +y: U32, floor: U32,
  ceil: U32, over: List<&2, U32>) -> Sim.Try:
  match go:
    case False{}:
      Try{False{}, p, things}
    case True{}:
      Player{ox, oy, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
      Try{True{}, Player{x, y, z, angle, momx, momy, momz, floor, ceil, viewheight, deltaview, viewz,
        List.append(&2, U32, crossed, over), inv, psprites, hurt}, Sim.relink(level, things, ox, oy, x, y)}

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

# Doom's trace: the ray P_PathTraverse walks, from its origin nudged off
# a cell's edge along its whole length. A visitor that must place
# something on the ray reads it, as PTR_ShootTraverse does.
type Sim.Trace is Data:
  Trace{x: U32, y: U32, dx: U32, dy: U32}

def Sim.trace.of(+bm: L.Level.Blockmap, +x1: U32, +y1: U32, +x2: U32, +y2: U32) -> Sim.Trace:
  L.Blockmap{words, +ox, +oy, cols, rows} = bm
  +tx = Sim.nudge(x1, ox)
  +ty = Sim.nudge(y1, oy)
  Trace{tx, ty, (x2 - tx : U32), (y2 - ty : U32)}

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
  tr: Sim.Trace, +x2: U32, +y2: U32) -> List<&2, Sim.Meet>:
  L.Blockmap{words, +ox, +oy, cols, rows} = bm
  Trace{+tx, +ty, tdx, tdy} = tr
  Sim.meets.sort(Sim.meets.go(Sim.ray(ox, oy, tx, ty, x2, y2), [], lines, things, level, ts, p, tx, ty,
    tdx, tdy), [])

# Doom's P_PathTraverse intercepts: what the trace meets in the cells it
# crosses, gathered in the walk's order and sorted by distance. The
# mobjs come from the population, where a move, a spawn and a removal
# write their links.
def Sim.meets(+level: L.Level, ts: H.Things, p: Player, lines: Bool, things: Bool, x1: U32, y1: U32, +x2: U32,
  +y2: U32) -> List<&2, Sim.Meet>:
  Sim.meets.at(L.Level.blockmap_of(level), level, ts, p, lines, things,
    Sim.trace.of(L.Level.blockmap_of(level), x1, y1, x2, y2), x2, y2)

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
def Sim.slide.once(+level: L.Level, +things: H.Things, +p: Player) -> Sim.Try:
  Player{+x, +y, z, angle, +momx, +momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = p
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
# order, everything ST_Ticker and M_Random keep outside the playsim
# (M_Random's index, the random numbers no demo depends on, and the
# status bar face's counters, all in one vector as Sim.Face lays it
# out), and whether the state asks to be built again, which P_DeathThink
# sets as vanilla's PST_REBORN and whoever runs the tics answers, since
# a fresh state comes from the map as loaded.
type State is Data:
  State{player: Player, level: L.Level, things: H.Things, sidetex: V.Vec,
    thinkers: Thinkers, rnd: U32, clock: U32, ended: Bool, usedown: Bool,
    sounds: List<&2, Sn.Sound.Event>, mrnd: V.Vec, reborn: Bool}

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

def State.thinkers.of(s: State) -> Thinkers:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  thinkers

# The thinkers in the order they were started.
def State.thinkers(s: State) -> List<&2, Thinker>:
  State{player, level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  List.append(&2, Thinker, List.reverse(&2, Thinker, ran), due)

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

# ST_Ticker's and M_Random's own state, which Sim.Face lays out.
def State.face(s: State) -> V.Vec:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  mrnd

def State.mrnd(s: State) -> U32:
  Sim.Face.mrnd(State.face(s))

def State.reborn(s: State) -> Bool:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  reborn

# The state with another player, which the player's think leaves.
def State.player.put(s: State, p: Player) -> State:
  State{was, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{p, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}

# The state with a thinker started, last to run.
def State.thinking(s: State, t: Thinker) -> State:
  State{player, level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, level, things, sidetex, Thinkers{ran, List.append(&2, Thinker, due, [t])}, rnd, clock, ended,
    usedown, sounds, mrnd, reborn}

# The state with the thinker whose turn it was kept, to run again next
# tic.
def State.kept(s: State, t: Thinker) -> State:
  State{player, level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, level, things, sidetex, Thinkers{t <> ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn}

# Sounds
# ------

# The state after the tic reports an event: a start draws from M_Random
# as S_StartSound does.
def State.heard(+e: Sn.Sound.Event, s: State) -> State:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown,
    List.append(&2, Sn.Sound.Event, sounds, [e]), Sim.Face.drew(Sn.Sound.Event.draws(e), mrnd), reborn}

def State.told.go(events: List<&2, Sn.Sound.Event>, s: State) -> State:
  match events:
    case []:
      s
    case e <> rest:
      State.told.go(rest, State.heard(e, s))

# The state once it has reported what its things were heard doing.
def State.told(s: State) -> State:
  State{player, level, H.Things{tree, count, you, cells, sectors, heard}, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State.told.go(heard, State{player, level, H.Things{tree, count, you, cells, sectors, []}, sidetex, thinkers, rnd,
    clock, ended, usedown, sounds, mrnd, reborn})

def Sim.sound.spot(xy: U32 & U32) -> Sn.Sound.Source:
  (x, y) = xy
  Sn.Spot{x, y}

# The player hears its own sounds where it stands, and a thing that is
# gone has no place.
def Sim.sound.thing(own: Bool, m: Maybe<&2, H.Thing>) -> Sn.Sound.Source:
  match own m:
    case False{} Some{H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz}}:
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

# Spawning and removing
# ---------------------

# A thing entered into a state: in the population, linked where it is,
# its thinker started.
def State.entered(th: H.Thing, s: State) -> State:
  H.Thing{+id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz} = th
  State{player, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State.thinking(State{player, level, H.Things.entered(things, L.Level.blockmap_of(level),
    H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz}), sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd, reborn}, Mobj{id})

# Doom's P_SpawnMobj in play: a thing of a type at (x, y) and z, or on
# the floor or under the ceiling for H.Thing.onfloor and
# H.Thing.onceiling. It takes the next id past every one given, draws
# one random number, is linked where it is, and its thinker is started:
# last, so it first thinks the same tic if the thinkers' run is not over,
# as one added to the tail of Doom's list does.
def Sim.spawn(d: H.Thing.Def, x: U32, y: U32, z: U32, s: State) -> State:
  State{player, +level, +things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State.entered(H.Thing.mobj(d, level, H.Things.count(things), x, y, z), State{player, level,
    H.Things.fresh(things), sidetex, thinkers, M.Random.next(rnd), clock, ended, usedown, sounds, mrnd, reborn})

def Sim.remove.thing(m: Maybe<&2, H.Thing>, s: State) -> State:
  match m:
    case None{}:
      s
    case Some{th}:
      State{player, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
      State{player, level, H.Things.removed(things, L.Level.blockmap_of(level), th), sidetex, thinkers, rnd, clock,
        ended, usedown, sounds, mrnd, reborn}

# Doom's P_RemoveMobj: the thing unlinked and gone, its id never given
# again, its sound stopped; its thinker ends when its turn comes.
def Sim.remove(id: U32, +s: State) -> State:
  Sim.remove.thing(H.Things.get(State.things(s), id), s)

# Firing
# ------

# Doom's MISSILERANGE, how far a bullet reaches.
def Sim.missilerange() -> U32:
  134217728

# The slopes P_AimLineAttack opens with, the view's half height over its
# half width up and down: what the player can aim at without looking up.
def Sim.aimtop() -> U32:
  40960

def Sim.aimbottom() -> U32:
  4294926336

# Doom's shootz: a hitscan leaves the middle of the shooter's mobj,
# eight units higher.
def Sim.shootz(+z: U32, +height: U32) -> U32:
  (z + (height >> 1n) + 524288 : U32)

# C's division by two, which truncates toward zero where a shift floors.
def Sim.halve(+v: U32) -> U32:
  Bool.pick(U32, F.Fixed.is_neg(v), F.Fixed.neg((F.Fixed.neg(v) >> 1n : U32)), (v >> 1n : U32))

# What Doom's PTR_AimTraverse keeps in globals: the population and the
# player, to read a mobj the ray met; the shooter, which may not be
# aimed at; the height it shoots from and how far; the slopes still open
# above and below; and the slope at what has been aimed at, with its name.
type Sim.Aim is Data:
  Aim{things: H.Things, player: Player, shooter: U32, shootz: U32, range: U32, top: U32, bottom: U32,
    slope: U32, target: Maybe<&2, U32>}

def Sim.Aim.found(a: Sim.Aim) -> Bool:
  Aim{things, player, shooter, shootz, range, top, bottom, slope, target} = a
  Bool.not(Maybe.is_none(&2, U32, target))

def Sim.Aim.target(a: Sim.Aim) -> Maybe<&2, U32>:
  Aim{things, player, shooter, shootz, range, top, bottom, slope, target} = a
  target

# What P_AimLineAttack answers: the slope at what it aimed at, and level
# where it found nothing.
def Sim.Aim.slope(a: Sim.Aim) -> U32:
  Aim{things, player, shooter, shootz, range, top, bottom, +slope, target} = a
  Bool.pick(U32, Maybe.is_none(&2, U32, target), 0, slope)

# PTR_AimTraverse over a two-sided line: the opening narrows the slopes
# the shot may still take, each side only where the planes differ, and a
# pair of slopes that has closed ends the walk.
def Sim.aim.opening(+level: L.Level, +line: L.Level.Line, +frac: U32, a: Sim.Aim) -> Sim.Answer<&2, Sim.Aim>:
  L.Line{x1, y1, x2, y2, flags, +front, +back} = line
  Aim{things, player, shooter, +shootz, +range, +top, +bottom, slope, target} = a
  +dist = F.Fixed.mul(range, frac)
  +low = Bool.pick(U32, U32.is_eq(L.Level.floor(level, front), L.Level.floor(level, back)), bottom,
    F.Fixed.max(bottom, F.Fixed.div((Sim.open_bottom(level, line) - shootz : U32), dist)))
  +high = Bool.pick(U32, U32.is_eq(L.Level.ceil(level, front), L.Level.ceil(level, back)), top,
    F.Fixed.min(top, F.Fixed.div((Sim.open_top(level, line) - shootz : U32), dist)))
  Answer{F.Fixed.le(high, low), Aim{things, player, shooter, shootz, range, high, low, slope, target}}

# A line with no opening stops the aim where it stands.
def Sim.aim.open(open: Bool, +level: L.Level, +line: L.Level.Line, +frac: U32, a: Sim.Aim) ->
  Sim.Answer<&2, Sim.Aim>:
  match open:
    case False{}:
      Answer{True{}, a}
    case True{}:
      Sim.aim.opening(level, line, frac, a)

def Sim.aim.line(+level: L.Level, +i: U32, +frac: U32, a: Sim.Aim) -> Sim.Answer<&2, Sim.Aim>:
  +line = L.Level.line(level, i)
  Sim.aim.open(Bool.and(Sim.twosided(line), Bool.not(Sim.shut(level, line))), level, line, frac, a)

# The mobj is aimed at: the slope is the middle of what shows of it
# between the open slopes, and the walk ends there.
def Sim.aim.hit(missed: Bool, +id: U32, +slope: U32, a: Sim.Aim) -> Sim.Answer<&2, Sim.Aim>:
  match missed:
    case True{}:
      Answer{False{}, a}
    case False{}:
      Aim{things, player, shooter, shootz, range, top, bottom, was, target} = a
      Answer{True{}, Aim{things, player, shooter, shootz, range, top, bottom, slope, Some{id}}}

# PTR_AimTraverse over a mobj: one whose whole box lies over or under
# the open slopes is shot past.
def Sim.aim.shootable(shootable: Bool, +id: U32, +z: U32, +height: U32, +frac: U32, a: Sim.Aim) ->
  Sim.Answer<&2, Sim.Aim>:
  match shootable:
    case False{}:
      Answer{False{}, a}
    case True{}:
      Aim{things, player, shooter, +shootz, +range, +top, +bottom, slope, target} = a
      +dist = F.Fixed.mul(range, frac)
      +high = F.Fixed.div((z + height - shootz : U32), dist)
      +low = F.Fixed.div((z - shootz : U32), dist)
      Sim.aim.hit(Bool.or(F.Fixed.lt(high, bottom), F.Fixed.gt(low, top)), id,
        Sim.halve((F.Fixed.min(high, top) + F.Fixed.max(low, bottom) : U32)),
        Aim{things, player, shooter, shootz, range, top, bottom, slope, target})

# The shooter may not aim at itself, and a mobj the population no longer
# has is nowhere.
def Sim.aim.self(own: Bool, m: Maybe<&2, Sim.Body>, +id: U32, +frac: U32, a: Sim.Aim) -> Sim.Answer<&2, Sim.Aim>:
  match own m:
    case True{} _:
      Answer{False{}, a}
    case False{} None{}:
      Answer{False{}, a}
    case False{} Some{Body{bid, bx, by, z, radius, height, +flags}}:
      Sim.aim.shootable(Bool.not(U32.is_zero((flags .&. 4 : U32))), id, z, height, frac, a)

def Sim.aim.thing(+id: U32, +frac: U32, a: Sim.Aim) -> Sim.Answer<&2, Sim.Aim>:
  Aim{+things, +player, +shooter, shootz, range, top, bottom, slope, target} = a
  Sim.aim.self(U32.is_eq(id, shooter), Sim.body(things, player, id), id, frac,
    Aim{things, player, shooter, shootz, range, top, bottom, slope, target})

def Sim.aim.met(isline: Bool, +level: L.Level, +what: U32, +frac: U32, a: Sim.Aim) -> Sim.Answer<&2, Sim.Aim>:
  match isline:
    case True{}:
      Sim.aim.line(level, what, frac, a)
    case False{}:
      Sim.aim.thing(what, frac, a)

# Doom's PTR_AimTraverse.
def Sim.aim.visit(+level: L.Level, m: Sim.Meet, a: Sim.Aim) -> Sim.Answer<&2, Sim.Aim>:
  Meet{frac, isline, what} = m
  Sim.aim.met(isline, level, what, frac, a)

# Doom's P_AimLineAttack: the ray of some range along an angle, and the
# slope at the first shootable mobj it can reach.
def Sim.aim(+level: L.Level, +ts: H.Things, +p: Player, +x: U32, +y: U32, +shootz: U32, +shooter: U32,
  +angle: U32, +range: U32) -> Sim.Aim:
  +sine = L.Level.sine(level)
  +f = A.Angle.fine(angle)
  Sim.path(~Sim.Aim, ~Sim.aim.visit, level, ts, p, True{}, True{}, x, y,
    (x + (range >> 16n) * A.Angle.cos(sine, f) : U32), (y + (range >> 16n) * A.Angle.sin(sine, f) : U32),
    Aim{ts, p, shooter, shootz, range, Sim.aimtop(), Sim.aimbottom(), 0, None{}})

# P_BulletSlope's last try, a turn to the left of the facing.
def Sim.slope.left(found: Bool, +level: L.Level, +ts: H.Things, +p: Player, +x: U32, +y: U32, +shootz: U32,
  +shooter: U32, +angle: U32, a: Sim.Aim) -> Sim.Aim:
  match found:
    case True{}:
      a
    case False{}:
      Sim.aim(level, ts, p, x, y, shootz, shooter, (angle - 67108864 : U32), Sim.missilerange())

# P_BulletSlope's second try, a turn to the right.
def Sim.slope.right(found: Bool, +level: L.Level, +ts: H.Things, +p: Player, +x: U32, +y: U32, +shootz: U32,
  +shooter: U32, +angle: U32, a: Sim.Aim) -> Sim.Aim:
  match found:
    case True{}:
      a
    case False{}:
      +right = Sim.aim(level, ts, p, x, y, shootz, shooter, (angle + 67108864 : U32), Sim.missilerange())
      Sim.slope.left(Sim.Aim.found(right), level, ts, p, x, y, shootz, shooter, angle, right)

# Doom's P_BulletSlope: the aim straight ahead, and where that finds
# nothing a turn of 1<<26 to either side, the right first. The slope of
# the last try stands, so three misses aim level.
def Sim.bulletslope(+level: L.Level, +ts: H.Things, +p: Player, +x: U32, +y: U32, +shootz: U32, +shooter: U32,
  +angle: U32) -> U32:
  +ahead = Sim.aim(level, ts, p, x, y, shootz, shooter, angle, Sim.missilerange())
  Sim.Aim.slope(Sim.slope.right(Sim.Aim.found(ahead), level, ts, p, x, y, shootz, shooter, angle, ahead))

# Where a bullet stopped: at a wall's face, at a mobj, or nowhere, which
# is a shot into a sky as well as one that reached its range.
type Sim.Hit is Data:
  Struck{frac: U32}
  Pierced{id: U32, frac: U32}
  Vanished{}

# What Doom's PTR_ShootTraverse keeps in globals, with what the bullet
# met: the population and the player to read a mobj with, the shooter,
# the height and range of the shot, the slope it flies at, and the
# damage it deals whatever it hits.
type Sim.Shot is Data:
  Shot{things: H.Things, player: Player, shooter: U32, shootz: U32, range: U32, slope: U32, damage: U32,
    hit: Sim.Hit}

# The wall was reached: the bullet leaves nothing where it flew over a
# sky ceiling, or where the sector behind the line shows the sky too,
# which is vanilla's sky hack.
def Sim.shot.sky(sky: Bool, +frac: U32, sh: Sim.Shot) -> Sim.Answer<&2, Sim.Shot>:
  match sky:
    case True{}:
      Shot{things, player, shooter, shootz, range, slope, damage, was} = sh
      Answer{True{}, Shot{things, player, shooter, shootz, range, slope, damage, Vanished{}}}
    case False{}:
      Shot{things, player, shooter, shootz, range, slope, damage, was} = sh
      Answer{True{}, Shot{things, player, shooter, shootz, range, slope, damage, Struck{frac}}}

def Sim.shot.behind(exists: Bool, +level: L.Level, +back: U32) -> Bool:
  match exists:
    case False{}:
      False{}
    case True{}:
      L.Level.sky(level, back)

# PTR_ShootTraverse's hit on a line: the puff stands four units back
# along the ray, which is where the sky is tested too.
def Sim.shot.wall(+level: L.Level, +line: L.Level.Line, +frac: U32, sh: Sim.Shot) -> Sim.Answer<&2, Sim.Shot>:
  L.Line{x1, y1, x2, y2, flags, +front, +back} = line
  Shot{things, player, shooter, +shootz, +range, +slope, damage, hit} = sh
  +back4 = (frac - F.Fixed.div(262144, range) : U32)
  +z = (shootz + F.Fixed.mul(slope, F.Fixed.mul(back4, range)) : U32)
  Sim.shot.sky(Bool.and(L.Level.sky(level, front), Bool.or(F.Fixed.gt(z, L.Level.ceil(level, front)),
      Sim.shot.behind(Bool.not(U32.is_eq(back, L.Level.none())), level, back))), back4,
    Shot{things, player, shooter, shootz, range, slope, damage, hit})

def Sim.shot.open(blocked: Bool, +level: L.Level, +line: L.Level.Line, +frac: U32, sh: Sim.Shot) ->
  Sim.Answer<&2, Sim.Shot>:
  match blocked:
    case True{}:
      Sim.shot.wall(level, line, frac, sh)
    case False{}:
      Answer{False{}, sh}

# PTR_ShootTraverse over a two-sided line: the bullet flies on while its
# slope stays inside the opening, and hits the line where a plane that
# differs from the one behind it is in the way.
def Sim.shot.crosses(+level: L.Level, +line: L.Level.Line, +frac: U32, sh: Sim.Shot) -> Sim.Answer<&2, Sim.Shot>:
  L.Line{x1, y1, x2, y2, flags, +front, +back} = line
  Shot{things, player, shooter, +shootz, +range, +slope, damage, hit} = sh
  +dist = F.Fixed.mul(range, frac)
  Sim.shot.open(Bool.or(
      Bool.and(Bool.not(U32.is_eq(L.Level.floor(level, front), L.Level.floor(level, back))),
        F.Fixed.gt(F.Fixed.div((Sim.open_bottom(level, line) - shootz : U32), dist), slope)),
      Bool.and(Bool.not(U32.is_eq(L.Level.ceil(level, front), L.Level.ceil(level, back))),
        F.Fixed.lt(F.Fixed.div((Sim.open_top(level, line) - shootz : U32), dist), slope))),
    level, line, frac, Shot{things, player, shooter, shootz, range, slope, damage, hit})

def Sim.shot.solid(open: Bool, +level: L.Level, +line: L.Level.Line, +frac: U32, sh: Sim.Shot) ->
  Sim.Answer<&2, Sim.Shot>:
  match open:
    case False{}:
      Sim.shot.wall(level, line, frac, sh)
    case True{}:
      Sim.shot.crosses(level, line, frac, sh)

def Sim.shot.line(+level: L.Level, +i: U32, +frac: U32, sh: Sim.Shot) -> Sim.Answer<&2, Sim.Shot>:
  +line = L.Level.line(level, i)
  Sim.shot.solid(Bool.and(Sim.twosided(line), Bool.not(Sim.shut(level, line))), level, line, frac, sh)

# The mobj is hit: what it is given stands ten units back along the ray.
def Sim.shot.body(missed: Bool, +id: U32, +frac: U32, sh: Sim.Shot) -> Sim.Answer<&2, Sim.Shot>:
  match missed:
    case True{}:
      Answer{False{}, sh}
    case False{}:
      Shot{things, player, shooter, shootz, +range, slope, damage, was} = sh
      Answer{True{}, Shot{things, player, shooter, shootz, range, slope, damage,
        Pierced{id, (frac - F.Fixed.div(655360, range) : U32)}}}

# PTR_ShootTraverse over a mobj: one whose box the slope passes over or
# under is shot past.
def Sim.shot.shootable(shootable: Bool, +id: U32, +z: U32, +height: U32, +frac: U32, sh: Sim.Shot) ->
  Sim.Answer<&2, Sim.Shot>:
  match shootable:
    case False{}:
      Answer{False{}, sh}
    case True{}:
      Shot{things, player, shooter, +shootz, +range, +slope, damage, hit} = sh
      +dist = F.Fixed.mul(range, frac)
      Sim.shot.body(Bool.or(F.Fixed.lt(F.Fixed.div((z + height - shootz : U32), dist), slope),
          F.Fixed.gt(F.Fixed.div((z - shootz : U32), dist), slope)), id, frac,
        Shot{things, player, shooter, shootz, range, slope, damage, hit})

def Sim.shot.self(own: Bool, m: Maybe<&2, Sim.Body>, +id: U32, +frac: U32, sh: Sim.Shot) ->
  Sim.Answer<&2, Sim.Shot>:
  match own m:
    case True{} _:
      Answer{False{}, sh}
    case False{} None{}:
      Answer{False{}, sh}
    case False{} Some{Body{bid, bx, by, z, radius, height, +flags}}:
      Sim.shot.shootable(Bool.not(U32.is_zero((flags .&. 4 : U32))), id, z, height, frac, sh)

def Sim.shot.thing(+id: U32, +frac: U32, sh: Sim.Shot) -> Sim.Answer<&2, Sim.Shot>:
  Shot{+things, +player, +shooter, shootz, range, slope, damage, hit} = sh
  Sim.shot.self(U32.is_eq(id, shooter), Sim.body(things, player, id), id, frac,
    Shot{things, player, shooter, shootz, range, slope, damage, hit})

def Sim.shot.met(isline: Bool, +level: L.Level, +what: U32, +frac: U32, sh: Sim.Shot) -> Sim.Answer<&2, Sim.Shot>:
  match isline:
    case True{}:
      Sim.shot.line(level, what, frac, sh)
    case False{}:
      Sim.shot.thing(what, frac, sh)

# Doom's PTR_ShootTraverse. P_ShootSpecialLine is left out: no line in
# either E1M1 fires on a gunshot.
def Sim.shot.visit(+level: L.Level, m: Sim.Meet, sh: Sim.Shot) -> Sim.Answer<&2, Sim.Shot>:
  Meet{frac, isline, what} = m
  Sim.shot.met(isline, level, what, frac, sh)

# The puff once it stands where P_SpawnPuff put it: it rises a unit a
# tic, and its first state is shortened by the draw, never under a tic.
def Sim.puff.tics(m: Maybe<&2, H.Thing>, +id: U32, +drawn: U32, s: State) -> State:
  match m:
    case None{}:
      s
    case Some{H.Thing{i, kind, x, y, z, floorz, ceilz, angle, sector, state, +tics, momz}}:
      State{player, level, +things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
      State{player, level, H.Things.put(things, id, Some{H.Thing{i, kind, x, y, z, floorz, ceilz, angle, sector,
        state, F.Fixed.max(1, (tics - (drawn .&. 3 : U32) : U32)), F.Fixed.unit()}}), sidetex, thinkers, rnd, clock,
        ended, usedown, sounds, mrnd, reborn}

def Sim.puff.drawn(+id: U32, s: State) -> State:
  State{player, level, +things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  +drew = M.Random.next(rnd)
  Sim.puff.tics(H.Things.get(things, id), id, M.Random.at(drew), State{player, level, things, sidetex, thinkers,
    drew, clock, ended, usedown, sounds, mrnd, reborn})

def Sim.puff.at(+x: U32, +y: U32, +z: U32, +s: State) -> State:
  Sim.puff.drawn(H.Things.count(State.things(s)), Sim.spawn(H.Thing.info(H.Thing.puff()), x, y, z, s))

# Doom's P_SpawnPuff: the z is nudged by up to four units either way,
# the mobj spawns and draws as any does, and a last draw shortens its
# first state. The spark state is for a punch alone, whose attack range
# no shot has.
def Sim.puff(+x: U32, +y: U32, +z: U32, s: State) -> State:
  State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  +a = M.Random.next(rnd)
  +b = M.Random.next(a)
  Sim.puff.at(x, y, (z + ((M.Random.at(a) - M.Random.at(b) : U32) << 10n) : U32),
    State{player, level, things, sidetex, thinkers, b, clock, ended, usedown, sounds, mrnd, reborn})

# A mobj the bullet hit takes a puff where it does not bleed, as vanilla
# gives an MF_NOBLOOD thing. P_SpawnBlood for one that bleeds, and
# P_DamageMobj for either, belong in this match.
def Sim.shot.hurt(bleeds: Bool, +x: U32, +y: U32, +z: U32, s: State) -> State:
  match bleeds:
    case False{}:
      Sim.puff(x, y, z, s)
    case True{}:
      s

def Sim.shot.bled(m: Maybe<&2, Sim.Body>, +x: U32, +y: U32, +z: U32, s: State) -> State:
  match m:
    case None{}:
      s
    case Some{Body{id, bx, by, bz, radius, height, +flags}}:
      Sim.shot.hurt(U32.is_zero((flags .&. 524288 : U32)), x, y, z, s)

# What the bullet left where it stopped, which vanilla spawns inside the
# traversal: the walk ends at the first thing it hits, and no visitor of
# this walk draws, so spawning here makes the same draws in the same
# order.
def Sim.shot.left(hit: Sim.Hit, tr: Sim.Trace, sh: Sim.Shot, s: State) -> State:
  match hit:
    case Vanished{}:
      s
    case Struck{+frac}:
      Trace{tx, ty, tdx, tdy} = tr
      Shot{things, player, shooter, shootz, +range, slope, damage, was} = sh
      Sim.puff((tx + F.Fixed.mul(tdx, frac) : U32), (ty + F.Fixed.mul(tdy, frac) : U32),
        (shootz + F.Fixed.mul(slope, F.Fixed.mul(frac, range)) : U32), s)
    case Pierced{id, +frac}:
      Trace{tx, ty, tdx, tdy} = tr
      Shot{+things, +player, shooter, shootz, +range, slope, damage, was} = sh
      Sim.shot.bled(Sim.body(things, player, id), (tx + F.Fixed.mul(tdx, frac) : U32),
        (ty + F.Fixed.mul(tdy, frac) : U32), (shootz + F.Fixed.mul(slope, F.Fixed.mul(frac, range)) : U32), s)

def Sim.shot.done(tr: Sim.Trace, sh: Sim.Shot, s: State) -> State:
  Shot{things, player, shooter, shootz, range, slope, damage, +hit} = sh
  Sim.shot.left(hit, tr, Shot{things, player, shooter, shootz, range, slope, damage, hit}, s)

# Doom's P_LineAttack: the bullet's ray, and what it leaves where it
# stops.
def Sim.attack(+level: L.Level, +ts: H.Things, +p: Player, +x: U32, +y: U32, +shootz: U32, +shooter: U32,
  +angle: U32, +range: U32, +slope: U32, +damage: U32, s: State) -> State:
  +sine = L.Level.sine(level)
  +f = A.Angle.fine(angle)
  +x2 = (x + (range >> 16n) * A.Angle.cos(sine, f) : U32)
  +y2 = (y + (range >> 16n) * A.Angle.sin(sine, f) : U32)
  Sim.shot.done(Sim.trace.of(L.Level.blockmap_of(level), x, y, x2, y2),
    Sim.path(~Sim.Shot, ~Sim.shot.visit, level, ts, p, True{}, True{}, x, y, x2, y2,
      Shot{ts, p, shooter, shootz, range, slope, damage, Vanished{}}), s)

def Sim.gunshot.fired(+angle: U32, +damage: U32, +slope: U32, +s: State) -> State:
  +p = State.player(s)
  +ts = State.things(s)
  Sim.attack(State.level(s), ts, p, Player.x(p), Player.y(p), Sim.shootz(Player.z(p), Sim.height()),
    H.Things.you(ts), angle, Sim.missilerange(), slope, damage, s)

# A held shot is spread by a draw to either side, where the first of a
# press goes straight where the weapon points.
def Sim.gunshot.spread(accurate: Bool, +angle: U32, +damage: U32, +slope: U32, s: State) -> State:
  match accurate:
    case True{}:
      Sim.gunshot.fired(angle, damage, slope, s)
    case False{}:
      State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
      +a = M.Random.next(rnd)
      +b = M.Random.next(a)
      Sim.gunshot.fired((angle + ((M.Random.at(a) - M.Random.at(b) : U32) << 18n) : U32), damage, slope,
        State{player, level, things, sidetex, thinkers, b, clock, ended, usedown, sounds, mrnd, reborn})

# Doom's P_GunShot: the damage is drawn first, whoever takes it.
def Sim.gunshot(accurate: Bool, +slope: U32, s: State) -> State:
  State{+player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  +drew = M.Random.next(rnd)
  Sim.gunshot.spread(accurate, Player.angle(player), (5 * ((M.Random.at(drew) % 3 : U32) + 1 : U32) : U32), slope,
    State{player, level, things, sidetex, thinkers, drew, clock, ended, usedown, sounds, mrnd, reborn})

# The player sprites
# ------------------

# A player sprite mid-step: the state it is to enter, if any, the state
# its action set on the muzzle flash, the sprite itself, and the world
# the action changed.
type Sim.Entering is Data:
  Entering{next: Maybe<&2, U32>, sets: Maybe<&2, U32>, psp: Psprite, s: State}

# Doom's A_Raise: the sprite rises, and at the top the weapon's ready
# state is set.
def Sim.raise(psp: Psprite, weapon: H.Thing.Weapon, s: State) -> Sim.Entering:
  Psprite{state, tics, sx, sy} = psp
  H.Weapon{up, ready, down, ammo, atk, flash} = weapon
  +risen = (sy - Sim.raisespeed() : U32)
  Entering{Bool.pick(Maybe<&2, U32>, F.Fixed.gt(risen, Sim.weapontop()), None{}, Some{ready}), None{},
    Psprite{state, tics, sx, F.Fixed.max(risen, Sim.weapontop())}, s}

# A_WeaponReady's bob: the sprite swings on the level's clock, a turn
# every 64 tics, as far as the bob to either side of column 1 and below
# the top.
def Sim.ready.bob(psp: Psprite, +sine: V.Vec, +clock: U32, +bob: U32, s: State) -> Sim.Entering:
  Psprite{state, tics, sx, sy} = psp
  +angle = ((128 * clock : U32) .&. 8191 : U32)
  Entering{None{}, None{}, Psprite{state, tics, (65536 + F.Fixed.mul(bob, A.Angle.cos(sine, angle)) : U32),
    (Sim.weapontop() + F.Fixed.mul(bob, A.Angle.sin(sine, (angle .&. 4095 : U32))) : U32)}, s}

# The state with another count of shots the held attack has taken.
def State.firing(+refire: U32, s: State) -> State:
  State{+player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{Player.firing(player, refire), level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}

# One bullet spent, Doom's DecreaseAmmo for the pistol.
def Sim.spent(s: State) -> State:
  State{+player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{Player.holding(player, I.Inventory.spend(I.Inventory.am_clip(), 1, Player.inv(player))), level, things,
    sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}

def Sim.fire.shot(+s: State) -> State:
  +p = State.player(s)
  +ts = State.things(s)
  Sim.gunshot(U32.is_zero(Player.refire(p)), Sim.bulletslope(State.level(s), ts, p, Player.x(p), Player.y(p),
    Sim.shootz(Player.z(p), Sim.height()), H.Things.you(ts), Player.angle(p)), s)

# Doom's A_FirePistol: the shot is heard, a bullet is spent, the muzzle
# flash is set, and the bullet flies where the autoaim points, straight
# on the first shot of a press and spread on the rest. P_SetMobjState on
# the player's own mobj has no reader, since single player never draws
# it, and P_NoiseAlert has nothing to wake yet.
def Sim.fire.pistol(psp: Psprite, weapon: H.Thing.Weapon, s: State) -> Sim.Entering:
  H.Weapon{up, ready, down, ammo, atk, flash} = weapon
  Entering{None{}, Some{flash}, psp,
    Sim.fire.shot(Sim.spent(Sim.sound(Sn.Sound.pistol(), Sn.Thing{H.Thing.you()}, s)))}

# Whether the ready weapon has a shot left. Doom's P_CheckAmmo also
# picks another weapon where it has none, which is the switching
# ticket's, so a dry pistol stays up instead of being lowered.
def Sim.ammo.enough(+s: State) -> Bool:
  U32.is_lt(0, I.Inventory.rounds(I.Inventory.am_clip(), Player.inv(State.player(s))))

# Doom's P_FireWeapon: with a shot left the weapon enters its attack
# state.
def Sim.fire.weapon(enough: Bool, psp: Psprite, weapon: H.Thing.Weapon, s: State) -> Sim.Entering:
  match enough:
    case False{}:
      Entering{None{}, None{}, psp, s}
    case True{}:
      H.Weapon{up, ready, down, ammo, atk, flash} = weapon
      Entering{Some{atk}, None{}, psp, s}

def Sim.fire(psp: Psprite, weapon: H.Thing.Weapon, +s: State) -> Sim.Entering:
  Sim.fire.weapon(Sim.ammo.enough(s), psp, weapon, s)

# Doom's A_WeaponReady's fire check: the attack held fires and leaves
# the sprite where it is, and a released attack lets the weapon bob.
# Vanilla also writes attackdown here, which only the launcher and the
# BFG read. The pending weapon and the dead player's lowering are the
# switching ticket's.
def Sim.ready.fire(attack: Bool, psp: Psprite, weapon: H.Thing.Weapon, +sine: V.Vec, +clock: U32, +bob: U32,
  s: State) -> Sim.Entering:
  match attack:
    case True{}:
      Sim.fire(psp, weapon, s)
    case False{}:
      Sim.ready.bob(psp, sine, clock, bob, s)

# Doom's A_ReFire: the attack still held and the player alive takes
# another shot and counts it; anything else puts the count back, where
# vanilla also runs P_CheckAmmo.
def Sim.refire.again(again: Bool, psp: Psprite, weapon: H.Thing.Weapon, +s: State) -> Sim.Entering:
  match again:
    case True{}:
      Sim.fire(psp, weapon, State.firing((Player.refire(State.player(s)) + 1 : U32), s))
    case False{}:
      Entering{None{}, None{}, psp, State.firing(0, s)}

def Sim.refire(psp: Psprite, cmd: K.Cmd, weapon: H.Thing.Weapon, +s: State) -> Sim.Entering:
  Sim.refire.again(Bool.and(K.Cmd.attack(cmd),
    Bool.not(U32.is_zero(I.Inventory.health(Player.inv(State.player(s)))))), psp, weapon, s)

# Doom's A_Lower for a dead player: the sprite sinks 6 a tic and stays
# at the bottom of the screen. Death is the only thing that lowers a
# weapon here, so the branch that brings the next one up has no caller.
def Sim.lower(psp: Psprite, s: State) -> Sim.Entering:
  Psprite{state, tics, sx, +sy} = psp
  Entering{None{}, None{}, Psprite{state, tics, sx, F.Fixed.min((sy + Sim.lowerspeed() : U32),
    Sim.weaponbottom())}, s}

def Sim.psprite.act(action: H.Thing.Action, psp: Psprite, cmd: K.Cmd, weapon: H.Thing.Weapon, +s: State) ->
  Sim.Entering:
  match action:
    case H.Null{}:
      Entering{None{}, None{}, psp, s}
    case H.Raise{}:
      Sim.raise(psp, weapon, s)
    case H.WeaponReady{}:
      Sim.ready.fire(K.Cmd.attack(cmd), psp, weapon, L.Level.sine(State.level(s)), State.clock(s),
        Sim.bob(Player.momx(State.player(s)), Player.momy(State.player(s))), s)
    case H.FirePistol{}:
      Sim.fire.pistol(psp, weapon, s)
    case H.ReFire{}:
      Sim.refire(psp, cmd, weapon, s)
    case H.Lower{}:
      Sim.lower(psp, s)
    case other:
      Entering{None{}, None{}, psp, s}

# The state a step goes on to: the one the action set, else the next row
# where the state it entered lasts no tics, as P_SetPsprite's loop does.
def Sim.psprite.on(set: Maybe<&2, U32>, out: Bool, +next: U32) -> Maybe<&2, U32>:
  match set out:
    case Some{state} _:
      Some{state}
    case None{} True{}:
      Some{next}
    case None{} False{}:
      None{}

# The flash state an action set, over whatever an earlier step set.
def Sim.psprite.or(set: Maybe<&2, U32>, had: Maybe<&2, U32>) -> Maybe<&2, U32>:
  match set:
    case None{}:
      had
    case Some{state}:
      Some{state}

def Sim.psprite.entered(e: Sim.Entering, +row: H.Thing.Row, had: Maybe<&2, U32>) -> Sim.Entering:
  Entering{next, set, psp, s} = e
  Entering{Sim.psprite.on(next, U32.is_zero(H.Thing.Row.tics(row)), H.Thing.Row.next(row)),
    Sim.psprite.or(set, had), psp, s}

# One turn of P_SetPsprite: the sprite takes the state's row and tics,
# and the row's action runs.
def Sim.psprite.enter(+state: U32, had: Maybe<&2, U32>, psp: Psprite, cmd: K.Cmd, +weapon: H.Thing.Weapon,
  s: State) -> Sim.Entering:
  Psprite{was, tics, sx, sy} = psp
  +row = H.Thing.row(state)
  Sim.psprite.entered(Sim.psprite.act(H.Thing.Row.action(row),
    Psprite{Some{state}, H.Thing.Row.tics(row), sx, sy}, cmd, weapon, s), row, had)

# Entering S_NULL stops the sprite showing, as a state number of 0 does
# in vanilla.
def Sim.psprite.gone(null: Bool, state: U32, had: Maybe<&2, U32>, psp: Psprite, cmd: K.Cmd,
  +weapon: H.Thing.Weapon, s: State) -> Sim.Entering:
  match null psp:
    case True{} Psprite{was, tics, sx, sy}:
      Entering{None{}, had, Psprite{None{}, tics, sx, sy}, s}
    case False{} kept:
      Sim.psprite.enter(state, had, kept, cmd, weapon, s)

# Doom's P_SetPsprite: states are entered in turn while an action sets
# one or the state entered lasts no tics. No chain of vanilla's is
# longer than three.
def Sim.psprite.set(fuel: Nat, st: Sim.Entering, +cmd: K.Cmd, +weapon: H.Thing.Weapon) -> Sim.Entering:
  match fuel st:
    case 1n+f Entering{Some{+state}, sets, psp, s}:
      Sim.psprite.set(f, Sim.psprite.gone(U32.is_eq(state, H.Thing.null()), state, sets, psp, cmd, weapon, s),
        cmd, weapon)
    case _ Entering{next, sets, psp, s}:
      Entering{next, sets, psp, s}

# Doom's P_MovePsprites for one sprite: one that shows counts its tics
# down, and the tic they run out enters its next state. No weapon state
# lasts.
def Sim.psprite.tic(psp: Psprite, sets: Maybe<&2, U32>, cmd: K.Cmd, weapon: H.Thing.Weapon, s: State) ->
  Sim.Entering:
  match psp:
    case Psprite{None{}, tics, sx, sy}:
      Entering{None{}, sets, Psprite{None{}, tics, sx, sy}, s}
    case Psprite{Some{+state}, +tics, sx, sy}:
      Sim.psprite.set(8n, Entering{Bool.pick(Maybe<&2, U32>, U32.is_eq(tics, 1),
        Some{H.Thing.Row.next(H.Thing.row(state))}, None{}), sets, Psprite{Some{state}, (tics - 1 : U32), sx, sy},
        s}, cmd, weapon)

# The flash is drawn where the weapon is.
def Sim.psprites.follow(weapon: Psprite, flash: Psprite) -> Psprites:
  Psprite{state, tics, +sx, +sy} = weapon
  Psprite{fstate, ftics, fx, fy} = flash
  Psprites{Psprite{state, tics, sx, sy}, Psprite{fstate, ftics, sx, sy}}

# The state holding the sprites a tic left.
def State.showing(ps: Psprites, s: State) -> State:
  State{+player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{Player.showing(player, ps), level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}

def Sim.psprites.done(weapon: Psprite, e: Sim.Entering) -> State:
  Entering{next, sets, psp, s} = e
  State.showing(Sim.psprites.follow(weapon, psp), s)

def Sim.psprites.after(weapon: Psprite, e: Sim.Entering, +cmd: K.Cmd, +winfo: H.Thing.Weapon) -> State:
  Entering{next, sets, psp, s} = e
  Sim.psprites.done(weapon, Sim.psprite.tic(psp, None{}, cmd, winfo, s))

# The flash after the weapon's step: a state the weapon's action set is
# entered first, and only then does P_MovePsprites count the flash's
# tics down, since it reaches the flash after the weapon.
def Sim.psprites.flash(flash: Psprite, e: Sim.Entering, +cmd: K.Cmd, +winfo: H.Thing.Weapon) -> State:
  Entering{next, sets, psp, s} = e
  Sim.psprites.after(psp, Sim.psprite.set(8n, Entering{sets, None{}, flash, s}, cmd, winfo), cmd, winfo)

def Sim.psprites.both(ps: Psprites, +cmd: K.Cmd, +winfo: H.Thing.Weapon, s: State) -> State:
  Psprites{+weapon, flash} = ps
  Sim.psprites.flash(flash, Sim.psprite.tic(weapon, None{}, cmd, winfo, s), cmd, winfo)

# Doom's P_MovePsprites: the weapon's sprite steps first, and its action
# may set the flash's state; then the flash's steps, on the state the
# weapon left it in.
def Sim.psprites(+cmd: K.Cmd, +s: State) -> State:
  Sim.psprites.both(Player.psprites(State.player(s)), cmd, H.Thing.pistol(), s)

# The weapon put away, the flash as it was.
def Sim.psprites.lowered(flash: Psprite, e: Sim.Entering) -> State:
  Entering{next, sets, psp, s} = e
  State.showing(Psprites{psp, flash}, s)

def Sim.psprites.raised(e: Sim.Entering) -> State:
  Entering{next, sets, psp, s} = e
  State.showing(Psprites{psp, Psprite{None{}, 0, 0, 0}}, s)

# Doom's P_SetupPsprites and P_BringUpWeapon: the weapon enters its
# raise state at the bottom of the view, where A_Raise takes it up at
# once. The pistol starts no sound and draws nothing, so where in the
# level's start this runs cannot be seen.
def Sim.psprites.up(+weapon: H.Thing.Weapon, s: State) -> State:
  H.Weapon{+up, ready, down, ammo, atk, flash} = weapon
  Sim.psprites.raised(Sim.psprite.set(8n, Entering{Some{up}, None{}, Psprite{None{}, 0, 0, Sim.weaponbottom()}, s},
    K.Cmd.idle(), weapon))

def Sim.psprites.start(s: State) -> State:
  Sim.psprites.up(H.Thing.pistol(), s)

# Lights
# ------

def Sim.light(s: State, sector: U32) -> U32:
  L.Level.sector.light(State.level(s), sector)

# A blink goes dark from its bright level, else bright, for that level's
# time, or for a random count under it; put is how it joins the
# thinkers, started or kept.
def Sim.blink.to(~put: @s: State -> @t: Thinker -> State, +lit: Bool, +sector: U32, +dark: U32, +bright: U32,
  +darktime: U32, +brighttime: U32, +random: Bool, s: State) -> State:
  State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  +time = Bool.pick(U32, lit, darktime, brighttime)
  +i = Bool.pick(U32, random, M.Random.next(rnd), rnd)
  put(State{player, L.Level.light.put(level, sector, Bool.pick(U32, lit, dark, bright)), things, sidetex,
    thinkers, i, clock, ended, usedown, sounds, mrnd, reborn}, Blink{sector, Bool.pick(U32, random,
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
  State{player, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  +light = L.Level.sector.light(level, sector)
  +next = Bool.pick(U32, down, (light - 8 : U32), (light + 8 : U32))
  +turn = Bool.pick(Bool, down, F.Fixed.le(next, dark), F.Fixed.ge(next, bright))
  State.kept(State{player, L.Level.light.put(level, sector, Bool.pick(U32, turn, light, next)), things, sidetex,
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
  H.Thing{id, kind, x, y, +z, +floorz, ceilz, angle, sector, state, tics, momz} = th
  Body{i, mx, my, mz, radius, +height, flags} = m
  Fit{ok, +floor, +ceil} = f
  (Bool.or(Sim.fits(floor, ceil, height), U32.is_zero((flags .&. 4 : U32))),
    H.Thing{id, kind, x, y, Sim.clip(z, floorz, floor, ceil, height), floor, ceil, angle, sector, state, tics, momz})

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
      State.kept(s, Button{side, slot, texture, (tics - 1 : U32)})

# The thing after its tic: one that entered S_NULL removed itself, as
# P_SetMobjState does, and its thinker ends at its next turn.
def Sim.thing.left(gone: Bool, th: H.Thing, +id: U32, s: State) -> State:
  match gone:
    case True{}:
      State.kept(Sim.remove(id, s), Mobj{id})
    case False{}:
      State{player, level, +things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
      State.kept(State{player, level, H.Things.put(things, id, Some{th}), sidetex, thinkers, rnd, clock,
        ended, usedown, sounds, mrnd, reborn}, Mobj{id})

def Sim.thing.stepped(+th: H.Thing, +id: U32, s: State) -> State:
  Sim.thing.left(H.Thing.gone(th), th, id, s)

# Doom's P_MobjThinker for a thing: its vertical move, then its tic
# through its states. One already removed has no thing, and its thinker
# ends here, as Doom's does when the run reaches it.
def Sim.thing.tic(m: Maybe<&2, H.Thing>, +id: U32, s: State) -> State:
  match m:
    case None{}:
      s
    case Some{th}:
      Sim.thing.stepped(H.Thing.tic(th), id, s)

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

def State.entered.all(things: List<&2, H.Thing>, s: State) -> State:
  match things:
    case []:
      s
    case th <> rest:
      State.entered.all(rest, State.entered(th, s))

# The player's mobj entered: linked where the player stands, its thinker
# started.
def State.entered.you(s: State) -> State:
  State{+player, +level, +things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State.thinking(State{player, level, H.Things.link(things, L.Level.blockmap_of(level), False{}, H.Things.you(things),
    Player.x(player), Player.y(player), L.Level.sector_at(level, Player.x(player), Player.y(player))), sidetex,
    thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}, Mobj{H.Things.you(things)})

# Whether the player's mobj enters before the first of some things: its
# record comes before theirs, or none is left.
def State.you.first(things: List<&2, H.Thing>, you: U32) -> Bool:
  match things:
    case []:
      True{}
    case H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz} <> rest:
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
  State{player, +level, +old, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State.populated.go(things, State.you.first(things, H.Things.you(old)), H.Things.you(old),
    State{player, level, Sim.nothing(L.Level.blockmap_of(level), count, H.Things.you(old), L.Level.nsectors(level)),
      sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn})

# The state a level starts in, from the map as loaded, with the player
# at rest at a place, the things spawned with the random numbers they
# draw, and then the lights in sector order. Use counts as down, as
# Doom's G_PlayerReborn leaves it, so a key held since before the level
# does nothing. M_Random's index stands at 64: G_InitNew clears it, and
# the melt that wipes the level in draws once a screen column, 320.
def State.at.spawned(+level: L.Level, place: L.Level.Start, spawn: H.Thing.Spawn) -> State:
  H.Spawn{things, rnd, you} = spawn
  Sim.psprites.start(Sim.lights(U32.to_nat(L.Level.nsectors(level)), 0,
    State.populated(things, L.Level.nthings(level),
      State{Player.at(level, place), level, H.Things.none(0, you, 0, 0), L.Level.sidetex(level), Thinkers{[], []},
        rnd, 0, False{}, True{}, [], Sim.Face.start(64), False{}})))

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
      State{player, +level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
      State{player, level, things, sidetex, Thinkers{Sim.door.turn(ran, sector, L.Level.floor(level, sector)),
        Sim.door.turn(due, sector, L.Level.floor(level, sector))}, rnd, clock, ended, usedown, sounds, mrnd, reborn}
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
      State{player, +level, things, +sidetex, Thinkers{+ran, +due}, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
      +showed = V.Vec.get(sidetex, (side * 3 + slot : U32))
      +started = List.append(&2, Thinker, List.reverse(&2, Thinker, ran), due)
      Sim.switch.button(Bool.and(again, Bool.not(Sim.pressed.side(started, side))), side, slot, showed,
        Sim.sound(Sn.Sound.swtchn(), Sim.switch.origin(started, level),
          State{player, level, things, V.Vec.set(sidetex, (side * 3 + slot : U32), L.Level.switch(level, showed)),
            Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn}))

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
  Sim.use.at(Bool.not(U32.is_zero(L.Level.special(level, i))), Sim.shut(level, L.Level.line(level, i)), i)

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

# Damage
# ------

# Doom's P_Random: the state with its index stepped. What it drew is the
# table at the index it leaves, M.Random.at(State.rnd(s)).
def Sim.drawn(s: State) -> State:
  State{player, level, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, level, things, sidetex, thinkers, M.Random.next(rnd), clock, ended, usedown, sounds, mrnd, reborn}

# A thing named by a blow: none for nobody, for the player, whose name
# no thing in the population carries, or for a thing since gone.
def Sim.named(self: Bool, +things: H.Things, +id: U32) -> Maybe<&2, H.Thing>:
  match self:
    case True{}:
      None{}
    case False{}:
      H.Things.get(things, id)

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
def Player.entering(+state: U32, +p: Player) -> Player:
  Player.hurting(p, V.Vec.set(V.Vec.set(Player.hurt(p), Sim.hurt.state(), state), Sim.hurt.tics(),
    H.Thing.Row.tics(H.Thing.row(state))))

# Doom's P_SetMobjState for the player's mobj: it enters the state for
# that state's tics and the state's action runs. No state of the
# player's has 0 tics, so none chains into the next.
def Sim.mobj.enter(+state: U32, +s: State) -> State:
  Sim.mobj.act(H.Thing.Row.action(H.Thing.row(state)),
    State.player.put(s, Player.entering(state, State.player(s))))

# The player's mobj some tics further into the state it stands in: one
# for P_MobjThinker's count down, a random 0 to 3 for the shortened
# death P_KillMobj starts.
def Player.counted(+n: U32, +p: Player) -> Player:
  Player.hurting(p, V.Vec.set(Player.hurt(p), Sim.hurt.tics(), (Sim.Hurt.tics(Player.hurt(p)) - n : U32)))

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
def Sim.mobj.state(+row: V.Vec, +s: State) -> State:
  Sim.mobj.step(U32.is_eq(Sim.Hurt.tics(row), 4294967295), U32.is_eq(Sim.Hurt.tics(row), 1),
    H.Thing.Row.next(H.Thing.row(Sim.Hurt.state(row))), s)

def Sim.mobj.tics(+s: State) -> State:
  Sim.mobj.state(Player.hurt(State.player(s)), s)

# Doom's P_DropWeapon: the ready weapon enters its down state, whose
# A_Lower runs as it does.
def Sim.drop.weapon(ps: Psprites, +weapon: H.Thing.Weapon, s: State) -> State:
  Psprites{shown, flash} = ps
  Sim.psprites.lowered(flash, Sim.psprite.set(8n, Entering{Some{H.Thing.Weapon.down(weapon)}, None{}, shown, s},
    K.Cmd.idle(), weapon))

def Sim.drop(+s: State) -> State:
  Sim.drop.weapon(Player.psprites(State.player(s)), H.Thing.pistol(), s)

# The death state's tics, less the random 0 to 3 P_KillMobj takes off.
# Its 10 never reach vanilla's floor of 1.
def Sim.kill.tics(+s: State) -> State:
  State.player.put(s, Player.counted((M.Random.at(State.rnd(s)) .&. 3 : U32), State.player(s)))

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
def Sim.damage.pain(+s: State) -> State:
  Sim.damage.flinch(U32.is_lt(M.Random.at(State.rnd(s)), 255), s)

def Sim.damage.done(dead: Bool, +s: State) -> State:
  match dead:
    case True{}:
      Sim.kill(s)
    case False{}:
      Sim.damage.pain(Sim.drawn(s))

# The end of P_DamageMobj's player branch: the inventory the armour and
# the health left, the damage count grown by what reached the player and
# held at 100, and the blow's source kept as the attacker.
def Player.took(+p: Player, inv: I.Inventory, +left: U32, +source: U32) -> Player:
  Player.holding(Player.hurting(p, V.Vec.set(V.Vec.set(Player.hurt(p), Sim.hurt.damage(),
    U32.min((Sim.Hurt.damage(Player.hurt(p)) + left : U32), 100)), Sim.hurt.attacker(), source)), inv)

def Sim.damage.taken(hurt: I.Inventory & U32, +source: U32, +s: State) -> State:
  (+inv, +left) = hurt
  Sim.damage.done(I.Inventory.dead(inv),
    State.player.put(s, Player.took(State.player(s), inv, left, source)))

# P_DamageMobj's player branch: the armour takes its share and the
# health the rest, which kills where the health it leaves runs out,
# since vanilla holds the player's health at 0 exactly there. The god
# and skill branches are left out, since no cheat is ported and the game
# is Hurt Me Plenty, and so is the hack for sectors with special 11,
# which neither map carries.
def Sim.damage.player(+damage: U32, +source: U32, +s: State) -> State:
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
def Sim.blow.at(+level: L.Level, +p: Player, +ix: U32, +iy: U32, +damage: U32, back: Bool) -> Player:
  Sim.blow.thrown(level, p, A.Angle.of(L.Level.tanto(level), (Player.x(p) - ix : U32), (Player.y(p) - iy : U32)),
    (damage * 8192 : U32), back)

# The push, once the roll is known: the index stands where it was drawn.
def Sim.blow.push(rolls: Bool, +ix: U32, +iy: U32, +damage: U32, +i: U32, s: State) -> State:
  State{+player, +level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{Sim.blow.at(level, player, ix, iy, damage,
      Bool.and(rolls, Bool.not(U32.is_zero((M.Random.at(i) .&. 1 : U32))))),
    level, things, sidetex, thinkers, i, clock, ended, usedown, sounds, mrnd, reborn}

def Sim.blow.roll(+rolls: Bool, +ix: U32, +iy: U32, +damage: U32, +s: State) -> State:
  Sim.blow.push(rolls, ix, iy, damage,
    Bool.pick(U32, rolls, M.Random.next(State.rnd(s)), State.rnd(s)), s)

# Doom's P_DamageMobj's thrust: the blow pushes the player away from the
# inflictor, a hundred times an eighth of a unit a point of damage over
# the player's mass, which is a hundred. A lethal blow under 40 points
# from an inflictor more than 64 units below throws the player the other
# way, four times as hard, on an odd random number, which is drawn only
# where the other three tests pass, as C's && leaves it.
def Sim.blow(+ix: U32, +iy: U32, +iz: U32, +damage: U32, +s: State) -> State:
  Sim.blow.roll(Bool.and(U32.is_lt(damage, 40),
    Bool.and(F.Fixed.gt(damage, I.Inventory.health(Player.inv(State.player(s)))),
      F.Fixed.gt((Player.z(State.player(s)) - iz : U32), 4194304))), ix, iy, damage, s)

def Sim.damage.hit(m: Maybe<&2, H.Thing>, +damage: U32, +source: U32, +s: State) -> State:
  match m:
    case None{}:
      Sim.damage.player(damage, source, s)
    case Some{H.Thing{id, kind, +x, +y, +z, floorz, ceilz, angle, sector, state, tics, momz}}:
      Sim.damage.player(damage, source, Sim.blow(x, y, z, damage, s))

def Sim.damage.if(dead: Bool, +damage: U32, +inflictor: U32, +source: U32, +s: State) ->
  State:
  match dead:
    case True{}:
      s
    case False{}:
      Sim.damage.hit(Sim.named(U32.is_eq(inflictor, H.Thing.you()), State.things(s), inflictor), damage, source, s)

# Doom's P_DamageMobj for the player, the one function everything that
# hurts the player calls: how much, the thing that dealt the blow and
# the thing to blame for it, both absent for the nukage. A blow with an
# inflictor thrusts the player away from it; the armour then takes its
# share of the damage and the player takes the rest. A player already
# dead takes none. The chainsaw's exemption from the thrust waits for a
# ready weapon to read.
def Sim.damage(damage: U32, inflictor: U32, source: U32, +s: State) -> State:
  Sim.damage.if(Player.dead(State.player(s)), damage, inflictor, source, s)

# The sector's special
# --------------------

def Sim.sector.hurt(due: Bool, s: State) -> State:
  match due:
    case False{}:
      s
    case True{}:
      Sim.damage(5, H.Thing.you(), H.Thing.you(), s)

# Doom's P_PlayerInSpecialSector on the sector under the player: special
# 7 is nukage, which takes 5 health every 32 tics of the level's clock
# while the player's feet are at that sector's floor. It is the only
# special either map carries that hurts, so the switch is the one test.
# Neither map spawns a radiation suit on this skill, so the suit's
# protection has no code.
def Sim.sector(+level: L.Level, +clock: U32, +s: State) -> State:
  +sector = L.Level.sector_at(level, Player.x(State.player(s)), Player.y(State.player(s)))
  Sim.sector.hurt(Bool.and(U32.is_eq(L.Level.sector.special(State.level(s), sector), 7),
    Bool.and(U32.is_zero((clock .&. 31 : U32)),
      U32.is_eq(Player.z(State.player(s)), L.Level.floor(level, sector)))), s)

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
    Bool.pick(V.Vec, near, Sim.Hurt.fade(hurt), hurt)}

# Who the dying view turns to: the attacker, or, with none to turn to,
# its own facing, which leaves the view where it is and fades the count,
# as P_DeathThink's other branch does.
def Sim.death.faced(m: Maybe<&2, H.Thing>, +level: L.Level, +p: Player) -> Player:
  match m:
    case None{}:
      Player.turned(True{}, Player.angle(p), 0, p)
    case Some{H.Thing{id, kind, +x, +y, z, floorz, ceilz, angle, sector, state, tics, momz}}:
      +to = A.Angle.of(L.Level.tanto(level), (x - Player.x(p) : U32), (y - Player.y(p) : U32))
      +delta = (to - Player.angle(p) : U32)
      Player.turned(Bool.or(U32.is_lt(delta, Sim.ang5()), U32.is_gt(delta, F.Fixed.neg(Sim.ang5()))), to, delta, p)

# A press of use asks for the level again: Doom's PST_REBORN, which
# G_DoReborn answers outside the playsim by loading the level, and which
# holds until it is answered.
def Sim.death.asked(use: Bool, s: State) -> State:
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, Bool.or(reborn, use)}

# Doom's P_DeathThink for the player alone: the player sprites move, the
# view sinks and is worked out again, and the facing turns to the
# attacker. Nothing else of P_PlayerThink runs: no move, no sector
# special, no use of a line and no counters, so the damage count fades
# here alone.
def Sim.death(+level: L.Level, +clock: U32, m: Maybe<&2, H.Thing>, s: State) -> Player:
  Sim.death.faced(m, level, Sim.eye(level, clock, Player.sinking(State.player(Sim.psprites(K.Cmd.idle(), s)))))

# The tic
# -------

# Use acts on the tic it goes down, not while it is held.
def Sim.pressed(cmd: K.Cmd, usedown: Bool) -> Bool:
  Bool.and(Bool.not(usedown), K.Cmd.use(cmd))

# The player where it stood before a thinker's turn, as the turn left
# it otherwise, the lines it crossed fired and forgotten.
def Player.held(before: Player, after: Player) -> Player:
  Player{x, y, bz, ba, bmomx, bmomy, bmomz, bfloorz, bceilz, bviewheight, bdeltaview, bviewz, bcrossed, binv, bpsprites, bhurt} = before
  Player{ax, ay, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt} = after
  Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, [], inv, psprites, hurt}

# What a turn keeps of the state it began with, whatever it did: the
# geometry, so no tic writes a wall, and the player's place, so nothing
# but the player's own movement moves the player sideways.
def State.held(geo: L.Level.Geo, before: State, after: State) -> State:
  State{was, wlevel, wthings, wsidetex, wthinkers, wrnd, wclock, wended, wusedown, wsounds, wmrnd, wreborn} = before
  State{player, L.Level{g, sectors, specials}, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = after
  State{Player.held(was, player), L.Level{geo, sectors, specials}, things, sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd, reborn}

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
# began with, whose geometry the wall law reads; the lines that movement
# crossed fire, the mobj goes through its own states, which time its
# pain and its death, and the thinker is kept.
def Sim.mobj(+cmd: K.Cmd, +geo: L.Level.Geo, +s: State) -> State:
  +level = {L.Level{geo, L.Level.sectors(State.level(s)), L.Level.specials(State.level(s))} : L.Level}
  +went = State.moved(Sim.mobj.z(Sim.xy(level, State.things(s), cmd, State.player(s))), level, s)
  State.kept(State.held(geo, went, Sim.mobj.tics(Sim.cross(Player.crossed(State.player(went)), went))),
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
    case f <> rest State{player, level, things, sidetex, Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      State{player, level, things, sidetex, Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd, reborn}
    case f <> rest State{player, level, +things, sidetex, Thinkers{ran, +t <> due}, rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      Sim.thinkers.go(rest, cmd, geo, Sim.turn(Sim.mine(t, H.Things.you(things)), t, cmd, geo,
        State{player, level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn}))

# Runs until none is due: the thinkers a run started run in the next, the
# same tic, as those added to the tail of Doom's list do. The fuel is
# how deep that may go; past it they wait a tic.
def Sim.thinkers.all(fuel: Nat, +cmd: K.Cmd, +geo: L.Level.Geo, s: State) -> State:
  match fuel s:
    case 0n s:
      s
    case 1n+f State{player, level, things, sidetex, Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      State{player, level, things, sidetex, Thinkers{ran, []}, rnd, clock, ended, usedown, sounds, mrnd, reborn}
    case 1n+f State{player, level, things, sidetex, Thinkers{ran, +t <> +due}, rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      Sim.thinkers.all(f, cmd, geo, Sim.thinkers.go(t <> due, cmd, geo,
        State{player, level, things, sidetex, Thinkers{ran, t <> due}, rnd, clock, ended, usedown, sounds, mrnd, reborn}))

# The thinkers all due again, in the order they were started.
def State.rested(s: State) -> State:
  State{player, level, things, sidetex, Thinkers{ran, due}, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, level, things, sidetex, Thinkers{[], List.append(&2, Thinker, List.reverse(&2, Thinker, ran), due)},
    rnd, clock, ended, usedown, sounds, mrnd, reborn}

# Doom's P_RunThinkers.
def Sim.thinkers(+cmd: K.Cmd, +geo: L.Level.Geo, s: State) -> State:
  State.rested(Sim.thinkers.all(8n, cmd, geo, s))

# What a live tic makes of the state its thinkers left: the geometry it
# began with, the clock counted, and whether use was down.
def Sim.tic.kept(geo: L.Level.Geo, clock: U32, use: Bool, +after: State) -> State:
  State{State.player(after), L.Level{geo, L.Level.sectors(State.level(after)), L.Level.specials(State.level(after))},
    State.things(after), State.sidetex(after), State.thinkers.of(after), State.rnd(after), (clock + 1 : U32),
    State.ended(after), use, State.sounds(after), State.face(after), State.reborn(after)}

# One tic in Doom's order: the player thinks (the move, the eye, use on
# the press, the player sprites, the counters), the thinkers run in
# the order they were started (the mobjs of the map's records, the
# player's among them, whose own turn moves the player and fires the
# lines that move crossed, then the lights, then what play started), the
# clock counts. The tic's sounds start from none, and what the things
# were heard doing is reported when its last thinker has run. An ended
# level stands still: no tic runs, so its sounds stay the last live
# tic's, and whoever gathers sounds tic by tic passes over it.
# Doom's P_PlayerThink for a living player, in its order: the move, the
# eye, what the sector's special deals, then the player sprites and the
# counters.
# P_PlayerThink's counters, once the sprites have moved.
def Sim.player.counted(+s: State) -> State:
  State.player.put(s, Sim.counters(State.player(s)))

def Sim.player.live(+cmd: K.Cmd, +level: L.Level, +clock: U32, +s: State) -> State:
  +hurt = Sim.sector(level, clock,
    State.player.put(s, Sim.eye(level, clock, Sim.move(level, cmd, State.player(s)))))
  Sim.player.counted(Sim.psprites(cmd, hurt))

# Doom's P_DeathThink: the sprites move, the view sinks and turns to the
# attacker, and use asks for the level again.
def Sim.player.dead(+level: L.Level, +clock: U32, use: Bool, +s: State) -> State:
  +asked = Sim.death.asked(use, s)
  State.player.put(asked, Sim.death(level, clock,
    Sim.named(U32.is_eq(Sim.Hurt.attacker(Player.hurt(State.player(asked))), H.Thing.you()),
      State.things(asked), Sim.Hurt.attacker(Player.hurt(State.player(asked)))), asked))

# Doom's P_PlayerThink: a dead player thinks of dying alone. Neither
# think moves the player, which the mobj's own turn does, so the tic
# holds the place across it.
def Sim.player(dead: Bool, +cmd: K.Cmd, +level: L.Level, +clock: U32, +s: State) -> State:
  match dead:
    case False{}:
      Sim.player.live(cmd, level, clock, s)
    case True{}:
      Sim.player.dead(level, clock, K.Cmd.use(cmd), s)

# One tic in Doom's order: the player thinks, use acts on the press,
# which a dead player never makes, the thinkers run in the order they
# were started (the mobjs of the map's records, the player's among them,
# whose own turn moves the player and fires the lines that move
# crossed), the clock counts. The tic's sounds start from none, and what
# the things were heard doing is reported when its last thinker has run.
# An ended level stands still: no tic runs, so its sounds stay the last
# live tic's, and whoever gathers sounds tic by tic passes over it.
def Sim.tic.done(+cmd: K.Cmd, +geo: L.Level.Geo, +clock: U32, before: State, after: State) -> State:
  Sim.tic.kept(geo, clock, K.Cmd.use(cmd), State.told(Sim.thinkers(cmd, geo, State.held(geo, before, after))))

# Doom's ST_Ticker, which G_Ticker runs after P_Ticker, so its draw
# comes after every sound that tic started: a number from M_Random for
# the tic, the face widget over it, and the health the next tic looks
# back at. Held fire is read from the tic command, since A_WeaponReady's
# attackdown has no field of its own (ticket 11).
def Sim.st.ticker(attack: Bool, s: State) -> State:
  State{+player, +level, +things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  State{player, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds,
    Sim.face.tic(attack, level, things, player, Sim.Face.drew(True{}, mrnd)), reborn}

def Sim.tic.live(+cmd: K.Cmd, +level: L.Level, +geo: L.Level.Geo, +clock: U32, +usedown: Bool, +dead: Bool,
  +before: State) -> State:
  Sim.st.ticker(K.Cmd.attack(cmd), Sim.tic.done(cmd, geo, clock, before,
    Sim.use(Bool.and(Bool.not(dead), Sim.pressed(cmd, usedown)), Sim.player(dead, cmd, level, clock, before))))

def Sim.tic(+cmd: K.Cmd, s: State) -> State:
  match s:
    case State{player, level, things, sidetex, thinkers, rnd, clock, True{}, usedown, sounds, mrnd, reborn}:
      State{player, level, things, sidetex, thinkers, rnd, clock, True{}, usedown, sounds, mrnd, reborn}
    case State{+player, L.Level{+geo, sectors, specials}, things, sidetex, thinkers, rnd, +clock, False{}, +usedown, sounds, mrnd, reborn}:
      +level = {L.Level{geo, sectors, specials} : L.Level}
      Sim.tic.live(cmd, level, geo, clock, usedown, Player.dead(player),
        {State{player, level, things, sidetex, thinkers, rnd, clock, False{}, usedown, [], mrnd, reborn} : State})

# A tic for each command of the list, in order: a demo.
def Sim.replay(script: List<&2, K.Cmd>, s: State) -> State:
  match script:
    case []:
      s
    case cmd <> rest:
      Sim.replay(rest, Sim.tic(cmd, s))
