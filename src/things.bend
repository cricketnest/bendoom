# Doom's info.c, P_SpawnMapThing and the state half of P_MobjThinker for
# the things Bendoom spawns: the definitions of the DoomEd types either
# E1M1 places, less the monsters and the starts, the state rows their
# spawn states lead to, the map's THINGS records made the level's first
# things, and a thing's tic through its states.
import Base
import ./fixed.bend as F
import ./angle.bend as A
import ./level.bend as L
import ./random.bend as M

# A thing, Doom's mobj: its THINGS record's index, which names it for
# good, its DoomEd type, its position with z on the floor or under the
# ceiling, its facing, the sector under it, its state row, and the tics
# left in it.
type Thing is Data:
  Thing{id: U32, kind: U32, x: U32, y: U32, z: U32, angle: U32, sector: U32, state: U32, tics: U32}

# A state row, Doom's state_t: the sprite's four-letter name, the frame
# (0 for A), whether it is full-bright, its tics, and the row after it.
# A row of -1 tics lasts, and it stores itself as its next, where
# vanilla's is S_NULL; no tic reads it, and the sprite load's chase
# stops there.
type Thing.Row is Data:
  Row{sprite: String, frame: U32, bright: Bool, tics: U32, next: U32}

# The state rows by Bendoom's number: every state the spawn states of the
# types below lead to, in vanilla's order. None has 0 tics or an action.
def Thing.rows() -> List<&2, Thing.Row>:
  [Row{"PLAY", 13, False{}, 4294967295, 0}, Row{"PLAY", 22, False{}, 4294967295, 1},
    Row{"POSS", 11, False{}, 4294967295, 2}, Row{"SPOS", 11, False{}, 4294967295, 3},
    Row{"TROO", 12, False{}, 4294967295, 4}, Row{"SARG", 13, False{}, 4294967295, 5},
    Row{"ARM1", 0, False{}, 6, 7}, Row{"ARM1", 1, True{}, 7, 6}, Row{"ARM2", 0, False{}, 6, 9},
    Row{"ARM2", 1, True{}, 6, 8}, Row{"BAR1", 0, False{}, 6, 11}, Row{"BAR1", 1, False{}, 6, 10},
    Row{"BON1", 0, False{}, 6, 13}, Row{"BON1", 1, False{}, 6, 14}, Row{"BON1", 2, False{}, 6, 15},
    Row{"BON1", 3, False{}, 6, 16}, Row{"BON1", 2, False{}, 6, 17}, Row{"BON1", 1, False{}, 6, 12},
    Row{"BON2", 0, False{}, 6, 19}, Row{"BON2", 1, False{}, 6, 20}, Row{"BON2", 2, False{}, 6, 21},
    Row{"BON2", 3, False{}, 6, 22}, Row{"BON2", 2, False{}, 6, 23}, Row{"BON2", 1, False{}, 6, 18},
    Row{"BKEY", 0, False{}, 10, 25}, Row{"BKEY", 1, True{}, 10, 24}, Row{"STIM", 0, False{}, 4294967295, 26},
    Row{"MEDI", 0, False{}, 4294967295, 27}, Row{"SOUL", 0, True{}, 6, 29}, Row{"SOUL", 1, True{}, 6, 30},
    Row{"SOUL", 2, True{}, 6, 31}, Row{"SOUL", 3, True{}, 6, 32}, Row{"SOUL", 2, True{}, 6, 33},
    Row{"SOUL", 1, True{}, 6, 28}, Row{"PSTR", 0, True{}, 4294967295, 34}, Row{"CLIP", 0, False{}, 4294967295, 35},
    Row{"AMMO", 0, False{}, 4294967295, 36}, Row{"ROCK", 0, False{}, 4294967295, 37},
    Row{"BROK", 0, False{}, 4294967295, 38}, Row{"CELL", 0, False{}, 4294967295, 39},
    Row{"CELP", 0, False{}, 4294967295, 40}, Row{"SHEL", 0, False{}, 4294967295, 41},
    Row{"SBOX", 0, False{}, 4294967295, 42}, Row{"BPAK", 0, False{}, 4294967295, 43},
    Row{"MGUN", 0, False{}, 4294967295, 44}, Row{"CSAW", 0, False{}, 4294967295, 45},
    Row{"LAUN", 0, False{}, 4294967295, 46}, Row{"PLAS", 0, False{}, 4294967295, 47},
    Row{"SHOT", 0, False{}, 4294967295, 48}, Row{"COLU", 0, True{}, 4294967295, 49},
    Row{"POL5", 0, False{}, 4294967295, 50}, Row{"POL6", 0, False{}, 6, 52}, Row{"POL6", 1, False{}, 8, 51},
    Row{"GOR4", 0, False{}, 4294967295, 53}, Row{"SMIT", 0, False{}, 4294967295, 54},
    Row{"CBRA", 0, True{}, 4294967295, 55}, Row{"TRE1", 0, False{}, 4294967295, 56},
    Row{"TRE2", 0, False{}, 4294967295, 57}, Row{"ELEC", 0, False{}, 4294967295, 58}]

