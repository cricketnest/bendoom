# Doom's info.c, P_SpawnMobj, P_SpawnMapThing, P_SetThingPosition,
# P_RemoveMobj, P_ZMovement and the state half of P_MobjThinker for the
# things Bendoom spawns: the definitions of the DoomEd types either E1M1
# places, less the starts and the spectre, which Hurt Me Plenty never
# spawns, the state rows their spawn states lead to and the pistol's
# with its entry in d_items.c's weaponinfo and the bullet puff's, the
# map's THINGS records made the level's first things, a thing's tic
# through its states and up by its vertical momentum, and the population
# with its blockmap and sector links.
import Base
import ./fixed.bend as F
import ./angle.bend as A
import ./level.bend as L
import ./random.bend as M
import ./vec.bend as V
import ./sound.bend as Sn

# A thing, Doom's mobj: its id, which names it for good (its THINGS
# record's index, or the next id past every one given for a thing spawned
# in play), its DoomEd type, its position with z on the floor or under the
# ceiling, the floor and ceiling it is held between, its facing, the
# sector under it, its state row, the tics left in it, and its vertical
# momentum.
type Thing is Data:
  Thing{id: U32, kind: U32, x: U32, y: U32, z: U32, floorz: U32, ceilz: U32, angle: U32, sector: U32, state: U32,
    tics: U32, momz: U32}

# The player's id on a map with no start for it: one no record has.
def Thing.you() -> U32:
  4294967295

# Doom's S_NULL, the state that is no state: a thing that enters it
# removes itself, and a player sprite that enters it stops showing.
def Thing.null() -> U32:
  4294967295

# What a state row does as it is entered, Doom's action pointers: a
# weapon's A_Raise, A_WeaponReady, A_Lower, A_FirePistol and A_ReFire, a
# mobj's A_Pain and A_PlayerScream, or nothing. A row of one kind never
# holds the other's.
type Thing.Action is Data:
  Null{}
  Raise{}
  WeaponReady{}
  FirePistol{}
  ReFire{}
  Lower{}
  Pain{}
  Scream{}

# A state row, Doom's state_t: the sprite's four-letter name, the frame
# (0 for A), whether it is full-bright, its tics, the row after it, its
# action, and the extra light a muzzle flash showing it lends the view.
# A row of -1 tics lasts, and it stores itself as its next, where
# vanilla's is S_NULL; no tic reads it, and the sprite load's chase stops
# there. Vanilla sets the extra light from A_Light0, A_Light1 and
# A_Light2, which no state but a flash's carries and which always run as
# that state is entered, so the row says it and the player need not.
type Thing.Row is Data:
  Row{sprite: String, frame: U32, bright: Bool, tics: U32, next: U32, action: Thing.Action, light: U32}

