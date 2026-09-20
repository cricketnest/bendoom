# Doom's info.c, P_SpawnMobj, P_SpawnMapThing, P_SetThingPosition,
# P_RemoveMobj and the state half of P_MobjThinker for the things
# Bendoom spawns: the definitions of the DoomEd types either E1M1
# places, less the monsters and the starts, the state rows their spawn
# states lead to and the pistol's with its entry in d_items.c's
# weaponinfo, the map's THINGS records made the level's first things, a
# thing's tic through its states, and the population with its blockmap
# and sector links.
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
# sector under it, its state row, and the tics left in it.
type Thing is Data:
  Thing{id: U32, kind: U32, x: U32, y: U32, z: U32, floorz: U32, ceilz: U32, angle: U32, sector: U32, state: U32,
    tics: U32}

# The player's id on a map with no start for it: one no record has.
def Thing.you() -> U32:
  4294967295

# What a state row does as it is entered, Doom's action pointers: a
# weapon's A_Raise, A_WeaponReady and A_Lower, a mobj's A_Pain and
# A_PlayerScream, or nothing. A row of one kind never holds the other's.
type Thing.Action is Data:
  Null{}
  Raise{}
  WeaponReady{}
  Lower{}
  Pain{}
  Scream{}

# A state row, Doom's state_t: the sprite's four-letter name, the frame
# (0 for A), whether it is full-bright, its tics, the row after it, and
# its action. A row of -1 tics lasts, and it stores itself as its next,
# where vanilla's is S_NULL; no tic reads it, and the sprite load's
# chase stops there.
type Thing.Row is Data:
  Row{sprite: String, frame: U32, bright: Bool, tics: U32, next: U32, action: Thing.Action}

# The state rows by Bendoom's number: every state the spawn states of the
# types below lead to, in vanilla's order, then the pistol's ready, raise
# and down states and the player mobj's own, whose death ends in row 0,
# the corpse a dead marine record spawns in. None has 0 tics.
def Thing.rows() -> List<&2, Thing.Row>:
  [Row{"PLAY", 13, False{}, 4294967295, 0, Null{}}, Row{"PLAY", 22, False{}, 4294967295, 1, Null{}},
    Row{"POSS", 11, False{}, 4294967295, 2, Null{}}, Row{"SPOS", 11, False{}, 4294967295, 3, Null{}},
    Row{"TROO", 12, False{}, 4294967295, 4, Null{}}, Row{"SARG", 13, False{}, 4294967295, 5, Null{}},
    Row{"ARM1", 0, False{}, 6, 7, Null{}}, Row{"ARM1", 1, True{}, 7, 6, Null{}}, Row{"ARM2", 0, False{}, 6, 9, Null{}},
    Row{"ARM2", 1, True{}, 6, 8, Null{}}, Row{"BAR1", 0, False{}, 6, 11, Null{}},
    Row{"BAR1", 1, False{}, 6, 10, Null{}}, Row{"BON1", 0, False{}, 6, 13, Null{}},
    Row{"BON1", 1, False{}, 6, 14, Null{}}, Row{"BON1", 2, False{}, 6, 15, Null{}},
    Row{"BON1", 3, False{}, 6, 16, Null{}}, Row{"BON1", 2, False{}, 6, 17, Null{}},
    Row{"BON1", 1, False{}, 6, 12, Null{}}, Row{"BON2", 0, False{}, 6, 19, Null{}},
    Row{"BON2", 1, False{}, 6, 20, Null{}}, Row{"BON2", 2, False{}, 6, 21, Null{}},
    Row{"BON2", 3, False{}, 6, 22, Null{}}, Row{"BON2", 2, False{}, 6, 23, Null{}},
    Row{"BON2", 1, False{}, 6, 18, Null{}}, Row{"BKEY", 0, False{}, 10, 25, Null{}},
    Row{"BKEY", 1, True{}, 10, 24, Null{}}, Row{"STIM", 0, False{}, 4294967295, 26, Null{}},
    Row{"MEDI", 0, False{}, 4294967295, 27, Null{}}, Row{"SOUL", 0, True{}, 6, 29, Null{}},
    Row{"SOUL", 1, True{}, 6, 30, Null{}}, Row{"SOUL", 2, True{}, 6, 31, Null{}},
    Row{"SOUL", 3, True{}, 6, 32, Null{}}, Row{"SOUL", 2, True{}, 6, 33, Null{}},
    Row{"SOUL", 1, True{}, 6, 28, Null{}}, Row{"PSTR", 0, True{}, 4294967295, 34, Null{}},
    Row{"CLIP", 0, False{}, 4294967295, 35, Null{}}, Row{"AMMO", 0, False{}, 4294967295, 36, Null{}},
    Row{"ROCK", 0, False{}, 4294967295, 37, Null{}}, Row{"BROK", 0, False{}, 4294967295, 38, Null{}},
    Row{"CELL", 0, False{}, 4294967295, 39, Null{}}, Row{"CELP", 0, False{}, 4294967295, 40, Null{}},
    Row{"SHEL", 0, False{}, 4294967295, 41, Null{}}, Row{"SBOX", 0, False{}, 4294967295, 42, Null{}},
    Row{"BPAK", 0, False{}, 4294967295, 43, Null{}}, Row{"MGUN", 0, False{}, 4294967295, 44, Null{}},
    Row{"CSAW", 0, False{}, 4294967295, 45, Null{}}, Row{"LAUN", 0, False{}, 4294967295, 46, Null{}},
    Row{"PLAS", 0, False{}, 4294967295, 47, Null{}}, Row{"SHOT", 0, False{}, 4294967295, 48, Null{}},
    Row{"COLU", 0, True{}, 4294967295, 49, Null{}}, Row{"POL5", 0, False{}, 4294967295, 50, Null{}},
    Row{"POL6", 0, False{}, 6, 52, Null{}}, Row{"POL6", 1, False{}, 8, 51, Null{}},
    Row{"GOR4", 0, False{}, 4294967295, 53, Null{}}, Row{"SMIT", 0, False{}, 4294967295, 54, Null{}},
    Row{"CBRA", 0, True{}, 4294967295, 55, Null{}}, Row{"TRE1", 0, False{}, 4294967295, 56, Null{}},
    Row{"TRE2", 0, False{}, 4294967295, 57, Null{}}, Row{"ELEC", 0, False{}, 4294967295, 58, Null{}},
    Row{"PISG", 0, False{}, 1, 59, WeaponReady{}}, Row{"PISG", 0, False{}, 1, 60, Raise{}},
    Row{"PISG", 0, False{}, 1, 61, Lower{}}, Row{"PLAY", 0, False{}, 4294967295, 62, Null{}},
    Row{"PLAY", 6, False{}, 4, 64, Null{}}, Row{"PLAY", 6, False{}, 4, 62, Pain{}},
    Row{"PLAY", 7, False{}, 10, 66, Null{}}, Row{"PLAY", 8, False{}, 10, 67, Scream{}},
    Row{"PLAY", 9, False{}, 10, 68, Null{}}, Row{"PLAY", 10, False{}, 10, 69, Null{}},
    Row{"PLAY", 11, False{}, 10, 70, Null{}}, Row{"PLAY", 12, False{}, 10, 0, Null{}}]

