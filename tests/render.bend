# Frames of E1M1 from the WAD named by BENDOOM_IWAD, rendered through
# the function the game draws with: for each, a 32-bit FNV-1a hash of the
# view's 320 by 168 palette indices and the indices at four pixels (the
# view's centre, near its top left, near its bottom right, and high on
# its centre column). The start, then hand-chosen places with the eye at
# rest on the floor and the angle a multiple of 45 degrees, each after
# the oracle's 20 idle tics: a bright metal wall, the dim bench room
# north of the start, the hazard-striped step under the computer panels,
# the lowered opening west of the start with a masked grate across it
# and the yard's trees behind, the hall under a ceiling of water, the
# yard under the open sky, the railed pit, and the dead former sergeant
# on its bench. Then the sprites' rules, each place found by rendering
# the map and each count below from drawing one sprite with and without
# the stored ranges: the medikit (record 258) in sector 8, which the
# walk enters through at least three of its nine subsectors (40, 34 and
# 35 store ranges) and which is drawn once, as a copy would leave the
# same pixels and no frame can show one; a near stalagmite (record 153)
# over a far tree (23), which shows 206 of its 1022 pixels; a hall where
# one-sided walls hide the sergeant and a hung leg, and ledges two
# corpses, all projected; and a corpse (record 171) beyond a raised
# bench, whose edge leaves 78 of its 220 pixels, and another (167) it
# hides whole. Then the masked pass's two depth orders, the yard and the
# bars: the yard's trees in front of the grate, which drawing every
# sprite before every masked texture changes by 837 pixels, the grate's
# top over the trees; and a hung body and the dead sergeant behind the
# bars east of the walls hall, which drawing every masked texture before
# every sprite changes by 516. Then the monsters' rotations, each from a
# place no monster of the map can see, so that none has woken in vanilla
# either: the demon of record 92 head on at rotation 1, 6 tics in, while
# its spawn's 7 tics still hold it before its first A_Look; the shotgun
# guy of record 94 from behind, rotation 5, and from its side, rotation
# 4; and the demon of record 3 at rotation 6, which SARGA4A6 draws
# mirrored. Moving the monster's record to the start changes 3758, 375,
# 736 and 1706 pixels of those frames, so each shows its monster. Then
# frames after scripts, which the oracle plays too: a stride, riding the
# lift down, off its east edge, a north room's door half open, the
# special 23 switch pressed, the exit
# switch pressed, a blinking wall at its dark level, the blue key on the
# last tic of its dim state, 22, and the first of its full-bright one,
# 23, then the pickups: the blue key on the tic before the player
# strafing past it takes it and on the tic it does, a health bonus on a
# step 24 up on the tic before a walk reaches it and on the tic it does,
# green armour 33 to the right of a walk on the tic before it reaches it
# and on the tic it does, a stimpack and a medikit before and after a
# walk across them and back at 100 health, which leaves both, the rocket
# in its nook strafed past facing 112.5 degrees on the tic before it is
# taken and the tic it is, and on that tic with every ammo type at its
# cap, where it stays, and the chainsaw on the key's script on the tic
# it is taken and, owned, on the tic it stays; each script is beside its
# frame below. Last the pistol, which every frame above holds at rest or
# bobbing: 8 tics into its rise, 74 down the screen, and on a walk east
# from the start at the bob's lowest, tic 48, and at its farthest right,
# tic 64; the stride has it far left. Every frame holds the things E1M1
# spawns on Hurt Me Plenty, monsters among them, each in its state on
# that tic.
# tools/oracle.nu finds no pixel off vanilla's in the frames it can
# compare. It cannot compare a frame whose script lets a monster see the
# player, since vanilla's wakes and Bendoom's cannot yet (milestone 6's
# ticket 15 gives them A_Look): the two run east past the pit, the two
# of the blue key in its dim and bright states, the two of the key
# strafed past, the two of the green armour and the chainsaw taken are
# regression pins until then, and so are the exit, which vanilla never
# stands in (milestone 4's ticket 09 compares it another way), and the
# two refused frames, whose full inventory vanilla's demo cannot reach.
# The pickup frames show their pickup: the key is 44 pixels of the first
# key frame and would be 347 of the second, a bonus never
# taken would be 1465 of the second bonus frame, the green armour is 745
# of its first frame and would be 419 of its second, and a stimpack and
# a medikit taken at 100 health 2744 of theirs; a refused frame differs
# from its taken twin only in the pickup's sprite, 762 pixels of the
# rocket and 5092 of the chainsaw.
# Each frame is drawn twice, over a view blanked to 0 and to 255: equal
# hashes mean every pixel of the view was written. Pinned to Freedoom.
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
import ../src/fnv.bend as H
import ../src/inventory.bend as I