# The state rows by Bendoom's number: every state the spawn states of the
# types below lead to, in vanilla's order, then the pistol's ready and
# raise states, then the monsters' two idle states each, whose A_Look is
# not run yet, then the pistol's down state and the player mobj's own,
# whose death ends in row 0, the corpse a dead marine record spawns in,
# then the pistol's fire states, its muzzle flash's, the state that puts
# the flash's light out and the bullet puff's. Only S_LIGHTDONE, row 84,
# has 0 tics, and it is a player sprite's; it carries A_Light0 in
# vanilla and here only puts the light out by being the last row before
# S_NULL.
def Thing.rows() -> List<&2, Thing.Row>:
  [Row{"PLAY", 13, False{}, 4294967295, 0, Null{}, 0}, Row{"PLAY", 22, False{}, 4294967295, 1, Null{}, 0},
    Row{"POSS", 11, False{}, 4294967295, 2, Null{}, 0}, Row{"SPOS", 11, False{}, 4294967295, 3, Null{}, 0},
    Row{"TROO", 12, False{}, 4294967295, 4, Null{}, 0}, Row{"SARG", 13, False{}, 4294967295, 5, Null{}, 0},
    Row{"ARM1", 0, False{}, 6, 7, Null{}, 0}, Row{"ARM1", 1, True{}, 7, 6, Null{}, 0}, Row{"ARM2", 0, False{}, 6, 9, Null{}, 0},
    Row{"ARM2", 1, True{}, 6, 8, Null{}, 0}, Row{"BAR1", 0, False{}, 6, 11, Null{}, 0},
    Row{"BAR1", 1, False{}, 6, 10, Null{}, 0}, Row{"BON1", 0, False{}, 6, 13, Null{}, 0},
    Row{"BON1", 1, False{}, 6, 14, Null{}, 0}, Row{"BON1", 2, False{}, 6, 15, Null{}, 0},
    Row{"BON1", 3, False{}, 6, 16, Null{}, 0}, Row{"BON1", 2, False{}, 6, 17, Null{}, 0},
    Row{"BON1", 1, False{}, 6, 12, Null{}, 0}, Row{"BON2", 0, False{}, 6, 19, Null{}, 0},
    Row{"BON2", 1, False{}, 6, 20, Null{}, 0}, Row{"BON2", 2, False{}, 6, 21, Null{}, 0},
    Row{"BON2", 3, False{}, 6, 22, Null{}, 0}, Row{"BON2", 2, False{}, 6, 23, Null{}, 0},
    Row{"BON2", 1, False{}, 6, 18, Null{}, 0}, Row{"BKEY", 0, False{}, 10, 25, Null{}, 0},
    Row{"BKEY", 1, True{}, 10, 24, Null{}, 0}, Row{"STIM", 0, False{}, 4294967295, 26, Null{}, 0},
    Row{"MEDI", 0, False{}, 4294967295, 27, Null{}, 0}, Row{"SOUL", 0, True{}, 6, 29, Null{}, 0},
    Row{"SOUL", 1, True{}, 6, 30, Null{}, 0}, Row{"SOUL", 2, True{}, 6, 31, Null{}, 0},
    Row{"SOUL", 3, True{}, 6, 32, Null{}, 0}, Row{"SOUL", 2, True{}, 6, 33, Null{}, 0},
    Row{"SOUL", 1, True{}, 6, 28, Null{}, 0}, Row{"PSTR", 0, True{}, 4294967295, 34, Null{}, 0},
    Row{"CLIP", 0, False{}, 4294967295, 35, Null{}, 0}, Row{"AMMO", 0, False{}, 4294967295, 36, Null{}, 0},
    Row{"ROCK", 0, False{}, 4294967295, 37, Null{}, 0}, Row{"BROK", 0, False{}, 4294967295, 38, Null{}, 0},
    Row{"CELL", 0, False{}, 4294967295, 39, Null{}, 0}, Row{"CELP", 0, False{}, 4294967295, 40, Null{}, 0},
    Row{"SHEL", 0, False{}, 4294967295, 41, Null{}, 0}, Row{"SBOX", 0, False{}, 4294967295, 42, Null{}, 0},
    Row{"BPAK", 0, False{}, 4294967295, 43, Null{}, 0}, Row{"MGUN", 0, False{}, 4294967295, 44, Null{}, 0},
    Row{"CSAW", 0, False{}, 4294967295, 45, Null{}, 0}, Row{"LAUN", 0, False{}, 4294967295, 46, Null{}, 0},
    Row{"PLAS", 0, False{}, 4294967295, 47, Null{}, 0}, Row{"SHOT", 0, False{}, 4294967295, 48, Null{}, 0},
    Row{"COLU", 0, True{}, 4294967295, 49, Null{}, 0}, Row{"POL5", 0, False{}, 4294967295, 50, Null{}, 0},
    Row{"POL6", 0, False{}, 6, 52, Null{}, 0}, Row{"POL6", 1, False{}, 8, 51, Null{}, 0},
    Row{"GOR4", 0, False{}, 4294967295, 53, Null{}, 0}, Row{"SMIT", 0, False{}, 4294967295, 54, Null{}, 0},
    Row{"CBRA", 0, True{}, 4294967295, 55, Null{}, 0}, Row{"TRE1", 0, False{}, 4294967295, 56, Null{}, 0},
    Row{"TRE2", 0, False{}, 4294967295, 57, Null{}, 0}, Row{"ELEC", 0, False{}, 4294967295, 58, Null{}, 0},
    Row{"PISG", 0, False{}, 1, 59, WeaponReady{}, 0}, Row{"PISG", 0, False{}, 1, 60, Raise{}, 0},
    Row{"POSS", 0, False{}, 10, 62, Null{}, 0}, Row{"POSS", 1, False{}, 10, 61, Null{}, 0},
    Row{"SPOS", 0, False{}, 10, 64, Null{}, 0}, Row{"SPOS", 1, False{}, 10, 63, Null{}, 0},
    Row{"TROO", 0, False{}, 10, 66, Null{}, 0}, Row{"TROO", 1, False{}, 10, 65, Null{}, 0},
    Row{"SARG", 0, False{}, 10, 68, Null{}, 0}, Row{"SARG", 1, False{}, 10, 67, Null{}, 0},
    Row{"PISG", 0, False{}, 1, 69, Lower{}, 0}, Row{"PLAY", 0, False{}, 4294967295, 70, Null{}, 0},
    Row{"PLAY", 6, False{}, 4, 72, Null{}, 0}, Row{"PLAY", 6, False{}, 4, 70, Pain{}, 0},
    Row{"PLAY", 7, False{}, 10, 74, Null{}, 0}, Row{"PLAY", 8, False{}, 10, 75, Scream{}, 0},
    Row{"PLAY", 9, False{}, 10, 76, Null{}, 0}, Row{"PLAY", 10, False{}, 10, 77, Null{}, 0},
    Row{"PLAY", 11, False{}, 10, 78, Null{}, 0}, Row{"PLAY", 12, False{}, 10, 0, Null{}, 0},
    Row{"PISG", 0, False{}, 4, 80, Null{}, 0}, Row{"PISG", 1, False{}, 6, 81, FirePistol{}, 0},
    Row{"PISG", 2, False{}, 4, 82, Null{}, 0}, Row{"PISG", 1, False{}, 5, 59, ReFire{}, 0},
    Row{"PISF", 0, True{}, 7, 84, Null{}, 1}, Row{"SHTG", 4, False{}, 0, 4294967295, Null{}, 0},
    Row{"PUFF", 0, True{}, 4, 86, Null{}, 0}, Row{"PUFF", 1, False{}, 4, 87, Null{}, 0},
    Row{"PUFF", 2, False{}, 4, 88, Null{}, 0}, Row{"PUFF", 3, False{}, 4, 4294967295, Null{}, 0}]

