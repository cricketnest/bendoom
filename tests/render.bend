# Frames of E1M1 from the WAD named by BENDOOM_IWAD, rendered through
# the function the game draws with: for each, a 32-bit FNV-1a hash of the
# whole 320 by 200 frame, the view over the status bar, and the indices
# at six pixels (the view's centre, near its top left, near its bottom
# right, high on its centre column, column 1 row 2 of the arms
# panel's second number, which is grey 96 while the shotgun is not owned
# and yellow 160 in the two frames with a full inventory, and row 180
# column 155 of the marine's face, which the WAD read in nushell says is
# 72 in STFST00, 64 in STFST01, 59 in STFST02, 79 in STFEVL0 and 8 in
# STFDEAD0, so the pixel names the face every frame shows). The start,
# then hand-chosen places with the eye at rest on the floor and the
# angle a multiple of 45 degrees, each after
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
# tic 64; the stride has it far left. Then the dead view: 650 tics stood
# in the nukage of sector 173, which kills on the tic the clock reads
# 608, leave the eye 6 units over the floor, the pistol off the bottom
# of the screen and the bar at no health. Every frame holds the things
# E1M1 spawns on Hurt Me Plenty, monsters among them, each in its state
# on that tic.
# Every frame carries the status bar the inventory of its state fills,
# so the bar at the start, after the rocket is taken, after the green
# armour and after the blue key are the frames named for those pickups,
# and the face ST_updateFaceWidget chose on that tic. The oracle masks
# the face's box, since vanilla's face keeps changing under the pause,
# but the dead one holds: its frame's face pixels are STFDEAD0's, all
# 591 of them, and the rested start's are STFST00's, all 578, each read
# from the WAD with tools/oracle.nu's patch-pixels.
# Remaining combat fidelity gaps are recorded in milestone 6's tickets.
# The exit and full-inventory fixtures are regression pins where a
# vanilla demo cannot reach the same state.
# The pickup frames show their pickup: the key is 44 pixels of the first
# key frame and would be 347 of the second, a bonus never
# taken would be 1465 of the second bonus frame, the green armour is 745
# of its first frame and would be 419 of its second, and a stimpack and
# a medikit taken at 100 health 2744 of theirs; a refused frame differs
# from its taken twin only in the pickup's sprite, 762 pixels of the
# rocket and 5092 of the chainsaw.
# Each frame is drawn twice, over a frame blanked to 0 and to 255: equal
# hashes mean every pixel of the 200 rows was written.
# Every line names the palette ST_doPaletteStuff chose for its frame,
# which the renderer answers beside the indices. The plain palette 0 is
# every frame's but the pickups' and the nukage's. A pickup adds 6 to
# the flash and the same tic's counters take one off, so 5 picks the
# first gold, 10: the health bonus, the green armour, the rocket and the
# chainsaw frames show it, and so does the run east at tic 66, which has
# just crossed the health bonus record 268 at 512 256. The blue key sets
# the flash to 6 and then adds 6, leaving 11, which picks the second
# gold, 11. A tic stood in the nukage of sector 173 leaves a damage
# count of 4, which picks the first red, 2; by the dead frame's tic 650
# it has long faded. Pinned to Freedoom.
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
import ../src/message.bend as Msg
import ./fixtures/combat.bend as C

type Hash is Type:
  Hash{mem: Array<U32>, h: U32, pal: U32}

def hash.mix(h: U32, pal: U32, p: Array<U32> & U32) -> Hash:
  (mem, v) = p
  Hash{mem, H.Fnv.mix(h, v), pal}

def hash.px(i: Nat, st: Hash) -> Hash:
  Hash{mem, h, pal} = st
  hash.mix(h, pal, B.Bytes.at(mem, (G.Gfx.frame() + U32.from_nat(i) : U32)))

def shows(xs: List<&2, U32>) -> List<&2, String>:
  match xs:
    case []:
      []
    case x <> rest:
      U32.show(x) <> shows(rest)

def pixels(covered: Bool, h: U32, pal: U32, p: Array<U32> & List<&2, U32>) -> Array<U32> & String:
  (mem, xs) = p
  (mem, "hash " ++ U32.show(h) ++ " pixels " ++ String.join(shows(xs), " ") ++ " covered "
    ++ Bool.show(covered) ++ " palette " ++ U32.show(pal))