def Thing.row(s: U32) -> Thing.Row:
  Maybe.default(&2, Thing.Row, List.get(&2, Thing.Row, Thing.rows(), U32.to_nat(s)), Row{"", 0, False{}, 0, 0, Null{}})

def Thing.Row.tics(r: Thing.Row) -> U32:
  Row{sprite, frame, bright, tics, next, action} = r
  tics

def Thing.Row.bright(r: Thing.Row) -> Bool:
  Row{sprite, frame, bright, tics, next, action} = r
  bright

def Thing.Row.next(r: Thing.Row) -> U32:
  Row{sprite, frame, bright, tics, next, action} = r
  next

def Thing.Row.action(r: Thing.Row) -> Thing.Action:
  Row{sprite, frame, bright, tics, next, action} = r
  action

# A weapon's row in Doom's weaponinfo: the states it rises, is ready and
# sinks in, and the ammotype_t it spends, which the status bar counts.
type Thing.Weapon is Data:
  Weapon{up: U32, ready: U32, down: U32, ammo: U32}

# d_items.c's weaponinfo for the pistol: it rises in row 60, rests in
# row 59 and spends am_clip, ammotype_t 0.
def Thing.pistol() -> Thing.Weapon:
  Weapon{60, 59, 61, 0}

def Thing.Weapon.down(w: Thing.Weapon) -> U32:
  Weapon{up, ready, down, ammo} = w
  down

# The player mobj's rows in Doom's mobjinfo: the state it stands in,
# the one it flinches in and the one its death begins with. Its spawn
# health, 100, is the inventory's.
def Thing.play() -> U32:
  62

def Thing.play.pain() -> U32:
  63

def Thing.play.death() -> U32:
  65

def Thing.Weapon.ammo(w: Thing.Weapon) -> U32:
  Weapon{up, ready, down, ammo} = w
  ammo

# Doom's P_MobjThinker for a thing that does not move: a lasting state
# stays as it is; another counts its tics down, and the tic they run out
# the thing enters the next state for that state's tics.
def Thing.tic.step(lasting: Bool, out: Bool, thing: Thing) -> Thing:
  match lasting out thing:
    case True{} _ _:
      thing
    case False{} True{} Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics}:
      +next = Thing.Row.next(Thing.row(state))
      Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, next, Thing.Row.tics(Thing.row(next))}
    case False{} False{} Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics}:
      Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, (tics - 1 : U32)}