def Thing.row(s: U32) -> Thing.Row:
  Maybe.default(&2, Thing.Row, List.get(&2, Thing.Row, Thing.rows(), U32.to_nat(s)),
    Row{"", 0, False{}, 0, 0, Null{}, 0})

def Thing.Row.tics(r: Thing.Row) -> U32:
  Row{sprite, frame, bright, tics, next, action, light} = r
  tics

def Thing.Row.bright(r: Thing.Row) -> Bool:
  Row{sprite, frame, bright, tics, next, action, light} = r
  bright

def Thing.Row.next(r: Thing.Row) -> U32:
  Row{sprite, frame, bright, tics, next, action, light} = r
  next

def Thing.Row.action(r: Thing.Row) -> Thing.Action:
  Row{sprite, frame, bright, tics, next, action, light} = r
  action

# Doom's extralight for a player sprite showing this row.
def Thing.Row.light(r: Thing.Row) -> U32:
  Row{sprite, frame, bright, tics, next, action, light} = r
  light

# A weapon's row in Doom's weaponinfo: the states it rises, is ready,
# sinks and fires in, its muzzle flash's, and the ammotype_t it spends,
# which the status bar counts.
type Thing.Weapon is Data:
  Weapon{up: U32, ready: U32, down: U32, ammo: U32, atk: U32, flash: U32}

# d_items.c's weaponinfo for the pistol: it rises in row 60, rests in
# row 59, sinks in row 69, spends am_clip, ammotype_t 0, fires from row
# 79 and flashes in row 83.
def Thing.pistol() -> Thing.Weapon:
  Weapon{60, 59, 69, 0, 79, 83}

def Thing.Weapon.down(w: Thing.Weapon) -> U32:
  Weapon{up, ready, down, ammo, atk, flash} = w
  down

def Thing.Weapon.ammo(w: Thing.Weapon) -> U32:
  Weapon{up, ready, down, ammo, atk, flash} = w
  ammo

# The player mobj's rows in Doom's mobjinfo: the state it stands in,
# the one it flinches in and the one its death begins with. Its spawn
# health, 100, is the inventory's.
def Thing.play() -> U32:
  70

def Thing.play.pain() -> U32:
  71

def Thing.play.death() -> U32:
  73

type Thing.Def is Data:
  Def{kind: U32, state: U32, radius: U32, height: U32, flags: U32}