def line(+over0: U32, st: Hash) -> Array<U32> & String:
  Hash{mem, +h, pal} = st
  pixels(U32.is_eq(h, over0), h, pal, B.Bytes.each(~U32, ~B.Bytes.at, [(G.Gfx.frame() + 84 * 320 + 160 : U32),
    (G.Gfx.frame() + 10 * 320 + 10 : U32), (G.Gfx.frame() + 150 * 320 + 300 : U32),
    (G.Gfx.frame() + 20 * 320 + 160 : U32), (G.Gfx.frame() + 174 * 320 + 124 : U32),
    (G.Gfx.frame() + 180 * 320 + 155 : U32)], mem))

def print(tag: String, p: Array<U32> & String) -> IO(Array<U32>):
  (mem, text) = p
  do IO<Array<U32>>:
    IO.print(tag ++ " " ++ text)
    return mem

def hashed.of(p: Array<U32> & U32) -> Hash:
  (mem, pal) = p
  D.Draw.each(~Hash, ~hash.px, U32.to_nat(64000), 0n, Hash{mem, H.Fnv.basis(), pal})

# A frame's hash and the palette the renderer named for it, drawn over a
# frame blanked to an index.
def hashed(+tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, blank: U32, mem: Array<U32>) -> Hash:
  hashed.of(R.Render.frame(tables, gfx, s, False{},
    D.Draw.set(U32.to_nat(64000), mem, G.Gfx.frame(), blank)))

def again(tables: P.Project.Tables, gfx: G.Gfx, s: S.State, st: Hash) -> Array<U32> & String:
  Hash{mem, h, pal} = st
  line(h, hashed(tables, gfx, s, 255, mem))

# A frame of the state, its line printed, and the array back.
def frame(tag: String, +tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, mem: Array<U32>) ->
  IO(Array<U32>):
  print(tag, again(tables, gfx, s, hashed(tables, gfx, s, 0, mem)))

# The frame's first eight rows, which is every row the font's tallest
# glyph reaches.
def band(p: Array<U32> & U32) -> Array<U32> & List<&2, U32>:
  (mem, pal) = p
  B.Bytes.each(~U32, ~B.Bytes.at, B.Bytes.fields(2560n, G.Gfx.frame(), 1, [0]), mem)

def said.at(+i: U32, +v: U32) -> String:
  " " ++ U32.show(i) ++ "," ++ U32.show(v)

# Where the frame with the message differs from the same frame without
# it: how many pixels, and the first four, each its index in the frame
# and the palette index the line left there.
def said.go(off: List<&2, U32>, on: List<&2, U32>, +i: U32, +n: U32, +text: String) -> U32 & String:
  match off on:
    case a <> as +b <> bs:
      +hit = Bool.not(U32.is_eq(a, b))
      said.go(as, bs, (i + 1 : U32), (n + Bool.to_u32(hit) : U32),
        Bool.pick(String, Bool.and(hit, U32.is_lt(n, 4)), text ++ said.at((i + G.Gfx.frame() : U32), b), text))
    case _ _:
      (n, text)

def said.show(+shown: U32, tics: U32, r: U32 & String, mem: Array<U32>) -> Array<U32> & String:
  (n, first) = r
  (mem, "message " ++ U32.show(shown) ++ " \"" ++ Msg.Message.text(shown) ++ "\" tics " ++ U32.show(tics)
    ++ " pixels " ++ U32.show(n) ++ first)

def said.diff(+s: S.State, off: List<&2, U32>, p: Array<U32> & List<&2, U32>) -> Array<U32> & String:
  (mem, on) = p
  said.show(S.State.message(s), S.State.msgtics(s), said.go(off, on, 0, 0, ""), mem)

def said.on(+tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, p: Array<U32> & List<&2, U32>) ->
  Array<U32> & String:
  (mem, off) = p
  said.diff(s, off, band(R.Render.frame(tables, gfx, s, True{}, mem)))

# A frame with its message line drawn, beside the same frame without it:
# the line's own pixels, which tools/wad.nu's hu-line answers from the
# WAD's font.
def said(tag: String, +tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, mem: Array<U32>) -> IO(Array<U32>):
  print(tag, said.on(tables, gfx, s, band(R.Render.frame(tables, gfx, s, False{}, mem))))

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

# Ctrl held for one tic, then the four tics S_PISTOL1 lasts: the frame
# is the one A_FirePistol made, with the muzzle flash showing and its
# extra light on every wall, plane and sprite.
def fired(n: Nat) -> List<&2, K.Cmd>:
  List.append(&2, K.Cmd, [K.Cmd.demo(0, 0, 0, 1)], idle(n))

