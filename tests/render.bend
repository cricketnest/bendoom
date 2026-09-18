# Frames of E1M1 from the WAD named by BENDOOM_IWAD, rendered through
# the function the game draws with: for each, a 32-bit FNV-1a hash of the
# view's 320 by 168 palette indices and the indices at four pixels (the
# view's centre, near its top left, near its bottom right, and high on
# its centre column). The start, then hand-chosen places with the eye at
# rest on the floor and the angle a multiple of 45 degrees, so that
# Chocolate Doom can stand in the same spot (tools/oracle.nu finds no
# pixel of any of them differing from its frame): a bright metal wall,
# the dim bench room north of the start, the hazard-striped step under
# the computer panels, the lowered opening west of the start with the
# grate of a masked middle texture across it and the sky behind, the
# hall under a ceiling of water, the yard under the open sky beside a
# wall of the sky's own texture, and the railed pit under the ledge.
# Then three frames from the sim's run east off the ledge, which no
# player start can express: mid-stride with the eye bobbing, in the air,
# and just landed with the view dipping. Then frames the movers
# make, each after a script from a place, the oracle's zero recorded in
# milestone 4's tickets: the first door half open, 21 tics after its use
# (832 384 90, "20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0"). Each frame is drawn twice, over
# a view blanked to 0 and to 255: equal hashes mean every pixel of the
# view was written. Pinned to Freedoom.
import Base
import ../src/bytes.bend as B
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
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
def hashed(+tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, blank: U32, mem: Array<U32>) -> Hash:
  D.Draw.each(~Hash, ~hash.px, U32.to_nat(53760), 0n, Hash{R.Render.frame(tables, gfx, s,
    D.Draw.set(U32.to_nat(53760), mem, G.Gfx.frame(), blank)), 2166136261})

def again(tables: P.Project.Tables, gfx: G.Gfx, s: S.State, st: Hash) -> Array<U32> & String:
  Hash{mem, h} = st
  line(h, hashed(tables, gfx, s, 255, mem))

# A frame of the state, its line printed, and the array back.
def frame(tag: String, +tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, mem: Array<U32>) ->
  IO(Array<U32>):
  print(tag, again(tables, gfx, s, hashed(tables, gfx, s, 0, mem)))

# The level's first state with the player at rest on the floor at a
# place: x and y in map units, west and south given as negatives, the
# angle in degrees.
def at(gfx: G.Gfx, +level: L.Level, x: U32, y: U32, degrees: U32) -> S.State:
  S.State.at(level, G.Gfx.sidetex(gfx), L.Start{x, y, A.Angle.of_thing(degrees)})

def east(units: U32) -> U32:
  F.Fixed.of_map(units)

def west(units: U32) -> U32:
  F.Fixed.neg(F.Fixed.of_map(units))

# The state after running east from the start for some tics.
def ran(gfx: G.Gfx, +level: L.Level, tics: Nat) -> S.State:
  S.Sim.replay(List.replicate(K.Cmd, tics, K.Cmd.demo(50, 0, 0, False{})),
    S.State.start(level, G.Gfx.sidetex(gfx)))

# The state after runs of commands in a demo's units from a place: the
# scripts the oracle plays.
def after(runs: List<&2, List<&2, K.Cmd>>, s: S.State) -> S.State:
  S.Sim.replay(List.concat(&2, K.Cmd, runs), s)

def idle(n: Nat) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.idle())

def frames(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  +tables = P.Project.tables(level)
  do IO<Unit>:
    m1 : Array<U32> <- frame("start", tables, gfx, S.State.start(level, G.Gfx.sidetex(gfx)), mem)
    m2 : Array<U32> <- frame("lit 736 464 135", tables, gfx, at(gfx, level, east(736), east(464), 135), m1)
    m3 : Array<U32> <- frame("dark -416 256 90", tables, gfx, at(gfx, level, west(416), east(256), 90), m2)
    m4 : Array<U32> <- frame("step 137 256 45", tables, gfx, at(gfx, level, east(137), east(256), 45), m3)
    m5 : Array<U32> <- frame("grate -416 256 180", tables, gfx, at(gfx, level, west(416), east(256), 180), m4)
    m6 : Array<U32> <- frame("water 3 256 0", tables, gfx, at(gfx, level, east(3), east(256), 0), m5)
    m7 : Array<U32> <- frame("sky -640 256 90", tables, gfx, at(gfx, level, west(640), east(256), 90), m6)
    m8 : Array<U32> <- frame("pit 488 256 0", tables, gfx, at(gfx, level, east(488), east(256), 0), m7)
    m9 : Array<U32> <- frame("stride U!:34", tables, gfx, ran(gfx, level, 34n), m8)
    m10 : Array<U32> <- frame("air U!:56", tables, gfx, ran(gfx, level, 56n), m9)
    m11 : Array<U32> <- frame("landed U!:66", tables, gfx, ran(gfx, level, 66n), m10)
    m12 : Array<U32> <- frame("door half open", tables, gfx, after([idle(20n),
      List.replicate(K.Cmd, 20n, K.Cmd.demo(25, 0, 0, False{})), [K.Cmd.demo(0, 0, 0, True{})], idle(20n)],
      at(gfx, level, east(832), east(384), 90)), m11)
    IO.print("end")

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  frames(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)

#|start hash 2160814949 pixels 1 1 7 5 covered True
#|lit 736 464 135 hash 3300301580 pixels 104 7 95 103 covered True
#|dark -416 256 90 hash 3488594130 pixels 110 107 0 238 covered True
#|step 137 256 45 hash 3958655367 pixels 7 0 79 111 covered True
#|grate -416 256 180 hash 2863794005 pixels 3 111 106 93 covered True
#|water 3 256 0 hash 2231310396 pixels 2 111 76 6 covered True
#|sky -640 256 90 hash 3006348923 pixels 8 89 105 105 covered True
#|pit 488 256 0 hash 2052822416 pixels 8 6 111 1 covered True
#|stride U!:34 hash 4182473275 pixels 2 109 164 6 covered True
#|air U!:56 hash 1020890737 pixels 6 0 8 6 covered True
#|landed U!:66 hash 577452768 pixels 79 110 111 6 covered True
#|door half open hash 1284933713 pixels 107 6 74 111 covered True
#|end