def Thing.defs() -> List<&2, Thing.Def>:
  [Def{5, 24, 20, 16, 33554433}, Def{8, 43, 20, 16, 1}, Def{10, 1, 20, 16, 0}, Def{12, 1, 20, 16, 0},
    Def{15, 0, 20, 16, 0}, Def{17, 40, 20, 16, 1}, Def{18, 2, 20, 16, 0}, Def{19, 3, 20, 16, 0},
    Def{20, 4, 20, 16, 0}, Def{21, 5, 20, 16, 0}, Def{24, 50, 20, 16, 0}, Def{26, 51, 16, 16, 2},
    Def{35, 55, 16, 16, 2}, Def{43, 56, 16, 16, 2}, Def{47, 54, 16, 16, 2}, Def{48, 58, 16, 16, 2},
    Def{54, 57, 32, 16, 2}, Def{60, 53, 20, 68, 768}, Def{2001, 48, 20, 16, 1}, Def{2002, 44, 20, 16, 1},
    Def{2003, 46, 20, 16, 1}, Def{2004, 47, 20, 16, 1}, Def{2005, 45, 20, 16, 1}, Def{2007, 35, 20, 16, 1},
    Def{2008, 41, 20, 16, 1}, Def{2010, 37, 20, 16, 1}, Def{2011, 26, 20, 16, 1}, Def{2012, 27, 20, 16, 1},
    Def{2013, 28, 20, 16, 8388609}, Def{2014, 12, 20, 16, 8388609}, Def{2015, 18, 20, 16, 8388609},
    Def{2018, 6, 20, 16, 1}, Def{2019, 8, 20, 16, 1}, Def{2023, 34, 20, 16, 8388609}, Def{2028, 49, 16, 16, 2},
    Def{2035, 10, 10, 42, 524294}, Def{2046, 38, 20, 16, 1}, Def{2047, 39, 20, 16, 1}, Def{2048, 36, 20, 16, 1},
    Def{2049, 42, 20, 16, 1}, Def{3004, 61, 20, 56, 4194310}, Def{9, 63, 20, 56, 4194310},
    Def{3001, 65, 20, 56, 4194310}, Def{3002, 67, 30, 56, 4194310}, Def{4294967295, 85, 20, 16, 528}]

# MT_PUFF's DoomEd type, -1: no THINGS record can name it, so the puff
# only ever spawns from a shot.
def Thing.puff() -> U32:
  4294967295

def Thing.Def.kind(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  kind

# A type's radius in fixed point.
def Thing.Def.radius(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  F.Fixed.of_map(radius)

# A type's height in map units.
def Thing.Def.height(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  height

def Thing.Def.flags(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  flags

# Doom's MF_NOBLOCKMAP: a mobj of the type is in no blockmap cell, so
# nothing that walks the blockmap ever meets it.
def Thing.Def.unlisted(d: Thing.Def) -> Bool:
  Bool.not(U32.is_zero((Thing.Def.flags(d) .&. 16 : U32)))

def Thing.def.put(d: Thing.Def, found: Maybe<&2, Thing.Def>, hit: Bool) -> Maybe<&2, Thing.Def>:
  match hit:
    case True{}:
      Some{d}
    case False{}:
      found

def Thing.def.go(defs: List<&2, Thing.Def>, +kind: U32) -> Maybe<&2, Thing.Def>:
  match defs:
    case []:
      None{}
    case +d <> rest:
      Thing.def.put(d, Thing.def.go(rest, kind), U32.is_eq(Thing.Def.kind(d), kind))

# The definition of a DoomEd type, none for a type Bendoom does not
# spawn.
def Thing.def(kind: U32) -> Maybe<&2, Thing.Def>:
  Thing.def.go(Thing.defs(), kind)

# The definition of a spawned thing's type.
def Thing.info(+kind: U32) -> Thing.Def:
  Maybe.default(&2, Thing.Def, Thing.def(kind), Def{kind, 0, 0, 0, 0})

# Doom's P_MobjThinker for a thing that does not move: a lasting state
# stays as it is; another counts its tics down, and the tic they run out
# the thing enters the next state for that state's tics. A thing that
# enters S_NULL keeps it as its row, and its caller removes it.
def Thing.tic.step(lasting: Bool, out: Bool, thing: Thing) -> Thing:
  match lasting out thing:
    case True{} _ _:
      thing
    case False{} True{} Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz}:
      +next = Thing.Row.next(Thing.row(state))
      Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, next, Thing.Row.tics(Thing.row(next)), momz}
    case False{} False{} Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz}:
      Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, (tics - 1 : U32), momz}

# Doom's P_ZMovement's clip, under the ceiling: a rising mobj that meets
# it stops there.
def Thing.z.ceiling(hit: Bool, +z: U32, +momz: U32, +ceilz: U32, +height: U32) -> U32 & U32:
  match hit:
    case True{}:
      ((ceilz - height : U32), Bool.pick(U32, F.Fixed.gt(momz, 0), 0, momz))
    case False{}:
      (z, momz)

# Doom's P_ZMovement for the things Bendoom moves: the mobj rises by its
# momentum and stops where the floor or the ceiling is. Gravity has no
# caller, since every thing that leaves its floor is flagged without it.
def Thing.z.floor(hit: Bool, +z: U32, +momz: U32, +floorz: U32, +ceilz: U32, +height: U32) -> U32 & U32:
  match hit:
    case True{}:
      Thing.z.ceiling(F.Fixed.gt((floorz + height : U32), ceilz), floorz, 0, ceilz, height)
    case False{}:
      Thing.z.ceiling(F.Fixed.gt((z + height : U32), ceilz), z, momz, ceilz, height)

