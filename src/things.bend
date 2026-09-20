# Doom's info.c, P_SpawnMapThing and the state half of P_MobjThinker for
# the things Bendoom spawns: the definitions of the DoomEd types either
# E1M1 places, less the monsters and the starts, the state rows their
# spawn states lead to and the pistol's with its entry in d_items.c's
# weaponinfo, the map's THINGS records made the level's first things, a
# thing's tic through its states, and P_RemoveMobj.
import Base
import ./fixed.bend as F
import ./angle.bend as A
import ./level.bend as L
import ./random.bend as M
import ./vec.bend as V
import ./sound.bend as Sn

# A thing, Doom's mobj: its THINGS record's index, which names it for
# good, its DoomEd type, its position with z on the floor or under the
# ceiling, the floor and ceiling it is held between, its facing, the
# sector under it, its state row, and the tics left in it.
type Thing is Data:
  Thing{id: U32, kind: U32, x: U32, y: U32, z: U32, floorz: U32, ceilz: U32, angle: U32, sector: U32, state: U32,
    tics: U32}

# The player among the mobjs: a name no record has, above every record's,
# so the player's link ranked by it heads its cell.
def Thing.you() -> U32:
  4294967295

# What a state row does as it is entered, Doom's action pointers:
# nothing, A_Raise, A_WeaponReady.
type Thing.Action is Data:
  Null{}
  Raise{}
  WeaponReady{}

# A state row, Doom's state_t: the sprite's four-letter name, the frame
# (0 for A), whether it is full-bright, its tics, the row after it, and
# its action. A row of -1 tics lasts, and it stores itself as its next,
# where vanilla's is S_NULL; no tic reads it, and the sprite load's
# chase stops there.
type Thing.Row is Data:
  Row{sprite: String, frame: U32, bright: Bool, tics: U32, next: U32, action: Thing.Action}

# The state rows by Bendoom's number: every state the spawn states of the
# types below lead to, in vanilla's order, then the pistol's ready and
# raise states. None has 0 tics.
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
    Row{"PISG", 0, False{}, 1, 59, WeaponReady{}}, Row{"PISG", 0, False{}, 1, 60, Raise{}}]

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

# A weapon's row in Doom's weaponinfo: the state it rises in, the state
# it is ready in, and the ammotype_t it spends, which the status bar
# counts.
type Thing.Weapon is Data:
  Weapon{up: U32, ready: U32, ammo: U32}

# d_items.c's weaponinfo for the pistol: it rises in row 60, rests in
# row 59 and spends am_clip, ammotype_t 0.
def Thing.pistol() -> Thing.Weapon:
  Weapon{60, 59, 0}

def Thing.Weapon.ammo(w: Thing.Weapon) -> U32:
  Weapon{up, ready, ammo} = w
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

# The things spawned, the last first while they spawn, the random
# index, and player 1's start record, the player's own name before one
# spawns.
type Thing.Spawn is Data:
  Spawn{things: List<&2, Thing>, rnd: U32, you: U32}

# Doom's P_SpawnMobj and the rest of P_SpawnMapThing: one random number
# drawn for the thing, and one more for a state that runs out, which
# lasts that number modulo its tics, plus one. It stands on the floor of
# the sector under it, or hangs its height under the ceiling, is held
# between that sector's floor and ceiling, and faces the record's angle.
def Thing.spawn.mobj(d: Thing.Def, +level: L.Level, id: U32, +x: U32, +y: U32, angle: U32, s: Thing.Spawn) ->
  Thing.Spawn:
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
      (ceil - F.Fixed.of_map(height) : U32)), floor, ceil, A.Angle.of_thing(angle), sector, state,
      Bool.pick(U32, runs, (M.Random.at(after) % tics + 1 : U32), tics)} <> things, after, you}

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
# too and ranks among the things of its cell by the first such record,
# the start Level.start_of places it at; another record spawns when its
# options set that skill's bit, 2, and not the multiplayer bit, 16, and
# its type has a definition.
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
# player's own name. Last, what the things did that is heard and the
# state has not reported yet: a position check has no state to tell.
type Things is Data:
  Things{tree: Thing.Tree, count: U32, you: U32, heard: List<&2, Sn.Sound.Event>}

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

def Thing.Tree.tics(t: Thing.Tree) -> Thing.Tree:
  match t:
    case Slot{m}:
      Slot{Maybe.map(&2, Thing, Thing, Thing.tic, m)}
    case Fork{l, r}:
      Fork{Thing.Tree.tics(l), Thing.Tree.tics(r)}

def Things.get(ts: Things, +id: U32) -> Maybe<&2, Thing>:
  Things{tree, count, you, heard} = ts
  Thing.Tree.get(tree, V.Vec.odd(id), id)

def Things.put(ts: Things, +id: U32, m: Maybe<&2, Thing>) -> Things:
  Things{tree, count, you, heard} = ts
  Things{Thing.Tree.set(tree, V.Vec.odd(id), id, m), count, you, heard}

# The things after one of them was heard.
def Things.sounded(ts: Things, e: Sn.Sound.Event) -> Things:
  Things{tree, count, you, heard} = ts
  Things{tree, count, you, List.append(&2, Sn.Sound.Event, heard, [e])}

# Doom's P_RemoveMobj: the thing is gone, and its sound stops.
def Things.removed(ts: Things, +id: U32) -> Things:
  Things.sounded(Things.put(ts, id, None{}), Sn.Stop{Sn.Thing{id}})

def Things.you(ts: Things) -> U32:
  Things{tree, count, you, heard} = ts
  you

# The things after the player's first move.
def Things.moved(ts: Things) -> Things:
  Things{tree, count, you, heard} = ts
  Things{tree, count, Thing.you(), heard}

def Things.of.go(things: List<&2, Thing>, ts: Things) -> Things:
  match things:
    case []:
      ts
    case Thing{+id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics} <> rest:
      Things.of.go(rest,
        Things.put(ts, id, Some{Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics}}))

# A population of things whose ids are under count, the player's link
# at you.
def Things.of(things: List<&2, Thing>, +count: U32, you: U32) -> Things:
  Things.of.go(things, Things{Thing.Tree.empty(V.Vec.depth(count)), count, you, []})

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
  Things{+tree, +count, you, heard} = ts
  Things.list.go(U32.to_nat(count), tree, 0)

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

# Every thing alive through its tic. A tic reads no other thing, so the
# order vanilla's thinkers run them in cannot show.
def Things.tics(ts: Things) -> Things:
  Things{tree, count, you, heard} = ts
  Things{Thing.Tree.tics(tree), count, you, heard}

def Thing.link.go(things: List<&2, Thing>, +level: L.Level) -> L.Level:
  match things:
    case []:
      level
    case Thing{+id, +kind, +x, +y, z, floorz, ceilz, angle, sector, state, tics} <> rest:
      Thing.link.go(rest, L.Level.link(level, id, x, y, kind))

# The level with things linked into its blockmap in turn, as Doom links
# them when they spawn, and no other.
def Thing.linked(+level: L.Level, things: List<&2, Thing>, count: U32) -> L.Level:
  Thing.link.go(things, L.Level.unlinked(level, count))