def Thing.tic(thing: Thing) -> Thing:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, +tics} = thing
  Thing.tic.step(U32.is_eq(tics, 4294967295), U32.is_eq(tics, 1),
    Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics})

# A type's mobjinfo_t: its DoomEd type, its spawn state's row, its
# radius and height in map units, and vanilla's flags: 1 special, 2
# solid, 4 shootable, 256 hung from the ceiling, 512 no gravity, 524288
# no blood, 8388608 an item the tally counts, 33554432 not in deathmatch.
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
    Def{2049, 42, 20, 16, 1}]

def Thing.Def.kind(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  kind

# A type's radius in fixed point.
def Thing.Def.radius(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  F.Fixed.of_map(radius)

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
    sector, state, Thing.Row.tics(Thing.row(state))}

# The thing with its centre at another place, in the sector under it.
def Thing.at(th: Thing, level: L.Level, +x: U32, +y: U32) -> Thing:
  Thing{id, kind, ox, oy, z, floorz, ceilz, angle, was, state, tics} = th
  Thing{id, kind, x, y, z, floorz, ceilz, angle, L.Level.sector_at(level, x, y), state, tics}

# The things spawned, the last first while they spawn, the random
# index, and player 1's start record, the player's own name before one
# spawns.
type Thing.Spawn is Data:
  Spawn{things: List<&2, Thing>, rnd: U32, you: U32}

def Thing.spawn.facing(th: Thing, angle: U32, tics: U32) -> Thing:
  Thing{id, kind, x, y, z, floorz, ceilz, east, sector, state, first} = th
  Thing{id, kind, x, y, z, floorz, ceilz, A.Angle.of_thing(angle), sector, state, tics}

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

# Doom's P_SpawnMapThing on Hurt Me Plenty with one player and no
# monsters: player 1's start spawns the player, who draws a random number
# too and takes the first such record's index for its name, the start
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
# centre is in and in its sector's; off the map it is in no cell.
def Things.placed(~edit: @ids: List<&2, U32> -> @+id: U32 -> List<&2, U32>, ts: Things, +bm: L.Level.Blockmap,
  +id: U32, x: U32, y: U32, sector: U32) -> Things:
  Things{tree, count, you, cells, sectors, heard} = ts
  L.Blockmap{words, ox, oy, +cols, +rows} = bm
  +c = L.Level.cell_of(bm, x, y)
  Things{tree, count, you, Things.edit.cell(~edit, L.Level.cell.inside(cols, rows, c), cells,
    L.Level.cell.number(cols, c), id), Things.edit(~edit, sectors, sector, id), heard}

# Doom's P_SetThingPosition: the mobj goes first in its cell's list and
# first in its sector's.
def Things.link(ts: Things, bm: L.Level.Blockmap, id: U32, x: U32, y: U32, sector: U32) -> Things:
  Things.placed(~Things.first, ts, bm, id, x, y, sector)

# Doom's P_UnsetThingPosition: the mobj leaves both lists.
def Things.unlink(ts: Things, bm: L.Level.Blockmap, id: U32, x: U32, y: U32, sector: U32) -> Things:
  Things.placed(~Things.without, ts, bm, id, x, y, sector)

# The population with a thing in it, linked where it is: one that
# spawned, or one that moved, once unlinked from where it was.
def Things.entered(ts: Things, bm: L.Level.Blockmap, th: Thing) -> Things:
  Thing{+id, kind, +x, +y, z, floorz, ceilz, angle, +sector, state, tics} = th
  Things.link(Things.put(ts, id, Some{Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics}}), bm, id, x,
    y, sector)

def Things.unlinked(ts: Things, bm: L.Level.Blockmap, th: Thing) -> Things:
  Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics} = th
  Things.unlink(ts, bm, id, x, y, sector)

# A thing at another place, once unlinked from where it was: Doom's
# P_UnsetThingPosition and P_SetThingPosition about a move.
def Things.moved(ts: Things, +bm: L.Level.Blockmap, was: Thing, now: Thing) -> Things:
  Things.entered(Things.unlinked(ts, bm, was), bm, now)

# Doom's P_RemoveMobj: the thing unlinked and gone, its id never used
# again, and its sound stopped.
def Things.removed(ts: Things, bm: L.Level.Blockmap, th: Thing) -> Things:
  Thing{+id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics} = th
  Things.sounded(Things.put(Things.unlinked(ts, bm,
    Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics}), id, None{}), Sn.Stop{Sn.Thing{id}})

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
    case Thing{+id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics} <> rest:
      Things.gone.name(Things.get(after, id), id, Things.gone(rest, after))

# How many things are left and the names of those gone since a first
# population, as text.
def Things.tally(first: List<&2, Thing>, +things: Things) -> String:
  " things " ++ Nat.show(List.length(&2, Thing, Things.list(things))) ++ " taken" ++ Things.gone(first, things)