def Thing.z.put(thing: Thing, zm: U32 & U32) -> Thing:
  Thing{id, kind, x, y, was, floorz, ceilz, angle, sector, state, tics, old} = thing
  (z, momz) = zm
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz}

def Thing.z(thing: Thing) -> Thing:
  Thing{id, +kind, x, y, +z, +floorz, +ceilz, angle, sector, state, tics, +momz} = thing
  +height = F.Fixed.of_map(Thing.Def.height(Thing.info(kind)))
  Thing.z.put(Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz},
    Thing.z.floor(F.Fixed.le((z + momz : U32), floorz), (z + momz : U32), momz, floorz, ceilz, height))

# The vertical half of Doom's P_MobjThinker, run for a mobj off its
# floor or with momentum, as vanilla runs P_ZMovement. A thing that
# stands still never asks for its type, which is a search.
def Thing.tic.z(moves: Bool, thing: Thing) -> Thing:
  match moves:
    case False{}:
      thing
    case True{}:
      Thing.z(thing)

def Thing.tic(thing: Thing) -> Thing:
  Thing{id, kind, x, y, +z, +floorz, ceilz, angle, sector, state, +tics, +momz} = thing
  Thing.tic.step(U32.is_eq(tics, 4294967295), U32.is_eq(tics, 1),
    Thing.tic.z(Bool.or(Bool.not(U32.is_eq(z, floorz)), Bool.not(U32.is_zero(momz))),
      Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz}))

# Whether a thing has entered S_NULL and so removed itself.
def Thing.gone(thing: Thing) -> Bool:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, +state, tics, momz} = thing
  U32.is_eq(state, Thing.null())

# Doom's ONFLOORZ and ONCEILINGZ: a z that asks P_SpawnMobj for the
# floor, or for the thing's height under the ceiling.
def Thing.onfloor() -> U32:
  2147483648

def Thing.onceiling() -> U32:
  2147483647

# Doom's P_SpawnMobj, less its random draw, which its caller makes: a
# thing of a type named id at (x, y) and z, in its first state for that
# state's tics, facing east, held between the floor and ceiling of the
# sector under it.
def Thing.mobj(d: Thing.Def, +level: L.Level, id: U32, +x: U32, +y: U32, +z: U32) -> Thing:
  Def{kind, +state, radius, height, flags} = d
  +sector = L.Level.sector_at(level, x, y)
  +floor = L.Level.floor(level, sector)
  +ceil = L.Level.ceil(level, sector)
  Thing{id, kind, x, y, Bool.pick(U32, U32.is_eq(z, Thing.onfloor()), floor,
      Bool.pick(U32, U32.is_eq(z, Thing.onceiling()), (ceil - F.Fixed.of_map(height) : U32), z)), floor, ceil, 0,
    sector, state, Thing.Row.tics(Thing.row(state)), 0}

# The thing with its centre at another place, in the sector under it.
def Thing.at(th: Thing, level: L.Level, +x: U32, +y: U32) -> Thing:
  Thing{id, kind, ox, oy, z, floorz, ceilz, angle, was, state, tics, momz} = th
  Thing{id, kind, x, y, z, floorz, ceilz, angle, L.Level.sector_at(level, x, y), state, tics, momz}

# The things spawned, the last first while they spawn, the random
# index, and player 1's start record, the player's own name before one
# spawns.
type Thing.Spawn is Data:
  Spawn{things: List<&2, Thing>, rnd: U32, you: U32}

def Thing.spawn.facing(th: Thing, angle: U32, tics: U32) -> Thing:
  Thing{id, kind, x, y, z, floorz, ceilz, east, sector, state, first, momz} = th
  Thing{id, kind, x, y, z, floorz, ceilz, A.Angle.of_thing(angle), sector, state, tics, momz}

# The rest of Doom's P_SpawnMapThing: one random number drawn for the
# mobj, and one more for a state that runs out, which lasts that number
# modulo its tics, plus one. It stands on the floor or hangs from the
# ceiling, and faces the record's angle.
def Thing.spawn.mobj(+d: Thing.Def, +level: L.Level, id: U32, x: U32, y: U32, angle: U32, s: Thing.Spawn) ->
  Thing.Spawn:
  Def{kind, state, radius, height, flags} = d
  Spawn{things, rnd, you} = s
  +tics = Thing.Row.tics(Thing.row(state))
  +drawn = M.Random.next(rnd)
  +runs = F.Fixed.gt(tics, 0)
  +after = Bool.pick(U32, runs, M.Random.next(drawn), drawn)
  Spawn{Thing.spawn.facing(Thing.mobj(d, level, id, x, y,
      Bool.pick(U32, U32.is_zero((flags .&. 256 : U32)), Thing.onfloor(), Thing.onceiling())), angle,
    Bool.pick(U32, runs, (M.Random.at(after) % tics + 1 : U32), tics)) <> things, after, you}