def Thing.row(s: U32) -> Thing.Row:
  Maybe.default(&2, Thing.Row, List.get(&2, Thing.Row, Thing.rows(), U32.to_nat(s)), Row{"", 0, False{}, 0, 0})

def Thing.Row.tics(r: Thing.Row) -> U32:
  Row{sprite, frame, bright, tics, next} = r
  tics

def Thing.Row.bright(r: Thing.Row) -> Bool:
  Row{sprite, frame, bright, tics, next} = r
  bright

def Thing.Row.next(r: Thing.Row) -> U32:
  Row{sprite, frame, bright, tics, next} = r
  next

# Doom's P_MobjThinker for a thing that does not move: a lasting state
# stays as it is; another counts its tics down, and the tic they run out
# the thing enters the next state for that state's tics.
def Thing.tic.step(lasting: Bool, out: Bool, thing: Thing) -> Thing:
  match lasting out thing:
    case True{} _ _:
      thing
    case False{} True{} Thing{id, kind, x, y, z, angle, sector, state, tics}:
      +next = Thing.Row.next(Thing.row(state))
      Thing{id, kind, x, y, z, angle, sector, next, Thing.Row.tics(Thing.row(next))}
    case False{} False{} Thing{id, kind, x, y, z, angle, sector, state, tics}:
      Thing{id, kind, x, y, z, angle, sector, state, (tics - 1 : U32)}

def Thing.tic(thing: Thing) -> Thing:
  Thing{id, kind, x, y, z, angle, sector, state, +tics} = thing
  Thing.tic.step(U32.is_eq(tics, 4294967295), U32.is_eq(tics, 1),
    Thing{id, kind, x, y, z, angle, sector, state, tics})

# Every thing's tic, in the order they spawned.
def Thing.tics(things: List<&2, Thing>) -> List<&2, Thing>:
  match things:
    case []:
      []
    case thing <> rest:
      Thing.tic(thing) <> Thing.tics(rest)

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

# The things spawned, the last first while they spawn, and the random
# index.
type Thing.Spawn is Data:
  Spawn{things: List<&2, Thing>, rnd: U32}

# Doom's P_SpawnMobj and the rest of P_SpawnMapThing: one random number
# drawn for the thing, and one more for a state that runs out, which
# lasts that number modulo its tics, plus one. It stands on the floor of
# the sector under it, or hangs its height under the ceiling, and faces
# the record's angle.
def Thing.spawn.mobj(d: Thing.Def, +level: L.Level, id: U32, +x: U32, +y: U32, angle: U32, s: Thing.Spawn) ->
  Thing.Spawn:
  Def{kind, +state, radius, height, flags} = d
  Spawn{things, rnd} = s
  +tics = Thing.Row.tics(Thing.row(state))
  +drawn = M.Random.next(rnd)
  +runs = F.Fixed.gt(tics, 0)
  +after = Bool.pick(U32, runs, M.Random.next(drawn), drawn)
  +sector = L.Level.sector_at(level, x, y)
  Spawn{Thing{id, kind, x, y, Bool.pick(U32, U32.is_zero((flags .&. 256 : U32)), L.Level.floor(level, sector),
      (L.Level.ceil(level, sector) - F.Fixed.of_map(height) : U32)), A.Angle.of_thing(angle), sector, state,
      Bool.pick(U32, runs, (M.Random.at(after) % tics + 1 : U32), tics)} <> things, after}

def Thing.spawn.if(player: Bool, skill: Bool, info: Maybe<&2, Thing.Def>, +level: L.Level, id: U32, +x: U32,
  +y: U32, angle: U32, s: Thing.Spawn) -> Thing.Spawn:
  match player skill info:
    case True{} _ _:
      Spawn{things, rnd} = s
      Spawn{things, M.Random.next(rnd)}
    case False{} True{} Some{d}:
      Thing.spawn.mobj(d, level, id, x, y, angle, s)
    case _ _ _:
      s

# Doom's P_SpawnMapThing on Hurt Me Plenty with one player and no
# monsters: player 1's start spawns the player, who draws a random number
# too; another record spawns when its options set that skill's bit, 2,
# and not the multiplayer bit, 16, and its type has a definition.
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
  Spawn{things, rnd} = s
  Spawn{List.reverse(&2, Thing, things), rnd}

# The level's first things, in the order of their records, and the
# random index once they have spawned, from 0.
def Thing.spawn(+level: L.Level) -> Thing.Spawn:
  Thing.spawn.done(Thing.spawn.go(U32.to_nat(L.Level.nthings(level)), level, 0, Spawn{[], 0}))
