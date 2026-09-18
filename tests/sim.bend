# E1M1 from the WAD named by BENDOOM_IWAD, loaded by the game's loader,
# and two scripted walks through the game's step: the player 1 start,
# then the position, facing, height, floor and eye above the floor after
# each run of held keys (U up, D down, L left, R right, A strafe left,
# S strafe right, ! run). The second walk runs east off a 140-unit
# ledge: the last tic on it, the first two airborne tics (double
# gravity, then single), the landing at 17 a tic with its dip of an
# eighth of that, and the view recovered.
# Freedoom's first map is not id's: the shareware start is 1056, -3616
# facing 90, and its first tic forward lands at 1055.999694, -3615.218765.
# Then the movers, as runs of one command in a demo's units from a
# place, each line with the clock, the thinkers running and a sector's
# floor and ceiling. The first door, sector 10, used from the pit south
# of it: its ceiling on the tics worked out by hand in milestone 4's
# ticket 04 from the WAD and vanilla's constants (-126 on the tic of the
# use, -4 61 tics on, the wait, -6 on the 214th, shut on the 275th, its
# thinker gone on the 276th); a use while it closes and one while it
# waits; use held down for 300 tics, which opens it once; a walk through
# it while open, where the first walk stopped at its shut face; a stand
# in the doorway through the wait, where the door comes down to the
# player's head at -72 on the 247th tic after the use, is blocked on the
# 248th and goes back up (ticket 05's hand computation); and the blue
# key door, which refuses. The heights and tics are the hand
# computation's; the positions are regression pins.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/vec.bend as V
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/sim.bend as S

def line(tag: String, s: S.State) -> String:
  +p = S.State.player(s)
  tag ++ " " ++ F.Fixed.show(S.Player.x(p)) ++ " " ++ F.Fixed.show(S.Player.y(p)) ++ " "
    ++ A.Angle.show(S.Player.angle(p)) ++ " z " ++ F.Fixed.show(S.Player.z(p))
    ++ " floor " ++ F.Fixed.show(S.Player.floorz(p))
    ++ " eye " ++ F.Fixed.show((S.Player.viewz(p) - S.Player.floorz(p) : U32))

