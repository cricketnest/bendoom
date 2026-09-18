# Doom's info.c and P_SpawnMapThing for the things Bendoom spawns: the
# definitions of the DoomEd types either E1M1 places, less the monsters
# and the starts, their spawn states' rows, and the map's THINGS records
# made the level's first things.
import Base
import ./fixed.bend as F
import ./level.bend as L
import ./random.bend as M
import ./vec.bend as V

# A thing, Doom's mobj: its THINGS record's index, which names it for
# good, its DoomEd type, its position with z on the floor or under the
# ceiling, the floor and ceiling it is held between, the sector under
# it, its state row, and the tics left in it.
type Thing is Data:
  Thing{id: U32, kind: U32, x: U32, y: U32, z: U32, floorz: U32, ceilz: U32, sector: U32, state: U32, tics: U32}

# The player among the mobjs: a name no record has, above every record's,
# so the player's link ranked by it heads its cell.
def Thing.you() -> U32:
  4294967295

# A state row, Doom's state_t: the sprite's four-letter name, the frame
# (0 for A), and its tics, -1 for a state that lasts.
type Thing.Row is Data:
  Row{sprite: String, frame: U32, tics: U32}

# The state rows by Bendoom's number: the spawn states of the types
# below, in their order.
def Thing.rows() -> List<&2, Thing.Row>:
  [Row{"BKEY", 0, 10}, Row{"BPAK", 0, 4294967295}, Row{"PLAY", 22, 4294967295}, Row{"PLAY", 13, 4294967295},
    Row{"CELP", 0, 4294967295}, Row{"POSS", 11, 4294967295}, Row{"SPOS", 11, 4294967295},
    Row{"TROO", 12, 4294967295}, Row{"SARG", 13, 4294967295}, Row{"POL5", 0, 4294967295}, Row{"POL6", 0, 6},
    Row{"CBRA", 0, 4294967295}, Row{"TRE1", 0, 4294967295}, Row{"SMIT", 0, 4294967295},
    Row{"ELEC", 0, 4294967295}, Row{"TRE2", 0, 4294967295}, Row{"GOR4", 0, 4294967295},
    Row{"SHOT", 0, 4294967295}, Row{"MGUN", 0, 4294967295}, Row{"LAUN", 0, 4294967295},
    Row{"PLAS", 0, 4294967295}, Row{"CSAW", 0, 4294967295}, Row{"CLIP", 0, 4294967295},
    Row{"SHEL", 0, 4294967295}, Row{"ROCK", 0, 4294967295}, Row{"STIM", 0, 4294967295},
    Row{"MEDI", 0, 4294967295}, Row{"SOUL", 0, 6}, Row{"BON1", 0, 6}, Row{"BON2", 0, 6}, Row{"ARM1", 0, 6},
    Row{"ARM2", 0, 6}, Row{"PSTR", 0, 4294967295}, Row{"COLU", 0, 4294967295}, Row{"BAR1", 0, 6},
    Row{"BROK", 0, 4294967295}, Row{"CELL", 0, 4294967295}, Row{"AMMO", 0, 4294967295},
    Row{"SBOX", 0, 4294967295}]

def Thing.row(s: U32) -> Thing.Row:
  Maybe.default(&2, Thing.Row, List.get(&2, Thing.Row, Thing.rows(), U32.to_nat(s)), Row{"", 0, 0})

def Thing.Row.tics(r: Thing.Row) -> U32:
  Row{sprite, frame, tics} = r
  tics

# A type's mobjinfo_t: its DoomEd type, its spawn state's row, its
# radius and height in map units, and vanilla's flags: 1 special, 2
# solid, 4 shootable, 256 hung from the ceiling, 512 no gravity, 524288
# no blood, 8388608 an item the tally counts, 33554432 not in deathmatch.
type Thing.Def is Data:
  Def{kind: U32, state: U32, radius: U32, height: U32, flags: U32}

