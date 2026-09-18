# Frames of E1M1 from the WAD named by BENDOOM_IWAD, rendered through
# the function the game draws with: for each, a 32-bit FNV-1a hash of the
# view's 320 by 168 palette indices and the indices at four pixels (the
# view's centre, near its top left, near its bottom right, and high on
# its centre column). The start, then hand-chosen places with the eye at
# rest on the floor and the angle a multiple of 45 degrees: a bright
# metal wall, the dim bench room north of the start, the hazard-striped
# step under the computer panels, the lowered opening west of the start
# with a masked grate across it, the hall under a ceiling of water, the
# yard under the open sky, the railed pit, and the dead former sergeant
# whole on its bench, the one thing Bendoom spawns yet; the start, the
# water and the stride see a few of its pixels past the walls between,
# and the pit sees none. Then frames after scripts, which the oracle
# plays too: a stride, riding the lift down, off its east edge, the
# first door half open, the special 23 switch pressed, the exit switch
# pressed, a blinking wall at its dark level, and the water on a later
# frame of its cycle. tools/oracle.nu finds no pixel of any of them off
# vanilla's, bar the exit, which vanilla never stands in (milestone 4's
# ticket 09 compares it another way); each script is beside its frame
# below. Each frame is drawn twice, over a view blanked to 0 and to 255:
# equal hashes mean every pixel of the view was written. Pinned to
# Freedoom.
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
def at(+level: L.Level, x: U32, y: U32, degrees: U32) -> S.State:
  S.State.at(level, L.Start{x, y, A.Angle.of_thing(degrees)})

def east(units: U32) -> U32:
  F.Fixed.of_map(units)

def west(units: U32) -> U32:
  F.Fixed.neg(F.Fixed.of_map(units))

# The state after running east from the start for some tics.
def ran(+level: L.Level, tics: Nat) -> S.State:
  S.Sim.replay(List.replicate(K.Cmd, tics, K.Cmd.demo(50, 0, 0, False{})),
    S.State.start(level))

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
    m1 : Array<U32> <- frame("start", tables, gfx, S.State.start(level), mem)
    m2 : Array<U32> <- frame("lit 736 464 135", tables, gfx, at(level, east(736), east(464), 135), m1)
    m3 : Array<U32> <- frame("dark -416 256 90", tables, gfx, at(level, west(416), east(256), 90), m2)
    m4 : Array<U32> <- frame("step 137 256 45", tables, gfx, at(level, east(137), east(256), 45), m3)
    m5 : Array<U32> <- frame("grate -416 256 180", tables, gfx, at(level, west(416), east(256), 180), m4)
    m6 : Array<U32> <- frame("water 3 256 0", tables, gfx, at(level, east(3), east(256), 0), m5)
    m7 : Array<U32> <- frame("sky -640 256 90", tables, gfx, at(level, west(640), east(256), 90), m6)
    m8 : Array<U32> <- frame("pit 488 256 0", tables, gfx, at(level, east(488), east(256), 0), m7)
    m9 : Array<U32> <- frame("sergeant 1144 259 315", tables, gfx, at(level, east(1144), east(259), 315), m8)
    m10 : Array<U32> <- frame("stride U!:34", tables, gfx, ran(level, 34n), m9)
    m11 : Array<U32> <- frame("air U!:56", tables, gfx, ran(level, 56n), m10)
    m12 : Array<U32> <- frame("landed U!:66", tables, gfx, ran(level, 66n), m11)
    m13 : Array<U32> <- frame("door half open", tables, gfx, after([idle(20n),
      List.replicate(K.Cmd, 20n, K.Cmd.demo(25, 0, 0, False{})), [K.Cmd.demo(0, 0, 0, True{})], idle(20n)],
      at(level, east(832), east(384), 90)), m12)
    m14 : Array<U32> <- frame("switch pressed", tables, gfx, after([idle(20n),
      List.replicate(K.Cmd, 10n, K.Cmd.demo(25, 0, 0, False{})), [K.Cmd.demo(0, 0, 0, True{})], idle(27n)],
      at(level, east(2064), west(260), 90)), m13)
    m15 : Array<U32> <- frame("exit pressed", tables, gfx, after([idle(20n), [K.Cmd.demo(0, 0, 0, True{})],
      idle(10n)], at(level, west(352), east(1296), 180)), m14)
    m16 : Array<U32> <- frame("blink dark", tables, gfx, after([idle(66n)], at(level, east(640), east(712), 180)),
      m15)
    m17 : Array<U32> <- frame("water moving", tables, gfx, after([idle(20n)], at(level, east(3), east(256), 0)), m16)
    IO.print("end")

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  frames(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)

#|start hash 309742466 pixels 1 1 7 5 covered True
#|lit 736 464 135 hash 3300301580 pixels 104 7 95 103 covered True
#|dark -416 256 90 hash 3488594130 pixels 110 107 0 238 covered True
#|step 137 256 45 hash 3958655367 pixels 7 0 79 111 covered True
#|grate -416 256 180 hash 2863794005 pixels 3 111 106 93 covered True
#|water 3 256 0 hash 233320077 pixels 2 111 76 6 covered True
#|sky -640 256 90 hash 3006348923 pixels 8 89 105 105 covered True
#|pit 488 256 0 hash 2052822416 pixels 8 6 111 1 covered True
#|sergeant 1144 259 315 hash 1178944882 pixels 111 108 0 1 covered True
#|stride U!:34 hash 1320634075 pixels 2 5 164 6 covered True
#|air U!:56 hash 2556132464 pixels 5 110 15 6 covered True
#|landed U!:66 hash 1207877047 pixels 6 110 14 79 covered True
#|door half open hash 1284933713 pixels 107 6 74 111 covered True
#|switch pressed hash 2946116189 pixels 3 110 107 7 covered True
#|exit pressed hash 847822191 pixels 102 95 102 3 covered True
#|blink dark hash 4167308477 pixels 99 73 73 3 covered True
#|water moving hash 4092342880 pixels 2 6 77 6 covered True
#|end