def step(tag: String, n: Nat, keys: K.Keys, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(K.Input.script(n, K.Input{keys, 0}), s)
  do IO<S.State>:
    IO.print(line(tag, q))
    return q

# A run of one command in a demo's units, then the clock, the player,
# the thinkers running, and a sector's floor and ceiling.
def watch(tag: String, +sector: U32, +s: S.State) -> String:
  line(tag ++ " tic " ++ U32.show(S.State.clock(s)), s) ++ " thinkers "
    ++ Nat.show(List.length(&2, S.Thinker, S.State.thinkers(s))) ++ " sector " ++ U32.show(sector) ++ " "
    ++ F.Fixed.show(L.Level.floor(S.State.level(s), sector)) ++ " "
    ++ F.Fixed.show(L.Level.ceil(S.State.level(s), sector))

def run(tag: String, n: Nat, cmd: K.Cmd, sector: U32, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.replicate(K.Cmd, n, cmd), s)
  do IO<S.State>:
    IO.print(watch(tag, sector, q))
    return q

def idle() -> K.Cmd:
  K.Cmd.idle()

def use() -> K.Cmd:
  K.Cmd.demo(0, 0, 0, True{})

def forward() -> K.Cmd:
  K.Cmd.demo(25, 0, 0, False{})

def at(+level: L.Level, x: U32, y: U32, degrees: U32) -> S.State:
  S.State.at(level, V.Leaf{0}, L.Start{F.Fixed.of_map(x), F.Fixed.of_map(y), A.Angle.of_thing(degrees)})

# The blue key door, sector 71, refuses.
def blue(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    b0 : S.State <- run("blue walk", 30n, forward(), 71, at(level, 832, 1400, 90))
    b1 : S.State <- run("use", 1n, use(), 71, b0)
    b2 : S.State <- run("-", 10n, idle(), 71, b1)
    IO.print("end")

# A use while the door closes sends it back up; one while it waits
# starts it down.
def turned(+closing: S.State) -> IO(Unit):
  do IO<Unit>:
    r1 : S.State <- run("closing -", 10n, idle(), 10, closing)
    r2 : S.State <- run("use", 1n, use(), 10, r1)
    r3 : S.State <- run("-", 10n, idle(), 10, r2)
    r4 : S.State <- run("-", 4n, idle(), 10, r3)
    r5 : S.State <- run("use", 1n, use(), 10, r4)
    IO.print("-")

def closes(+open: S.State) -> IO(S.State):
  do IO<S.State>:
    d4 : S.State <- run("-", 1n, idle(), 10, open)
    d5 : S.State <- run("-", 150n, idle(), 10, d4)
    run("-", 1n, idle(), 10, d5)

def shuts(+closing: S.State) -> IO(Unit):
  do IO<Unit>:
    d7 : S.State <- run("-", 61n, idle(), 10, closing)
    d8 : S.State <- run("-", 1n, idle(), 10, d7)
    turned(closing)

def opens(+open: S.State) -> IO(Unit):
  do IO<Unit>:
    closing : S.State <- closes(open)
    shuts(closing)
    w1 : S.State <- run("through walk", 40n, forward(), 10, open)
    c1 : S.State <- run("doorway walk", 6n, forward(), 10, open)
    c2 : S.State <- run("-", 179n, idle(), 10, c1)
    c3 : S.State <- run("-", 1n, idle(), 10, c2)
    c4 : S.State <- run("-", 1n, idle(), 10, c3)
    c5 : S.State <- run("-", 34n, idle(), 10, c4)
    IO.print("-")

# The first door, sector 10, from the pit south of it: used, held open,
# shut; turned twice; use held down all the while; walked through.
def used(+before: S.State) -> IO(Unit):
  do IO<Unit>:
    d1 : S.State <- run("use", 1n, use(), 10, before)
    d2 : S.State <- run("-", 20n, idle(), 10, d1)
    d3 : S.State <- run("-", 41n, idle(), 10, d2)
    opens(d3)
    h1 : S.State <- run("held use", 100n, use(), 10, before)
    h2 : S.State <- run("use", 200n, use(), 10, h1)
    IO.print("-")

def door(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    d0 : S.State <- run("door walk", 40n, forward(), 10, at(level, 832, 384, 90))
    used(d0)
    blue(level)

def free(+s: S.State) -> IO(S.State):
  +p = S.State.player(s)
  do IO<S.State>:
    IO.print("free at start " ++ Bool.show(S.Sim.free(S.State.level(s), S.Player.x(p), S.Player.y(p))))
    return s

def walk(p: Array<U32> & L.Level) -> IO(Unit):
  (a, +level) = p
  do IO<Unit>:
    s : S.State <- step("start", 0n, K.Keys.none(), S.State.start(level, V.Leaf{0}))
    p0 : S.State <- free(s)
    p1 : S.State <- step("U:1", 1n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}, p0)
    p2 : S.State <- step("U!:34", 34n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, p1)
    p3 : S.State <- step("L:20", 20n, K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}}, p2)
    p4 : S.State <- step("U!:200", 200n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, p3)
    p5 : S.State <- step("-:40", 40n, K.Keys{False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}, p4)
    p6 : S.State <- step("R:10", 10n, K.Keys{False{}, False{}, False{}, True{}, False{}, False{}, False{}, False{}}, p5)
    p7 : S.State <- step("U!:70", 70n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, p6)
    p8 : S.State <- step("L:30", 30n, K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}}, p7)
    p9 : S.State <- step("U:100", 100n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}, p8)
    p10 : S.State <- step("S:60", 60n, K.Keys{False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}}, p9)
    p11 : S.State <- step("D!:100", 100n, K.Keys{False{}, True{}, False{}, False{}, False{}, False{}, True{}, False{}}, p10)
    p12 : S.State <- step("R:40", 40n, K.Keys{False{}, False{}, False{}, True{}, False{}, False{}, False{}, False{}}, p11)
    p13 : S.State <- step("U!:120", 120n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, p12)
    p14 : S.State <- step("A!:40", 40n, K.Keys{False{}, False{}, False{}, False{}, True{}, False{}, True{}, False{}}, p13)
    q1 : S.State <- step("ledge U!:47", 47n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, S.State.start(level, V.Leaf{0}))
    q2 : S.State <- step("U!:1", 1n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, q1)
    q3 : S.State <- step("U!:1", 1n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, q2)
    q4 : S.State <- step("U!:15", 15n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, q3)
    q5 : S.State <- step("-:1", 1n, K.Keys.none(), q4)
    q6 : S.State <- step("-:40", 40n, K.Keys.none(), q5)
    door(level)

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    walk(L.Level.load(W.Wad.dir(bytes)))