def Thing.defs() -> List<&2, Thing.Def>:
  [Def{5, 0, 20, 16, 33554433}, Def{8, 1, 20, 16, 1}, Def{10, 2, 20, 16, 0}, Def{12, 2, 20, 16, 0},
    Def{15, 3, 20, 16, 0}, Def{17, 4, 20, 16, 1}, Def{18, 5, 20, 16, 0}, Def{19, 6, 20, 16, 0},
    Def{20, 7, 20, 16, 0}, Def{21, 8, 20, 16, 0}, Def{24, 9, 20, 16, 0}, Def{26, 10, 16, 16, 2},
    Def{35, 11, 16, 16, 2}, Def{43, 12, 16, 16, 2}, Def{47, 13, 16, 16, 2}, Def{48, 14, 16, 16, 2},
    Def{54, 15, 32, 16, 2}, Def{60, 16, 20, 68, 768}, Def{2001, 17, 20, 16, 1}, Def{2002, 18, 20, 16, 1},
    Def{2003, 19, 20, 16, 1}, Def{2004, 20, 20, 16, 1}, Def{2005, 21, 20, 16, 1}, Def{2007, 22, 20, 16, 1},
    Def{2008, 23, 20, 16, 1}, Def{2010, 24, 20, 16, 1}, Def{2011, 25, 20, 16, 1}, Def{2012, 26, 20, 16, 1},
    Def{2013, 27, 20, 16, 8388609}, Def{2014, 28, 20, 16, 8388609}, Def{2015, 29, 20, 16, 8388609},
    Def{2018, 30, 20, 16, 1}, Def{2019, 31, 20, 16, 1}, Def{2023, 32, 20, 16, 8388609},
    Def{2028, 33, 16, 16, 2}, Def{2035, 34, 10, 42, 524294}, Def{2046, 35, 20, 16, 1},
    Def{2047, 36, 20, 16, 1}, Def{2048, 37, 20, 16, 1}, Def{2049, 38, 20, 16, 1}]

def Thing.Def.kind(d: Thing.Def) -> U32:
  Def{kind, state, radius, height, flags} = d
  kind

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

# The things spawned, the last first while they spawn, the random
# index, and player 1's start record, the player's own name before one
# spawns.
type Thing.Spawn is Data:
  Spawn{things: List<&2, Thing>, rnd: U32, you: U32}

# Doom's P_SpawnMobj and the rest of P_SpawnMapThing: one random number
# drawn for the thing, and one more for a state that runs out, which
# lasts that number modulo its tics, plus one. It stands on the floor of
# the sector under it, or hangs its height under the ceiling, and is held
# between that sector's floor and ceiling.
def Thing.spawn.mobj(d: Thing.Def, +level: L.Level, id: U32, +x: U32, +y: U32, s: Thing.Spawn) -> Thing.Spawn:
  Def{kind, +state, radius, height, flags} = d
  Spawn{things, rnd, you} = s
  +tics = Thing.Row.tics(Thing.row(state))
  +drawn = M.Random.next(rnd)
  +runs = F.Fixed.gt(tics, 0)
  +after = Bool.pick(U32, runs, M.Random.next(drawn), drawn)
  +sector = L.Level.sector_at(level, x, y)
  +floor = L.Level.floor(level, sector)
  +ceil = L.Level.ceil(level, sector)
  Spawn{Thing{id, kind, x, y, Bool.pick(U32, U32.is_zero((flags .&. 256 : U32)), floor,
      (ceil - F.Fixed.of_map(height) : U32)), floor, ceil, sector, state,
      Bool.pick(U32, runs, (M.Random.at(after) % tics + 1 : U32), tics)} <> things, after, you}

def Thing.spawn.if(player: Bool, skill: Bool, info: Maybe<&2, Thing.Def>, +level: L.Level, +id: U32, +x: U32,
  +y: U32, s: Thing.Spawn) -> Thing.Spawn:
  match player skill info:
    case True{} _ _:
      Spawn{things, rnd, +you} = s
      Spawn{things, M.Random.next(rnd), Bool.pick(U32, U32.is_lt(id, you), id, you)}
    case False{} True{} Some{d}:
      Thing.spawn.mobj(d, level, id, x, y, s)
    case _ _ _:
      s

# Doom's P_SpawnMapThing on Hurt Me Plenty with one player and no
# monsters: player 1's start spawns the player, who draws a random number
# too and ranks among the things of its cell by the first such record,
# the start Level.start_of places it at; another record spawns when its
# options set that skill's bit, 2, and not the multiplayer bit, 16, and
# its type has a definition.
def Thing.spawn.one(+level: L.Level, id: U32, record: L.Level.Thing, s: Thing.Spawn) -> Thing.Spawn:
  L.Thing{x, y, angle, +kind, +options} = record
  Thing.spawn.if(U32.is_eq(kind, 1), Bool.and(Bool.not(U32.is_zero((options .&. 2 : U32))),
    U32.is_zero((options .&. 16 : U32))), Thing.def(kind), level, id, x, y, s)

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