type Hash is Type:
  Hash{mem: Array<U32>, h: U32}

def hash.mix(h: U32, p: Array<U32> & U32) -> Hash:
  (mem, v) = p
  Hash{mem, H.Fnv.mix(h, v)}

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
    D.Draw.set(U32.to_nat(53760), mem, G.Gfx.frame(), blank)), H.Fnv.basis()})

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
  S.Sim.replay(List.replicate(K.Cmd, tics, K.Cmd.demo(50, 0, 0, 0)),
    S.State.start(level))

# The state after runs of commands in a demo's units from a place: the
# scripts the oracle plays.
def after(runs: List<&2, List<&2, K.Cmd>>, s: S.State) -> S.State:
  S.Sim.replay(List.concat(&2, K.Cmd, runs), s)

def strafe(n: Nat) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.demo(0, 4294967272, 0, 0))

def idle(n: Nat) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.idle())

# A place after the oracle's 20 idle tics.
def rested(+level: L.Level, x: U32, y: U32, degrees: U32) -> S.State:
  S.Sim.replay(idle(20n), at(level, x, y, degrees))

def walk(n: Nat) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.demo(25, 0, 0, 0))

def back(n: Nat) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.demo(4294967271, 0, 0, 0))

# A pickup strafed past: the idle tics, a turn, then strafing left.
def strafed(turn: U32, n: Nat, s: S.State) -> S.State:
  after([idle(20n), [K.Cmd.demo(0, 0, turn, 0)], strafe(n)], s)

# Every weapon and every ammo type at its cap, so that no ammo or weapon
# pickup can be taken.
def maxed(inv: I.Inventory) -> I.Inventory:
  I.Inventory{health, armour, armourtype, cards, ammo, +caps, backpack, weapons, powers, items, bonus} = inv
  I.Inventory{health, armour, armourtype, cards, caps, caps, backpack, 511, powers, items, bonus}

def full(s: S.State) -> S.State:
  S.State{p, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd} = s
  S.State{S.Player.holding(p, maxed(I.Inventory.start())), level, things, sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd}