#|start -416.000000 256.000000 0.000 z 0.000000 floor 0.000000 eye 41.000000
#|free at start True
#|U:1 -415.218765 256.000289 0.000 z 0.000000 floor 0.000000 eye 41.000015
#|U!:34 3.282882 256.157440 0.000 z 0.000000 floor 0.000000 eye 33.430175
#|L:20 137.245544 256.206893 61.523 z 12.000000 floor 12.000000 eye 40.403701
#|U!:200 704.228622 495.748413 61.523 z 0.000000 floor 0.000000 eye 40.744659
#|-:40 704.185119 495.791839 61.523 z 0.000000 floor 0.000000 eye 41.000000
#|R:10 704.185119 495.791839 35.156 z 0.000000 floor 0.000000 eye 41.000000
#|U!:70 735.938049 464.014968 35.156 z 0.000000 floor 0.000000 eye 40.617416
#|L:30 735.938049 464.014968 131.835 z 0.000000 floor 0.000000 eye 41.000000
#|U:100 592.012649 495.984710 131.835 z 0.000000 floor 0.000000 eye 41.065185
#|S:60 730.213378 469.756973 131.835 z 0.000000 floor 0.000000 eye 41.068618
#|D!:100 735.912536 464.048477 131.835 z 0.000000 floor 0.000000 eye 41.733978
#|R:40 735.963653 464.013015 0.000 z 0.000000 floor 0.000000 eye 41.000000
#|U!:120 735.963653 464.013015 0.000 z 0.000000 floor 0.000000 eye 41.763900
#|A!:40 697.996063 495.962036 0.000 z 0.000000 floor 0.000000 eye 41.147979
#|ledge U!:47 207.783569 256.234542 0.000 z 12.000000 floor 12.000000 eye 48.658081
#|U!:1 224.302001 256.240737 0.000 z 12.000000 floor -128.000000 eye 187.570556
#|U!:1 240.820434 256.246932 0.000 z 10.000000 floor -128.000000 eye 181.000000
#|U!:15 488.596923 256.339859 0.000 z -128.000000 floor -128.000000 eye 46.000000
#|-:1 505.115356 256.346054 0.000 z -128.000000 floor -128.000000 eye 46.408325
#|-:40 661.677886 256.402297 0.000 z -128.000000 floor -128.000000 eye 41.012115
#|door walk tic 40 831.926605 495.977203 90.000 z -128.000000 floor -128.000000 eye 40.975143 thinkers 0 sector 10 -128.000000 -128.000000
#|use tic 41 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -126.000000
#|- tic 61 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -86.000000
#|- tic 102 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -4.000000
#|- tic 103 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -4.000000
#|- tic 253 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -4.000000
#|- tic 254 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -6.000000
#|- tic 315 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -128.000000
#|- tic 316 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 0 sector 10 -128.000000 -128.000000
#|closing - tic 264 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -26.000000
#|use tic 265 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -24.000000
#|- tic 275 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -4.000000
#|- tic 279 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -4.000000
#|use tic 280 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -6.000000
#|-
#|through walk tic 142 831.822738 750.318176 90.000 z -128.000000 floor -128.000000 eye 42.976440 thinkers 1 sector 10 -128.000000 -4.000000
#|doorway walk tic 108 831.918884 510.046890 90.000 z -128.000000 floor -128.000000 eye 42.444900 thinkers 1 sector 10 -128.000000 -4.000000
#|- tic 287 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -72.000000
#|- tic 288 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -72.000000
#|- tic 289 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -70.000000
#|- tic 323 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -4.000000
#|-
#|held use tic 140 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 1 sector 10 -128.000000 -4.000000
#|use tic 340 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 0 sector 10 -128.000000 -128.000000
#|-
#|blue walk tic 30 831.941818 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.024505 thinkers 0 sector 71 -128.000000 -128.000000
#|use tic 31 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 0 sector 71 -128.000000 -128.000000
#|- tic 41 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 0 sector 71 -128.000000 -128.000000
#|end