def Thing.spawn.if(player: Bool, skill: Bool, info: Maybe<&2, Thing.Def>, +level: L.Level, +id: U32, +x: U32,
  +y: U32, angle: U32, s: Thing.Spawn) -> Thing.Spawn:
  match player skill info:
    case True{} _ _:
      Spawn{things, rnd, +you} = s
      Spawn{things, M.Random.next(rnd), Bool.pick(U32, U32.is_lt(id, you), id, you)}
    case False{} True{} Some{d}:
      Thing.spawn.mobj(d, level, id, x, y, angle, s)
    case _ _ _:
      s

# Doom's P_SpawnMapThing on Hurt Me Plenty with one player: player 1's
# start spawns the player, who draws a random number too and takes the
# first such record's index for its name, the start
# Level.start_of places it at; another record spawns when its options
# set that skill's bit, 2, and not the multiplayer bit, 16, and its type
# has a definition.
def Thing.spawn.one(+level: L.Level, id: U32, record: L.Level.Thing, s: Thing.Spawn) -> Thing.Spawn:
  L.Thing{x, y, angle, +kind, +options} = record
  Thing.spawn.if(U32.is_eq(kind, 1), Bool.and(Bool.not(U32.is_zero((options .&. 2 : U32))),
    U32.is_zero((options .&. 16 : U32))), Thing.def(kind), level, id, x, y, angle, s)

def Thing.spawn.go(n: Nat, +level: L.Level, +i: U32, s: Thing.Spawn) -> Thing.Spawn:
  match n:
    case 0n:
      s
    case 1n+m:
      Thing.spawn.go(m, level, (i + 1 : U32), Thing.spawn.one(level, i, L.Level.thing(level, i), s))

def Thing.spawn.done(s: Thing.Spawn) -> Thing.Spawn:
  Spawn{things, rnd, you} = s
  Spawn{List.reverse(&2, Thing, things), rnd, you}

# The level's first things, in the order of their records, and the
# random index once they have spawned, from 0.
def Thing.spawn(+level: L.Level) -> Thing.Spawn:
  Thing.spawn.done(Thing.spawn.go(U32.to_nat(L.Level.nthings(level)), level, 0, Spawn{[], 0, Thing.you()}))

def Thing.ambush.of(record: L.Level.Thing, mapped: Bool) -> Bool:
  L.Thing{x, y, angle, kind, options} = record
  Bool.and(mapped, Bool.not(U32.is_zero((options .&. 8 : U32))))

# Doom's MF_AMBUSH, which P_SpawnMapThing sets from bit 8 of the record's
# options: a map thing's id is its record's index, so the record keeps
# the flag, and a thing spawned in play, its id past the records, has
# none.
def Thing.ambush(+level: L.Level, +id: U32) -> Bool:
  Thing.ambush.of(L.Level.thing(level, id), U32.is_lt(id, L.Level.nthings(level)))

# The population
# --------------

# The things alive by id, among ids from 0 to count, the player's id,
# and Doom's links: the ids in each blockmap cell and in each sector,
# the last linked first, the player's among them. A thing spawned in
# play takes the count for its id, so no id ever names two things. Last,
# what the things did that is heard and the state has not reported yet:
# a position check has no state to tell.
type Things is Data:
  Things{tree: V.Tree<Thing>, count: U32, you: U32, cells: V.Tree<List<&2, U32>>,
    sectors: V.Tree<List<&2, U32>>, heard: List<&2, Sn.Sound.Event>}

# No things, the ids under count kept for the map's records, with a
# list for each of so many blockmap cells and sectors.
def Things.none(+count: U32, you: U32, ncells: U32, nsectors: U32) -> Things:
  Things{V.Tree.empty(Thing, V.Vec.depth(count)), count, you, V.Tree.empty(List<&2, U32>, V.Vec.depth(ncells)),
    V.Tree.empty(List<&2, U32>, V.Vec.depth(nsectors)), []}

def Things.get(ts: Things, +id: U32) -> Maybe<&2, Thing>:
  Things{tree, count, you, cells, sectors, heard} = ts
  V.Tree.get(Thing, tree, id)