def frames(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  +tables = P.Project.tables(level)
  do IO<Unit>:
    m1 : Array<U32> <- frame("start", tables, gfx, S.Sim.replay(idle(20n), S.State.start(level)), mem)
    m2 : Array<U32> <- frame("lit 736 464 135", tables, gfx, rested(level, east(736), east(464), 135), m1)
    m3 : Array<U32> <- frame("dark -416 256 90", tables, gfx, rested(level, west(416), east(256), 90), m2)
    m4 : Array<U32> <- frame("step 137 256 45", tables, gfx, rested(level, east(137), east(256), 45), m3)
    m5 : Array<U32> <- frame("grate -416 256 180", tables, gfx, rested(level, west(416), east(256), 180), m4)
    m6 : Array<U32> <- frame("water 3 256 0", tables, gfx, rested(level, east(3), east(256), 0), m5)
    m7 : Array<U32> <- frame("sky -640 256 90", tables, gfx, rested(level, west(640), east(256), 90), m6)
    m8 : Array<U32> <- frame("pit 488 320 0", tables, gfx, rested(level, east(488), east(320), 0), m7)
    m9 : Array<U32> <- frame("sergeant 1144 259 315", tables, gfx, rested(level, east(1144), east(259), 315), m8)
    s1 : Array<U32> <- frame("once 256 1088 0", tables, gfx, rested(level, east(256), east(1088), 0), m9)
    s2 : Array<U32> <- frame("overlap 2752 960 0", tables, gfx, rested(level, east(2752), east(960), 0), s1)
    s3 : Array<U32> <- frame("walls 704 256 0", tables, gfx, rested(level, east(704), east(256), 0), s2)
    s4 : Array<U32> <- frame("ledge 256 128 90", tables, gfx, rested(level, east(256), east(128), 90), s3)
    d1 : Array<U32> <- frame("yard -640 256 0", tables, gfx, rested(level, west(640), east(256), 0), s4)
    d2 : Array<U32> <- frame("bars 1024 200 0", tables, gfx, rested(level, east(1024), east(200), 0), d1)
    n1 : Array<U32> <- frame("demon head on 48 1616 180", tables, gfx,
      S.Sim.replay(idle(6n), at(level, east(48), east(1616), 180)), d2)
    n2 : Array<U32> <- frame("shotgun guy from behind 896 2048 270", tables, gfx,
      rested(level, east(896), east(2048), 270), n1)
    n3 : Array<U32> <- frame("shotgun guy from the side 987 1947 225", tables, gfx,
      rested(level, east(987), east(1947), 225), n2)
    n4 : Array<U32> <- frame("demon mirrored 2448 2112 0", tables, gfx,
      rested(level, east(2448), east(2112), 0), n3)
    m10 : Array<U32> <- frame("stride U!:34", tables, gfx, ran(level, 34n), n4)
    m11 : Array<U32> <- frame("air U!:56", tables, gfx, ran(level, 56n), m10)
    m12 : Array<U32> <- frame("landed U!:66", tables, gfx, ran(level, 66n), m11)
    m13 : Array<U32> <- frame("door half open", tables, gfx, after([idle(20n), walk(20n),
      [K.Cmd.demo(0, 0, 0, 2)], idle(20n)],
      at(level, east(448), east(1968), 90)), m12)
    m14 : Array<U32> <- frame("switch pressed", tables, gfx, after([idle(20n), walk(10n),
      [K.Cmd.demo(0, 0, 0, 2)], idle(27n)],
      at(level, east(2064), west(260), 90)), m13)
    m15 : Array<U32> <- frame("exit pressed", tables, gfx, after([idle(20n), [K.Cmd.demo(0, 0, 0, 2)],
      idle(10n)], at(level, west(352), east(1296), 180)), m14)
    m16 : Array<U32> <- frame("blink dark", tables, gfx, after([idle(66n)], at(level, east(640), east(712), 180)),
      m15)
    m17 : Array<U32> <- frame("key 2380 600 180 22", tables, gfx, after([idle(22n)],
      at(level, east(2380), east(600), 180)), m16)
    m18 : Array<U32> <- frame("key bright 23", tables, gfx, after([idle(23n)], at(level, east(2380), east(600), 180)),
      m17)
    m19 : Array<U32> <- frame("key before", tables, gfx, strafed(4294967280, 12n,
      at(level, east(2246), east(592), 180)), m18)
    m20 : Array<U32> <- frame("key after", tables, gfx, strafed(4294967280, 13n,
      at(level, east(2246), east(592), 180)), m19)
    m21 : Array<U32> <- frame("bonus before", tables, gfx, after([idle(20n), walk(18n)],
      at(level, east(2590), east(780), 90)), m20)
    m22 : Array<U32> <- frame("bonus after", tables, gfx, after([idle(20n), walk(19n)],
      at(level, east(2590), east(780), 90)), m21)
    m23 : Array<U32> <- frame("green armour before", tables, gfx, after([idle(20n), walk(11n)],
      at(level, east(1631), east(1008), 90)), m22)
    m24 : Array<U32> <- frame("green armour after", tables, gfx, after([idle(20n), walk(12n)],
      at(level, east(1631), east(1008), 90)), m23)
    m25 : Array<U32> <- frame("stimpack and medikit before", tables, gfx, rested(level, east(0), east(400), 90), m24)
    m26 : Array<U32> <- frame("stimpack and medikit refused", tables, gfx, after([idle(20n), walk(16n), back(24n)],
      at(level, east(0), east(400), 90)), m25)
    m27 : Array<U32> <- frame("rocket before", tables, gfx, strafed(16, 11n, at(level, east(714), west(1011), 90)), m26)
    m28 : Array<U32> <- frame("rocket after", tables, gfx, strafed(16, 12n, at(level, east(714), west(1011), 90)), m27)
    m29 : Array<U32> <- frame("rocket refused", tables, gfx, strafed(16, 12n,
      full(at(level, east(714), west(1011), 90))), m28)
    m30 : Array<U32> <- frame("chainsaw after", tables, gfx, strafed(4294967280, 13n,
      at(level, east(3158), east(2176), 180)), m29)
    m31 : Array<U32> <- frame("chainsaw refused", tables, gfx, strafed(4294967280, 13n,
      full(at(level, east(3158), east(2176), 180))), m30)
    w1 : Array<U32> <- frame("pistol rising 8", tables, gfx, after([idle(8n)], S.State.start(level)), m31)
    w2 : Array<U32> <- frame("pistol bob low 48", tables, gfx, after([idle(20n), walk(28n)], S.State.start(level)), w1)
    w3 : Array<U32> <- frame("pistol bob right 64", tables, gfx, after([idle(20n), walk(44n)], S.State.start(level)),
      w2)
    IO.print("end")

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  frames(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)

#|start hash 1557165389 pixels 1 1 7 5 covered True
#|lit 736 464 135 hash 2164616461 pixels 106 8 95 105 covered True
#|dark -416 256 90 hash 1520781991 pixels 110 107 0 238 covered True
#|step 137 256 45 hash 2803172168 pixels 8 0 79 6 covered True
#|grate -416 256 180 hash 1590491081 pixels 3 111 106 93 covered True
#|water 3 256 0 hash 1501146406 pixels 2 6 77 6 covered True
#|sky -640 256 90 hash 3346711206 pixels 239 14 239 105 covered True
#|pit 488 320 0 hash 3386442803 pixels 79 110 150 6 covered True
#|sergeant 1144 259 315 hash 823643776 pixels 111 108 0 1 covered True
#|once 256 1088 0 hash 4087151414 pixels 110 79 105 7 covered True
#|overlap 2752 960 0 hash 990508562 pixels 79 125 10 78 covered True
#|walls 704 256 0 hash 3605968952 pixels 7 111 15 2 covered True
#|ledge 256 128 90 hash 912580506 pixels 7 5 15 110 covered True
#|yard -640 256 0 hash 680709450 pixels 1 100 78 8 covered True
#|bars 1024 200 0 hash 155268204 pixels 109 79 5 5 covered True
#|demon head on 48 1616 180 hash 2737074926 pixels 2 7 111 243 covered True
#|shotgun guy from behind 896 2048 270 hash 3615134057 pixels 5 109 0 5 covered True
#|shotgun guy from the side 987 1947 225 hash 2731718503 pixels 5 6 109 108 covered True
#|demon mirrored 2448 2112 0 hash 3491287994 pixels 39 2 6 79 covered True
#|stride U!:34 hash 3359230631 pixels 2 5 164 6 covered True
#|air U!:56 hash 4274552563 pixels 5 110 15 6 covered True
#|landed U!:66 hash 1862408548 pixels 6 110 14 79 covered True
#|door half open hash 1718761876 pixels 7 14 110 79 covered True
#|switch pressed hash 1212247325 pixels 3 110 107 7 covered True
#|exit pressed hash 4293877891 pixels 102 95 102 3 covered True
#|blink dark hash 3434806638 pixels 94 73 73 101 covered True
#|key 2380 600 180 22 hash 2913024500 pixels 5 1 6 110 covered True
#|key bright 23 hash 2913024500 pixels 5 1 6 110 covered True
#|key before hash 3885846684 pixels 6 10 5 89 covered True
#|key after hash 1759506197 pixels 105 10 2 89 covered True
#|bonus before hash 1827634615 pixels 11 79 78 6 covered True
#|bonus after hash 3218245263 pixels 10 78 2 11 covered True
#|green armour before hash 867258257 pixels 110 110 6 1 covered True
#|green armour after hash 3644477778 pixels 8 110 103 2 covered True
#|stimpack and medikit before hash 316771838 pixels 111 109 7 111 covered True
#|stimpack and medikit refused hash 1803262692 pixels 110 108 2 107 covered True
#|rocket before hash 1689782028 pixels 105 109 105 77 covered True
#|rocket after hash 3174246019 pixels 106 109 105 77 covered True
#|rocket refused hash 502319553 pixels 106 109 105 77 covered True
#|chainsaw after hash 2556295056 pixels 5 5 137 141 covered True
#|chainsaw refused hash 3684659689 pixels 5 5 137 141 covered True
#|pistol rising 8 hash 1980230935 pixels 1 1 7 5 covered True
#|pistol bob low 48 hash 480894361 pixels 1 79 1 245 covered True
#|pistol bob right 64 hash 4086953120 pixels 2 5 111 6 covered True
#|end