# A pickup strafed past: the idle tics, a turn, then strafing left.
def strafed(turn: U32, n: Nat, s: S.State) -> S.State:
  after([idle(20n), [K.Cmd.demo(0, 0, turn, 0)], strafe(n)], s)

# Every weapon and every ammo type at its cap, so that no ammo or weapon
# pickup can be taken.
def maxed(inv: I.Inventory) -> I.Inventory:
  I.Inventory{health, armour, armourtype, cards, ammo, +caps, backpack, weapons, powers, items, bonus, line} = inv
  I.Inventory{health, armour, armourtype, cards, caps, caps, backpack, 511, powers, items, bonus, line}

def full(s: S.State) -> S.State:
  S.State{p, level, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn} = s
  S.State{S.Player.holding(p, maxed(I.Inventory.start())), level, things, sidetex, thinkers, rnd, clock, ended,
    usedown, sounds, mrnd, reborn}

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
    d1 : Array<U32> <- frame("dead 1600 1000 90", tables, gfx, after([idle(650n)],
      at(level, east(1600), east(1000), 90)), w3)
    r1 : Array<U32> <- frame("nukage 1600 1000 90", tables, gfx, after([idle(1n)],
      at(level, east(1600), east(1000), 90)), d1)
    w4 : Array<U32> <- frame("pistol firing 25", tables, gfx, after([idle(20n), fired(4n)], S.State.start(level)),
      r1)
    w5 : Array<U32> <- frame("pistol flash over 32", tables, gfx, after([idle(20n), fired(11n)],
      S.State.start(level)), w4)
    w6 : Array<U32> <- frame("puff on the ledge 25", tables, gfx, after([idle(20n), fired(4n)],
      at(level, east(704), east(256), 0)), w5)
    w7 : Array<U32> <- frame("shotgun lowering", tables, gfx, after([idle(20n), walk(5n), idle(8n)],
      at(level, east(824), east(896), 0)), w6)
    w8 : Array<U32> <- frame("shotgun at rest", tables, gfx, after([idle(20n), walk(5n), idle(40n)],
      at(level, east(824), east(896), 0)), w7)
    w9 : Array<U32> <- frame("shotgun firing", tables, gfx, after([idle(20n), walk(5n), idle(40n), fired(3n)],
      at(level, east(824), east(896), 0)), w8)
    g1 : Array<U32> <- frame("corpse crushed by door", tables, gfx, C.Combat.crushed(level), w9)
    n1 : Array<U32> <- said("said armour", tables, gfx, after([idle(20n), walk(12n)],
      at(level, east(1631), east(1008), 90)), g1)
    n2 : Array<U32> <- said("said key", tables, gfx, strafed(4294967280, 13n,
      at(level, east(2246), east(592), 180)), n1)
    n3 : Array<U32> <- said("said chainsaw", tables, gfx, strafed(4294967280, 13n,
      at(level, east(3158), east(2176), 180)), n2)
    n4 : Array<U32> <- said("said none", tables, gfx, S.Sim.replay(idle(20n), S.State.start(level)), n3)
    IO.print("end")

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  frames(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)

