# Frames of E1M1 from the WAD named by BENDOOM_IWAD, rendered through
# the function the game draws with: for each, a 32-bit FNV-1a hash of the
# view's 320 by 168 palette indices and the indices at four pixels (the
# view's centre, near its top left, near its bottom right, and high on
# its centre column). The start, then hand-chosen places with the eye at
# rest on the floor and the angle a multiple of 45 degrees: a bright
# metal wall, the dim bench room north of the start, the hazard-striped
# step under the computer panels, the lowered opening west of the start
# with a masked grate across it and the yard's trees behind, the hall
# under a ceiling of water, the yard under the open sky, the railed pit,
# and the dead former sergeant on its bench. Then the sprites' rules,
# each place found by rendering the map and each count below from
# drawing one sprite with and without the stored ranges: the medikit
# (record 258) in sector 8, which the walk enters through at least three
# of its nine subsectors (40, 34 and 35 store ranges) and which is drawn
# once, as a copy would leave the same pixels and no frame can show one;
# a near stalagmite (record 153) over a far tree (23), which shows 206
# of its 1022 pixels; a hall where one-sided walls hide the sergeant and
# a hung leg, and ledges two corpses, all projected; and a corpse
# (record 171) beyond a raised bench, whose edge leaves 78 of its 220
# pixels, and another (167) it hides whole. Then the masked pass's two
# depth orders: the yard's trees in front of the grate, which drawing
# every sprite before every masked texture changes by 837 pixels, the
# grate's top over the trees; and a hung body and the dead sergeant
# behind the bars east of the walls hall, which drawing every masked
# texture before every sprite changes by 516. Then frames after scripts,
# which the oracle plays too: a stride, riding the lift down, off its
# east edge, the first door half open, the special 23 switch pressed,
# the exit switch pressed, a blinking wall at its dark level, and the
# water on a later frame of its cycle; each script is beside its frame
# below. Every frame holds the things E1M1 spawns on Hurt Me Plenty.
# tools/oracle.nu finds no pixel off vanilla's in the dark, grate,
# water, sky, sprite-rule, depth, stride, switch and blink frames. The others differ where a thing animates or
# is full-bright, which ticket 05 brings; with those things taken out of
# both games every count is 0, and until then their hashes are
# regression pins. The exit is not compared: vanilla never stands in it
# (milestone 4's ticket 09 compares it another way). Each frame is drawn
# twice, over a view blanked to 0 and to 255: equal hashes mean every
# pixel of the view was written. Pinned to Freedoom.
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
    s1 : Array<U32> <- frame("once 256 1088 0", tables, gfx, at(level, east(256), east(1088), 0), m9)
    s2 : Array<U32> <- frame("overlap 2752 960 0", tables, gfx, at(level, east(2752), east(960), 0), s1)
    s3 : Array<U32> <- frame("walls 704 256 0", tables, gfx, at(level, east(704), east(256), 0), s2)
    s4 : Array<U32> <- frame("ledge 256 128 90", tables, gfx, at(level, east(256), east(128), 90), s3)
    d1 : Array<U32> <- frame("yard -640 256 0", tables, gfx, at(level, west(640), east(256), 0), s4)
    d2 : Array<U32> <- frame("bars 1024 200 0", tables, gfx, at(level, east(1024), east(200), 0), d1)
    m10 : Array<U32> <- frame("stride U!:34", tables, gfx, ran(level, 34n), d2)
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

#|start hash 3582478214 pixels 1 1 7 5 covered True
#|lit 736 464 135 hash 3223437629 pixels 104 7 95 103 covered True
#|dark -416 256 90 hash 3549150205 pixels 110 107 0 238 covered True
#|step 137 256 45 hash 912470422 pixels 7 0 79 111 covered True
#|grate -416 256 180 hash 3767638002 pixels 3 111 106 93 covered True
#|water 3 256 0 hash 2875924069 pixels 2 111 76 6 covered True
#|sky -640 256 90 hash 4166025265 pixels 239 14 239 105 covered True
#|pit 488 256 0 hash 4118378470 pixels 8 6 111 1 covered True
#|sergeant 1144 259 315 hash 3133938681 pixels 111 108 0 1 covered True
#|once 256 1088 0 hash 2329486650 pixels 110 79 105 7 covered True
#|overlap 2752 960 0 hash 4038843935 pixels 79 125 10 78 covered True
#|walls 704 256 0 hash 3755778102 pixels 7 111 15 2 covered True
#|ledge 256 128 90 hash 4089245318 pixels 6 10 15 107 covered True
#|yard -640 256 0 hash 3050307010 pixels 1 100 78 8 covered True
#|bars 1024 200 0 hash 605587869 pixels 109 79 5 5 covered True
#|stride U!:34 hash 2845586337 pixels 2 5 164 6 covered True
#|air U!:56 hash 2977300388 pixels 5 110 15 6 covered True
#|landed U!:66 hash 4031325049 pixels 6 110 14 79 covered True
#|door half open hash 295776083 pixels 107 6 74 111 covered True
#|switch pressed hash 2946116189 pixels 3 110 107 7 covered True
#|exit pressed hash 847822191 pixels 102 95 102 3 covered True
#|blink dark hash 568518560 pixels 94 73 73 101 covered True
#|water moving hash 1934760231 pixels 2 6 77 6 covered True
#|end
