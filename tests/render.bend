# Frames of E1M1 from the WAD named by BENDOOM_IWAD, rendered through
# the function the game draws with: for each, a 32-bit FNV-1a hash of the
# view's 320 by 168 palette indices and the indices at four pixels (the
# view's centre, near its top left, near its bottom right, and high on
# its centre column). The start, then hand-chosen places with the eye at
# rest on the floor and the angle a multiple of 45 degrees, so that
# Chocolate Doom can stand in the same spot: a bright metal wall, the
# dim bench room north of the start, the hazard-striped step under the
# computer panels, the lowered opening west of the start with the
# grate of a masked middle texture across it, and the hall under a strip
# of sky. Each frame is drawn twice, over a view blanked
# to 0 and to 255: equal hashes mean every pixel of the view was
# written. Pinned to Freedoom.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/sim.bend as S
import ../src/project.bend as P
import ../src/draw.bend as D
import ../src/render.bend as R

type Hash is Type:
  Hash{mem: Array<U32>, h: U32}

def hash.mix(h: U32, p: Array<U32> & U32) -> Hash:
  (mem, v) = p
  Hash{mem, ((h .^. v) * 16777619 : U32)}

def hash.px(i: Nat, st: Hash) -> Hash:
  Hash{mem, h} = st
  hash.mix(h, B.Bytes.at(mem, (G.Gfx.frame() + U32.from_nat(i) : U32)))

def shows(xs: List<&2, U32>) -> List<&2, String>:
  match xs:
    case []:
      []
    case x <> rest:
      U32.show(x) <> shows(rest)

def pixels(covered: Bool, h: U32, p: Array<U32> & List<&2, U32>) -> Array<U32> & String:
  (mem, xs) = p
  (mem, "hash " ++ U32.show(h) ++ " pixels " ++ String.join(shows(xs), " ") ++ " covered "
    ++ Bool.show(covered))

def line(+over0: U32, st: Hash) -> Array<U32> & String:
  Hash{mem, +h} = st
  pixels(U32.is_eq(h, over0), h, B.Bytes.each(~U32, ~B.Bytes.at, [(G.Gfx.frame() + 84 * 320 + 160 : U32),
    (G.Gfx.frame() + 10 * 320 + 10 : U32), (G.Gfx.frame() + 150 * 320 + 300 : U32),
    (G.Gfx.frame() + 20 * 320 + 160 : U32)], mem))

def print(tag: String, p: Array<U32> & String) -> IO(Array<U32>):
  (mem, text) = p
  do IO<Array<U32>>:
    IO.print(tag ++ " " ++ text)
    return mem

# A frame's hash, drawn over a view blanked to an index.
def hashed(+tables: P.Project.Tables, +level: L.Level, +gfx: G.Gfx, +p: S.Player, blank: U32,
  mem: Array<U32>) -> Hash:
  D.Draw.each(~Hash, ~hash.px, U32.to_nat(53760), 0n, Hash{R.Render.frame(tables, level, gfx, p,
    D.Draw.set(U32.to_nat(53760), mem, G.Gfx.frame(), blank)), 2166136261})

def again(tables: P.Project.Tables, level: L.Level, gfx: G.Gfx, p: S.Player, st: Hash) -> Array<U32> & String:
  Hash{mem, h} = st
  line(h, hashed(tables, level, gfx, p, 255, mem))

# A frame from the player, its line printed, and the array back.
def frame(tag: String, +tables: P.Project.Tables, +level: L.Level, +gfx: G.Gfx, +p: S.Player,
  mem: Array<U32>) -> IO(Array<U32>):
  print(tag, again(tables, level, gfx, p, hashed(tables, level, gfx, p, 0, mem)))

# The player at rest on the floor at a place: x and y in map units,
# west and south given as negatives, the angle in degrees.
def at(+level: L.Level, x: U32, y: U32, degrees: U32) -> S.Player:
  S.Player.at(level, L.Start{x, y, A.Angle.of_thing(degrees)})

def east(units: U32) -> U32:
  F.Fixed.of_map(units)

def west(units: U32) -> U32:
  F.Fixed.neg(F.Fixed.of_map(units))

def frames(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  +tables = P.Project.tables(level)
  do IO<Unit>:
    m1 : Array<U32> <- frame("start", tables, level, gfx, S.Player.start(level), mem)
    m2 : Array<U32> <- frame("lit 736 464 135", tables, level, gfx, at(level, east(736), east(464), 135), m1)
    m3 : Array<U32> <- frame("dark -416 256 90", tables, level, gfx, at(level, west(416), east(256), 90), m2)
    m4 : Array<U32> <- frame("step 137 256 45", tables, level, gfx, at(level, east(137), east(256), 45), m3)
    m5 : Array<U32> <- frame("grate -416 256 180", tables, level, gfx, at(level, west(416), east(256), 180), m4)
    m6 : Array<U32> <- frame("sky 3 256 0", tables, level, gfx, at(level, east(3), east(256), 0), m5)
    IO.print("end")

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  frames(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    world : Array<U32> & G.Gfx & L.Level <- IO.pass(Array<U32> & G.Gfx & L.Level, G.Gfx.load(W.Wad.dir(bytes)))
    start(world)

#|start hash 557988919 pixels 1 1 7 5 covered True
#|lit 736 464 135 hash 3246659701 pixels 104 7 95 103 covered True
#|dark -416 256 90 hash 3735729281 pixels 110 107 0 238 covered True
#|step 137 256 45 hash 2640417900 pixels 7 0 79 111 covered True
#|grate -416 256 180 hash 2636261899 pixels 3 111 106 93 covered True
#|sky 3 256 0 hash 751409046 pixels 2 111 76 6 covered True
#|end