#|start hash 3501647150 pixels 1 1 7 5 96 72 covered True palette 0
#|lit 736 464 135 hash 1888788078 pixels 106 8 95 105 96 72 covered True palette 0
#|dark -416 256 90 hash 1364473328 pixels 110 107 0 238 96 72 covered True palette 0
#|step 137 256 45 hash 2880593419 pixels 8 0 79 6 96 72 covered True palette 0
#|grate -416 256 180 hash 442390666 pixels 3 111 106 93 96 72 covered True palette 0
#|water 3 256 0 hash 1102040513 pixels 2 6 77 6 96 72 covered True palette 0
#|sky -640 256 90 hash 4130793025 pixels 239 14 239 105 96 72 covered True palette 0
#|pit 488 320 0 hash 1510042988 pixels 79 110 150 6 96 72 covered True palette 0
#|sergeant 1144 259 315 hash 4195031459 pixels 111 108 0 1 96 72 covered True palette 0
#|once 256 1088 0 hash 2442400286 pixels 110 79 105 7 96 64 covered True palette 0
#|overlap 2752 960 0 hash 17648109 pixels 79 125 10 78 96 72 covered True palette 0
#|walls 704 256 0 hash 2399935752 pixels 7 111 15 2 96 64 covered True palette 0
#|ledge 256 128 90 hash 1443497237 pixels 7 5 15 110 96 72 covered True palette 0
#|yard -640 256 0 hash 1684750053 pixels 1 100 78 8 96 72 covered True palette 0
#|bars 1024 200 0 hash 439285215 pixels 109 79 5 5 96 72 covered True palette 0
#|demon head on 48 1616 180 hash 3057454219 pixels 2 7 111 243 96 59 covered True palette 0
#|shotgun guy from behind 896 2048 270 hash 3729950378 pixels 5 109 0 5 96 72 covered True palette 0
#|shotgun guy from the side 987 1947 225 hash 3040449328 pixels 5 6 109 108 96 72 covered True palette 0
#|demon mirrored 2448 2112 0 hash 2350286645 pixels 39 2 6 79 96 72 covered True palette 0
#|stride U!:34 hash 250131952 pixels 2 5 164 6 96 72 covered True palette 0
#|air U!:56 hash 2263461618 pixels 5 110 15 6 96 64 covered True palette 0
#|landed U!:66 hash 36073354 pixels 6 110 14 79 96 64 covered True palette 10
#|door half open hash 1169190636 pixels 7 14 110 79 96 64 covered True palette 0
#|switch pressed hash 644900545 pixels 3 110 107 7 96 64 covered True palette 0
#|exit pressed hash 786890588 pixels 102 95 102 3 96 72 covered True palette 0
#|blink dark hash 2817285794 pixels 95 72 103 93 96 65 covered True palette 0
#|key 2380 600 180 22 hash 3985974813 pixels 5 1 6 110 96 72 covered True palette 0
#|key bright 23 hash 4138847691 pixels 5 1 6 110 96 72 covered True palette 0
#|key before hash 2059559509 pixels 6 10 5 89 96 72 covered True palette 0
#|key after hash 3772851500 pixels 105 10 2 89 96 72 covered True palette 11
#|bonus before hash 3197225618 pixels 11 79 78 6 96 59 covered True palette 0
#|bonus after hash 3441438830 pixels 10 78 2 11 96 59 covered True palette 10
#|green armour before hash 123771255 pixels 110 110 6 1 96 72 covered True palette 0
#|green armour after hash 4258495022 pixels 8 110 103 2 96 72 covered True palette 10
#|stimpack and medikit before hash 1702492025 pixels 111 109 7 111 96 72 covered True palette 0
#|stimpack and medikit refused hash 1432617097 pixels 110 108 2 107 96 59 covered True palette 0
#|rocket before hash 470823295 pixels 105 109 105 77 96 72 covered True palette 0
#|rocket after hash 3313621550 pixels 106 109 105 77 96 72 covered True palette 10
#|rocket refused hash 3744069241 pixels 106 109 105 77 160 72 covered True palette 0
#|chainsaw after hash 1752609615 pixels 5 5 137 141 96 79 covered True palette 10
#|chainsaw refused hash 1360841628 pixels 5 5 137 141 160 64 covered True palette 0
#|pistol rising 8 hash 1914842866 pixels 1 1 7 5 96 59 covered True palette 0
#|pistol bob low 48 hash 3833298116 pixels 1 79 1 245 96 59 covered True palette 0
#|pistol bob right 64 hash 1365740933 pixels 2 5 111 6 96 59 covered True palette 0
#|dead 1600 1000 90 hash 1289269632 pixels 189 1 103 1 96 44 covered True palette 2
#|nukage 1600 1000 90 hash 3477668975 pixels 11 2 107 1 96 77 covered True palette 2
#|pistol firing 25 hash 3767616058 pixels 1 1 7 111 96 72 covered True palette 0
#|pistol flash over 32 hash 1365649270 pixels 1 1 7 5 96 72 covered True palette 0
#|puff on the ledge 25 hash 2607485146 pixels 7 110 15 2 96 64 covered True palette 0
#|shotgun lowering hash 4038683862 pixels 158 79 79 93 96 64 covered True palette 0
#|shotgun at rest hash 4155222496 pixels 9 8 78 93 96 72 covered True palette 0
#|shotgun firing hash 4015107196 pixels 159 8 78 93 96 59 covered True palette 0
#|corpse crushed by door hash 1079062495 pixels 7 75 106 79 96 64 covered True palette 0
#|said armour message 1 "Picked up the armor." tics 140 pixels 730 0,47 1,45 2,45 3,45
#|said key message 7 "Picked up a blue keycard." tics 140 pixels 901 0,47 1,45 2,45 3,45
#|said chainsaw message 15 "A chainsaw!  Find some meat!" tics 140 pixels 1030 3,47 4,45 5,189 16,47
#|said none message 0 "" tics 0 pixels 0
#|end