# The things by id, a complete binary tree like a V.Vec: a slot holds
# its thing, or none for an id that never spawned or is gone.
type Thing.Tree is Data:
  Slot{thing: Maybe<&2, Thing>}
  Fork{l: Thing.Tree, r: Thing.Tree}

# The things alive, among ids from 0 to count, and where the player's
# link stands among the things of its cell. Doom links a thing first in
# its cell when it spawns or moves, so the things are linked the last
# spawned first, and the player after those spawned after its start
# record, you, until its first move puts it before them all, at the
# player's own name.
type Things is Data:
  Things{tree: Thing.Tree, count: U32, you: U32}

def Thing.Tree.empty(d: Nat) -> Thing.Tree:
  match d:
    case 0n:
      Slot{None{}}
    case 1n++p:
      Fork{Thing.Tree.empty(p), Thing.Tree.empty(p)}

def Thing.Tree.get(t: Thing.Tree, odd: Bool, +i: U32) -> Maybe<&2, Thing>:
  match t odd:
    case Slot{m} _:
      m
    case Fork{l, r} False{}:
      Thing.Tree.get(l, V.Vec.odd((i >> 1n : U32)), (i >> 1n : U32))
    case Fork{l, r} True{}:
      Thing.Tree.get(r, V.Vec.odd((i >> 1n : U32)), (i >> 1n : U32))

def Thing.Tree.set(t: Thing.Tree, odd: Bool, +i: U32, m: Maybe<&2, Thing>) -> Thing.Tree:
  match t odd:
    case Slot{old} _:
      Slot{m}
    case Fork{l, r} False{}:
      Fork{Thing.Tree.set(l, V.Vec.odd((i >> 1n : U32)), (i >> 1n : U32), m), r}
    case Fork{l, r} True{}:
      Fork{l, Thing.Tree.set(r, V.Vec.odd((i >> 1n : U32)), (i >> 1n : U32), m)}

def Things.get(ts: Things, +id: U32) -> Maybe<&2, Thing>:
  Things{tree, count, you} = ts
  Thing.Tree.get(tree, V.Vec.odd(id), id)

def Things.put(ts: Things, +id: U32, m: Maybe<&2, Thing>) -> Things:
  Things{tree, count, you} = ts
  Things{Thing.Tree.set(tree, V.Vec.odd(id), id, m), count, you}

def Things.you(ts: Things) -> U32:
  Things{tree, count, you} = ts
  you

# The things after the player's first move.
def Things.moved(ts: Things) -> Things:
  Things{tree, count, you} = ts
  Things{tree, count, Thing.you()}

def Things.of.go(things: List<&2, Thing>, ts: Things) -> Things:
  match things:
    case []:
      ts
    case Thing{+id, kind, x, y, z, floorz, ceilz, sector, state, tics} <> rest:
      Things.of.go(rest, Things.put(ts, id, Some{Thing{id, kind, x, y, z, floorz, ceilz, sector, state, tics}}))

# A population of things whose ids are under count, the player's link
# at you.
def Things.of(things: List<&2, Thing>, +count: U32, you: U32) -> Things:
  Things.of.go(things, Things{Thing.Tree.empty(V.Vec.depth(count)), count, you})

def Things.cons(m: Maybe<&2, Thing>, rest: List<&2, Thing>) -> List<&2, Thing>:
  match m:
    case None{}:
      rest
    case Some{th}:
      th <> rest

def Things.list.go(n: Nat, +t: Thing.Tree, +i: U32) -> List<&2, Thing>:
  match n:
    case 0n:
      []
    case 1n+m:
      Things.cons(Thing.Tree.get(t, V.Vec.odd(i), i), Things.list.go(m, t, (i + 1 : U32)))

# The things alive, in the order of their ids.
def Things.list(ts: Things) -> List<&2, Thing>:
  Things{+tree, +count, you} = ts
  Things.list.go(U32.to_nat(count), tree, 0)

def Thing.link.go(things: List<&2, Thing>, +level: L.Level) -> L.Level:
  match things:
    case []:
      level
    case Thing{+id, +kind, +x, +y, z, floorz, ceilz, sector, state, tics} <> rest:
      Thing.link.go(rest, L.Level.link(level, id, x, y, kind))

# The level with things linked into its blockmap in turn, as Doom links
# them when they spawn, and no other.
def Thing.linked(+level: L.Level, things: List<&2, Thing>, count: U32) -> L.Level:
  Thing.link.go(things, L.Level.unlinked(level, count))
