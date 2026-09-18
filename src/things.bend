# Doom's info.c and P_SpawnMapThing for the things Bendoom spawns: each
# DoomEd type's spawn state, the state rows, and the map's THINGS
# records made the level's first things.
import Base
import ./level.bend as L

# A thing, Doom's mobj: its THINGS record's index, which names it for
# good, its DoomEd type, its position with z on the floor, the sector
# under it, and its state row.
type Thing is Data:
  Thing{id: U32, kind: U32, x: U32, y: U32, z: U32, sector: U32, state: U32}

# A state row, Doom's state_t: the sprite's four-letter name and the
# frame, 0 for A.
type Thing.Row is Data:
  Row{sprite: String, frame: U32}

# The state rows by Bendoom's number: 0 is S_SPOS_DIE5, a dead former
# sergeant's last frame.
def Thing.rows() -> List<&2, Thing.Row>:
  [Row{"SPOS", 11}]

def Thing.row(s: U32) -> Thing.Row:
  Maybe.default(&2, Thing.Row, List.get(&2, Thing.Row, Thing.rows(), U32.to_nat(s)), Row{"", 0})

# Doom's mobjinfo spawn state of a DoomEd type, none for a type Bendoom
# does not spawn: 19 is the dead former sergeant.
def Thing.spawnstate(kind: U32) -> Maybe<&2, U32>:
  match kind:
    case 19:
      Some{0}
    case _:
      None{}

def Thing.spawn.if(spawns: Bool, state: Maybe<&2, U32>, +level: L.Level, id: U32, kind: U32, +x: U32, +y: U32,
  rest: List<&2, Thing>) -> List<&2, Thing>:
  match spawns state:
    case True{} Some{s}:
      +sector = L.Level.sector_at(level, x, y)
      Thing{id, kind, x, y, L.Level.floor(level, sector), sector, s} <> rest
    case _ _:
      rest

# Doom's P_SpawnMapThing on Hurt Me Plenty with one player: a record
# spawns when its options set that skill's bit, 2, and not the
# multiplayer bit, 16, and its type has a spawn state; it stands on the
# floor of the sector under it.
def Thing.spawn.one(+level: L.Level, i: U32, record: L.Level.Thing, rest: List<&2, Thing>) -> List<&2, Thing>:
  L.Thing{x, y, angle, +kind, +options} = record
  Thing.spawn.if(Bool.and(Bool.not(U32.is_zero((options .&. 2 : U32))), U32.is_zero((options .&. 16 : U32))),
    Thing.spawnstate(kind), level, i, kind, x, y, rest)

def Thing.spawn.go(n: Nat, +level: L.Level, +i: U32) -> List<&2, Thing>:
  match n:
    case 0n:
      []
    case 1n+m:
      Thing.spawn.one(level, i, L.Level.thing(level, i), Thing.spawn.go(m, level, (i + 1 : U32)))

# The level's first things, in the order of their records.
def Thing.spawn(+level: L.Level) -> List<&2, Thing>:
  Thing.spawn.go(U32.to_nat(L.Level.nthings(level)), level, 0)