def Things.put(ts: Things, +id: U32, m: Maybe<&2, Thing>) -> Things:
  Things{tree, count, you, cells, sectors, heard} = ts
  Things{V.Tree.set(Thing, tree, id, m), count, you, cells, sectors, heard}

# The things after one of them was heard.
def Things.sounded(ts: Things, e: Sn.Sound.Event) -> Things:
  Things{tree, count, you, cells, sectors, heard} = ts
  Things{tree, count, you, cells, sectors, List.append(&2, Sn.Sound.Event, heard, [e])}

def Things.you(ts: Things) -> U32:
  Things{tree, count, you, cells, sectors, heard} = ts
  you

def Things.count(ts: Things) -> U32:
  Things{tree, count, you, cells, sectors, heard} = ts
  count

def Things.fresh.if(full: Bool, tree: V.Tree<Thing>) -> V.Tree<Thing>:
  match full:
    case False{}:
      tree
    case True{}:
      V.Tree.grown(Thing, tree)

# The population with one id more, its old count, and room for it: the
# tree is full when the count is a power of two.
def Things.fresh(ts: Things) -> Things:
  Things{tree, +count, you, cells, sectors, heard} = ts
  Things{Things.fresh.if(U32.is_zero((count .&. (count - 1) : U32)), tree), (count + 1 : U32), you, cells, sectors,
    heard}

# Links
# -----

def Things.first(ids: List<&2, U32>, +id: U32) -> List<&2, U32>:
  id <> ids

def Things.without(ids: List<&2, U32>, +id: U32) -> List<&2, U32>:
  match ids:
    case []:
      []
    case +h <> rest:
      V.Vec.keep(~U32, Bool.not(U32.is_eq(h, id)), h, Things.without(rest, id))

# List i of some lists with an id put first in it, or taken out of it.
def Things.edit(~edit: @ids: List<&2, U32> -> @+id: U32 -> List<&2, U32>, +lists: V.Tree<List<&2, U32>>, +i: U32,
  id: U32) -> V.Tree<List<&2, U32>>:
  V.Tree.set(List<&2, U32>, lists, i,
    Some{edit(Maybe.default(&2, List<&2, U32>, V.Tree.get(List<&2, U32>, lists, i), []), id)})

def Things.edit.cell(~edit: @ids: List<&2, U32> -> @+id: U32 -> List<&2, U32>, inside: Bool,
  cells: V.Tree<List<&2, U32>>, i: U32, id: U32) -> V.Tree<List<&2, U32>>:
  match inside:
    case False{}:
      cells
    case True{}:
      Things.edit(~edit, cells, i, id)

# A mobj at (x, y) in a sector, in the list of the blockmap cell its
# centre is in and in its sector's; off the map, or flagged for no
# blockmap, it is in no cell.
def Things.placed(~edit: @ids: List<&2, U32> -> @+id: U32 -> List<&2, U32>, ts: Things, +bm: L.Level.Blockmap,
  +unlisted: Bool, +id: U32, x: U32, y: U32, sector: U32) -> Things:
  Things{tree, count, you, cells, sectors, heard} = ts
  L.Blockmap{words, ox, oy, +cols, +rows} = bm
  +c = L.Level.cell_of(bm, x, y)
  Things{tree, count, you, Things.edit.cell(~edit, Bool.and(Bool.not(unlisted),
      L.Level.cell.inside(cols, rows, c)), cells, L.Level.cell.number(cols, c), id),
    Things.edit(~edit, sectors, sector, id), heard}

# Doom's P_SetThingPosition: the mobj goes first in its cell's list and
# first in its sector's.
def Things.link(ts: Things, bm: L.Level.Blockmap, unlisted: Bool, id: U32, x: U32, y: U32, sector: U32) -> Things:
  Things.placed(~Things.first, ts, bm, unlisted, id, x, y, sector)

# Doom's P_UnsetThingPosition: the mobj leaves both lists.
def Things.unlink(ts: Things, bm: L.Level.Blockmap, unlisted: Bool, id: U32, x: U32, y: U32, sector: U32) -> Things:
  Things.placed(~Things.without, ts, bm, unlisted, id, x, y, sector)

# The population with a thing in it, linked where it is: one that
# spawned, or one that moved, once unlinked from where it was.
def Things.entered(ts: Things, bm: L.Level.Blockmap, th: Thing) -> Things:
  Thing{+id, +kind, +x, +y, z, floorz, ceilz, angle, +sector, state, tics, momz} = th
  Things.link(Things.put(ts, id, Some{Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz}}), bm,
    Thing.Def.unlisted(Thing.info(kind)), id, x, y, sector)

def Things.unlinked(ts: Things, bm: L.Level.Blockmap, th: Thing) -> Things:
  Thing{id, +kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz} = th
  Things.unlink(ts, bm, Thing.Def.unlisted(Thing.info(kind)), id, x, y, sector)

# A thing at another place, once unlinked from where it was: Doom's
# P_UnsetThingPosition and P_SetThingPosition about a move.
def Things.moved(ts: Things, +bm: L.Level.Blockmap, was: Thing, now: Thing) -> Things:
  Things.entered(Things.unlinked(ts, bm, was), bm, now)

# Doom's P_RemoveMobj: the thing unlinked and gone, its id never used
# again, and its sound stopped.
def Things.removed(ts: Things, bm: L.Level.Blockmap, th: Thing) -> Things:
  Thing{+id, +kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz} = th
  Things.sounded(Things.put(Things.unlinked(ts, bm,
    Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz}), id, None{}), Sn.Stop{Sn.Thing{id}})

def Things.linked.at(inside: Bool, cells: V.Tree<List<&2, U32>>, i: U32) -> List<&2, U32>:
  match inside:
    case False{}:
      []
    case True{}:
      Maybe.default(&2, List<&2, U32>, V.Tree.get(List<&2, U32>, cells, i), [])

def Things.linked.go(cs: List<&2, L.Level.Cell>, +cols: U32, +rows: U32, +cells: V.Tree<List<&2, U32>>) ->
  List<&2, U32>:
  match cs:
    case []:
      []
    case +c <> rest:
      List.append(&2, U32, Things.linked.at(L.Level.cell.inside(cols, rows, c), cells, L.Level.cell.number(cols, c)),
        Things.linked.go(rest, cols, rows, cells))

# The mobjs linked in each of some blockmap cells in turn, a cell's
# last linked first: the order Doom's P_BlockThingsIterator meets them.
def Things.linked(ts: Things, bm: L.Level.Blockmap, cs: List<&2, L.Level.Cell>) -> List<&2, U32>:
  Things{tree, count, you, cells, sectors, heard} = ts
  L.Blockmap{words, ox, oy, cols, rows} = bm
  Things.linked.go(cs, cols, rows, cells)

# Lists
# -----

def Things.cons(m: Maybe<&2, Thing>, rest: List<&2, Thing>) -> List<&2, Thing>:
  match m:
    case None{}:
      rest
    case Some{th}:
      th <> rest

def Things.list.go(n: Nat, +t: V.Tree<Thing>, +i: U32) -> List<&2, Thing>:
  match n:
    case 0n:
      []
    case 1n+m:
      Things.cons(V.Tree.get(Thing, t, i), Things.list.go(m, t, (i + 1 : U32)))

# The things alive, in the order of their ids.
def Things.list(ts: Things) -> List<&2, Thing>:
  Things{+tree, +count, you, cells, sectors, heard} = ts
  Things.list.go(U32.to_nat(count), tree, 0)

def Things.ids(lists: V.Tree<List<&2, U32>>) -> List<&2, U32>:
  match lists:
    case V.Slot{m}:
      Maybe.default(&2, List<&2, U32>, m, [])
    case V.Fork{l, r}:
      List.append(&2, U32, Things.ids(l), Things.ids(r))

def Things.those(ids: List<&2, U32>, +tree: V.Tree<Thing>) -> List<&2, Thing>:
  match ids:
    case []:
      []
    case id <> rest:
      Things.cons(V.Tree.get(Thing, tree, id), Things.those(rest, tree))

# The things alive, sector by sector, a sector's in the order of its
# list: the order Doom's R_AddSprites meets the things of a sector in.
# The player's mobj is no thing, so it is not among them.
def Things.shown(ts: Things) -> List<&2, Thing>:
  Things{tree, count, you, cells, sectors, heard} = ts
  Things.those(Things.ids(sectors), tree)

# The name of a thing the population lacks, before rest; rest alone for
# one it has.
def Things.gone.name(m: Maybe<&2, Thing>, +id: U32, rest: String) -> String:
  match m:
    case None{}:
      " " ++ U32.show(id) ++ rest
    case Some{_}:
      rest

# The names of the things of a list gone from a population, as text.
def Things.gone(before: List<&2, Thing>, +after: Things) -> String:
  match before:
    case []:
      ""
    case Thing{+id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz} <> rest:
      Things.gone.name(Things.get(after, id), id, Things.gone(rest, after))

# How many things are left and the names of those gone since a first
# population, as text.
def Things.tally(first: List<&2, Thing>, +things: Things) -> String:
  " things " ++ Nat.show(List.length(&2, Thing, Things.list(things))) ++ " taken" ++ Things.gone(first, things)
