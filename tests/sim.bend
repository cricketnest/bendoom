# E1M1 from the WAD named by BENDOOM_IWAD, loaded by the game's loader,
# and scripted runs through the game's step. First two walks from the
# player 1 start, the position, facing, height, floor and eye above the
# floor after each run of held keys (U up, D down, L left, R right, A
# strafe left, S strafe right, ! run): the first turns on the lift its
# run called and rides it into the pit; the second runs across that
# lift and off its east edge into the fall and the landing. Freedoom's
# first map is not id's: the shareware start is 1056, -3616 facing 90.
# The start's things: on Hurt Me Plenty THINGS record 245 alone, the
# dead former sergeant (record 281, the other of type 19, is for the
# easy skills), on sector 170's floor 16 units up, as a nushell walk of
# the WAD's nodes finds it; the random index is 5 once P_SpawnMobj has
# drawn for the player and for it and the three flashes have spawned.
# Then the movers and the lights, as runs of one command in a demo's
# units from a place, each line with the clock, the thinkers running
# and chosen sectors' floors and ceilings: the first door used, turned
# twice, held, walked through and closed on the player; the special 23
# switch; a special 2 line crossed both ways; the lift called by its
# line and by its switch; the blue key door refusing; the exit switch;
# the blinks and the strobe from the start. The heights and tics are
# the hand computations in milestone 4's tickets 04 to 10; the blinks'
# lights, a nushell replay of T_LightFlash over Chocolate Doom's random
# table from index 2, which from index 1 gives milestone 4's; the
# positions are regression pins.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/things.bend as H

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

def heights(sectors: List<&2, U32>, +level: L.Level) -> String:
  match sectors:
    case []:
      ""
    case +sector <> rest:
      " sector " ++ U32.show(sector) ++ " " ++ F.Fixed.show(L.Level.floor(level, sector)) ++ " "
        ++ F.Fixed.show(L.Level.ceil(level, sector)) ++ heights(rest, level)

# A run of one command in a demo's units, then the clock, the player,
# the thinkers running, and some sectors' floors and ceilings.
def watch(tag: String, sectors: List<&2, U32>, +s: S.State) -> String:
  line(tag ++ " tic " ++ U32.show(S.State.clock(s)), s) ++ " thinkers "
    ++ Nat.show(List.length(&2, S.Thinker, S.State.thinkers(s))) ++ heights(sectors, S.State.level(s))

def run(tag: String, n: Nat, cmd: K.Cmd, sectors: List<&2, U32>, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.replicate(K.Cmd, n, cmd), s)
  do IO<S.State>:
    IO.print(watch(tag, sectors, q))
    return q

def idle() -> K.Cmd:
  K.Cmd.idle()

def use() -> K.Cmd:
  K.Cmd.demo(0, 0, 0, True{})

def forward() -> K.Cmd:
  K.Cmd.demo(25, 0, 0, False{})

def at(+level: L.Level, x: U32, y: U32, degrees: U32) -> S.State:
  S.State.at(level, L.Start{F.Fixed.of_map(x), F.Fixed.of_map(y), A.Angle.of_thing(degrees)})

# Freedoom's special 23 switch, line 753: its tag's three blocks lower
# at 1 a tic to the lowest floor around each, and it works once.
def floors(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    f0 : S.State <- run("switch walk", 30n, forward(), [76, 126, 129], at(level, 2064, 65276, 90))
    f1 : S.State <- run("use", 1n, use(), [76, 126, 129], f0)
    f2 : S.State <- run("-", 119n, idle(), [76, 126, 129], f1)
    f3 : S.State <- run("-", 1n, idle(), [76, 126, 129], f2)
    f4 : S.State <- run("-", 7n, idle(), [76, 126, 129], f3)
    f5 : S.State <- run("-", 1n, idle(), [76, 126, 129], f4)
    f6 : S.State <- run("-", 7n, idle(), [76, 126, 129], f5)
    f7 : S.State <- run("-", 1n, idle(), [76, 126, 129], f6)
    f8 : S.State <- run("use", 1n, use(), [76, 126, 129], f7)
    IO.print("-")

# Freedoom's special 2 lines along x 2032: crossing one opens sector 145
# for good, and crossing it again starts nothing.
def crossed(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    x0 : S.State <- run("trigger walk", 16n, forward(), [145], at(level, 1960, 65086, 0))
    x1 : S.State <- run("over", 1n, forward(), [145], x0)
    x2 : S.State <- run("-", 61n, idle(), [145], x1)
    x3 : S.State <- run("-", 1n, idle(), [145], x2)
    x4 : S.State <- run("back", 40n, K.Cmd.demo(4294967271, 0, 0, False{}), [145], x3)
    IO.print("-")

# Freedoom's first lift, sector 98: called by the walk-over line on its
# west edge and ridden down and up, then called by its switch from the
# pit east of it, used again while it runs, and again once it is back.
def lift(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    l0 : S.State <- run("lift run", 35n, K.Cmd.demo(50, 0, 0, False{}), [98], S.State.start(level))
    l1 : S.State <- run("-", 4n, idle(), [98], l0)
    l2 : S.State <- run("over", 1n, idle(), [98], l1)
    l3 : S.State <- run("-", 33n, idle(), [98], l2)
    l4 : S.State <- run("-", 1n, idle(), [98], l3)
    l5 : S.State <- run("-", 105n, idle(), [98], l4)
    l6 : S.State <- run("-", 1n, idle(), [98], l5)
    l7 : S.State <- run("-", 33n, idle(), [98], l6)
    l8 : S.State <- run("-", 1n, idle(), [98], l7)
    s0 : S.State <- run("lift switch walk", 10n, forward(), [98], at(level, 240, 256, 180))
    s1 : S.State <- run("use", 1n, use(), [98], s0)
    s2 : S.State <- run("-", 1n, idle(), [98], s1)
    s3 : S.State <- run("use", 1n, use(), [98], s2)
    s4 : S.State <- run("-", 171n, idle(), [98], s3)
    s5 : S.State <- run("-", 1n, idle(), [98], s4)
    s6 : S.State <- run("use", 1n, use(), [98], s5)
    IO.print("-")

# The blue key door, sector 71, refuses.
def blue(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    b0 : S.State <- run("blue walk", 30n, forward(), [71], at(level, 832, 1400, 90))
    b1 : S.State <- run("use", 1n, use(), [71], b0)
    b2 : S.State <- run("-", 10n, idle(), [71], b1)
    IO.print("-")

# A run, then whether the level has ended and the exit line's special.
def ending(tag: String, n: Nat, cmd: K.Cmd, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.replicate(K.Cmd, n, cmd), s)
  do IO<S.State>:
    IO.print(watch(tag, [], q) ++ " ended " ++ Bool.show(S.State.ended(q)) ++ " special "
      ++ U32.show(L.Level.special(S.State.level(q), 407)))
    return q

def exits(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    x0 : S.State <- ending("exit first tic use", 1n, use(), at(level, 65184, 1296, 180))
    x1 : S.State <- ending("-", 19n, idle(), x0)
    x2 : S.State <- ending("use", 1n, use(), x1)
    x3 : S.State <- ending("walk held use", 10n, K.Cmd.demo(25, 0, 0, True{}), x2)
    IO.print("-")

def lit(sectors: List<&2, U32>, +level: L.Level) -> String:
  match sectors:
    case []:
      ""
    case +sector <> rest:
      " sector " ++ U32.show(sector) ++ " " ++ U32.show(L.Level.sector.light(level, sector)) ++ lit(rest, level)

# The lights of four sectors after each run of idle tics.
def lights(gaps: List<&2, Nat>, +s: S.State) -> IO(Unit):
  match gaps:
    case []:
      IO.print("end")
    case n <> rest:
      do IO<Unit>:
        IO.print("lights tic " ++ U32.show(S.State.clock(s)) ++ lit([32, 33, 48, 90], S.State.level(s)))
        lights(rest, S.Sim.replay(List.replicate(K.Cmd, n, idle()), s))

# A use while the door closes sends it back up; one while it waits
# starts it down.
def turned(+closing: S.State) -> IO(Unit):
  do IO<Unit>:
    r1 : S.State <- run("closing -", 10n, idle(), [10], closing)
    r2 : S.State <- run("use", 1n, use(), [10], r1)
    r3 : S.State <- run("-", 10n, idle(), [10], r2)
    r4 : S.State <- run("-", 4n, idle(), [10], r3)
    r5 : S.State <- run("use", 1n, use(), [10], r4)
    IO.print("-")

def closes(+open: S.State) -> IO(S.State):
  do IO<S.State>:
    d4 : S.State <- run("-", 1n, idle(), [10], open)
    d5 : S.State <- run("-", 150n, idle(), [10], d4)
    run("-", 1n, idle(), [10], d5)

def shuts(+closing: S.State) -> IO(Unit):
  do IO<Unit>:
    d7 : S.State <- run("-", 61n, idle(), [10], closing)
    d8 : S.State <- run("-", 1n, idle(), [10], d7)
    turned(closing)

def opens(+open: S.State) -> IO(Unit):
  do IO<Unit>:
    closing : S.State <- closes(open)
    shuts(closing)
    w1 : S.State <- run("through walk", 40n, forward(), [10], open)
    c1 : S.State <- run("doorway walk", 6n, forward(), [10], open)
    c2 : S.State <- run("-", 179n, idle(), [10], c1)
    c3 : S.State <- run("-", 1n, idle(), [10], c2)
    c4 : S.State <- run("-", 1n, idle(), [10], c3)
    c5 : S.State <- run("-", 34n, idle(), [10], c4)
    IO.print("-")

# The first door, sector 10, from the pit south of it: used, held open,
# shut; turned twice; use held down all the while; walked through.
def used(+before: S.State) -> IO(Unit):
  do IO<Unit>:
    d1 : S.State <- run("use", 1n, use(), [10], before)
    d2 : S.State <- run("-", 20n, idle(), [10], d1)
    d3 : S.State <- run("-", 41n, idle(), [10], d2)
    opens(d3)
    h1 : S.State <- run("held use", 100n, use(), [10], before)
    h2 : S.State <- run("use", 200n, use(), [10], h1)
    IO.print("-")

def door(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    d0 : S.State <- run("door walk", 40n, forward(), [10], at(level, 832, 384, 90))
    used(d0)
    floors(level)
    crossed(level)
    lift(level)
    blue(level)
    exits(level)
    lights([1n, 34n, 1n, 4n, 1n, 23n, 1n, 1n, 1n, 2n, 2n, 60n, 1n, 2n, 1n, 1n, 1n, 1n, 4n, 1n, 0n], S.State.start(level))

def spawned(things: List<&2, H.Thing>) -> String:
  match things:
    case []:
      ""
    case H.Thing{id, kind, x, y, z, sector, state} <> rest:
      " thing " ++ U32.show(id) ++ " type " ++ U32.show(kind) ++ " at " ++ F.Fixed.show(x) ++ " " ++ F.Fixed.show(y)
        ++ " z " ++ F.Fixed.show(z) ++ " sector " ++ U32.show(sector) ++ " state " ++ U32.show(state) ++ spawned(rest)

def free(+s: S.State) -> IO(S.State):
  +p = S.State.player(s)
  do IO<S.State>:
    IO.print("free at start " ++ Bool.show(S.Sim.free(S.State.level(s), S.Player.x(p), S.Player.y(p))))
    IO.print("things at start" ++ spawned(S.State.things(s)) ++ " random " ++ U32.show(S.State.rnd(s)))
    return s

def walk(p: Array<U32> & L.Level) -> IO(Unit):
  (a, +level) = p
  do IO<Unit>:
    s : S.State <- step("start", 0n, K.Keys.none(), S.State.start(level))
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
    q1 : S.State <- step("ledge U!:47", 47n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, S.State.start(level))
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
#|things at start thing 245 type 19 at 1248.000000 224.000000 z 16.000000 sector 170 state 0 random 5
#|U:1 -415.218765 256.000289 0.000 z 0.000000 floor 0.000000 eye 41.000015
#|U!:34 3.282882 256.157440 0.000 z 0.000000 floor 0.000000 eye 33.430175
#|L:20 137.245544 256.206893 61.523 z -48.000000 floor -48.000000 eye 44.403701
#|U!:200 879.976928 495.961242 61.523 z -128.000000 floor -128.000000 eye 40.722702
#|-:40 879.976928 495.961242 61.523 z -128.000000 floor -128.000000 eye 41.000000
#|R:10 879.976928 495.961242 35.156 z -128.000000 floor -128.000000 eye 41.000000
#|U!:70 879.976928 495.976135 35.156 z -128.000000 floor -128.000000 eye 40.730163
#|L:30 879.976928 495.976135 131.835 z -128.000000 floor -128.000000 eye 41.000000
#|U:100 784.014022 495.985275 131.835 z -128.000000 floor -128.000000 eye 41.065185
#|S:60 879.981826 495.988571 131.835 z -128.000000 floor -128.000000 eye 41.059051
#|D!:100 811.054748 331.127044 131.835 z -128.000000 floor -128.000000 eye 41.392868
#|R:40 803.277694 323.355331 0.000 z -128.000000 floor -128.000000 eye 41.000000
#|U!:120 879.949401 430.466888 0.000 z -128.000000 floor -128.000000 eye 41.234771
#|A!:40 879.826950 495.961883 0.000 z -128.000000 floor -128.000000 eye 41.147918
#|ledge U!:47 207.783569 256.234542 0.000 z -24.000000 floor -24.000000 eye 52.658081
#|U!:1 224.302001 256.240737 0.000 z -24.000000 floor -128.000000 eye 151.570556
#|U!:1 240.820434 256.246932 0.000 z -26.000000 floor -128.000000 eye 145.000000
#|U!:15 492.898864 256.341476 0.000 z -128.000000 floor -128.000000 eye 42.834960
#|-:1 509.055541 256.347518 0.000 z -128.000000 floor -128.000000 eye 43.033325
#|-:40 662.189941 256.402572 0.000 z -128.000000 floor -128.000000 eye 41.011581
#|door walk tic 40 831.926605 495.977203 90.000 z -128.000000 floor -128.000000 eye 40.975143 thinkers 9 sector 10 -128.000000 -128.000000
#|use tic 41 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -126.000000
#|- tic 61 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -86.000000
#|- tic 102 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 103 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 253 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 254 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -6.000000
#|- tic 315 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -128.000000
#|- tic 316 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 10 -128.000000 -128.000000
#|closing - tic 264 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -26.000000
#|use tic 265 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -24.000000
#|- tic 275 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 279 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|use tic 280 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -6.000000
#|-
#|through walk tic 142 831.822738 750.318176 90.000 z -128.000000 floor -128.000000 eye 42.976440 thinkers 10 sector 10 -128.000000 -4.000000
#|doorway walk tic 108 831.918884 510.046890 90.000 z -128.000000 floor -128.000000 eye 42.444900 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 287 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -72.000000
#|- tic 288 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -72.000000
#|- tic 289 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -70.000000
#|- tic 323 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|-
#|held use tic 140 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|use tic 340 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 10 -128.000000 -128.000000
#|-
#|switch walk tic 30 2063.945510 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.024505 thinkers 9 sector 76 272.000000 272.000000 sector 126 264.000000 264.000000 sector 129 264.000000 264.000000
#|use tic 31 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 12 sector 76 271.000000 272.000000 sector 126 263.000000 264.000000 sector 129 263.000000 264.000000
#|- tic 150 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 12 sector 76 152.000000 272.000000 sector 126 144.000000 264.000000 sector 129 144.000000 264.000000
#|- tic 151 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 11 sector 76 151.000000 272.000000 sector 126 144.000000 264.000000 sector 129 143.000000 264.000000
#|- tic 158 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 11 sector 76 144.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|- tic 159 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 10 sector 76 143.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|- tic 166 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 10 sector 76 136.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|- tic 167 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 9 sector 76 136.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|use tic 168 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 9 sector 76 136.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|-
#|trigger walk tic 16 2029.450805 -449.974945 0.000 z 128.000000 floor 128.000000 eye 35.541717 thinkers 9 sector 145 136.000000 136.000000
#|over tic 17 2036.220657 -449.972503 0.000 z 128.000000 floor 128.000000 eye 35.539337 thinkers 10 sector 145 136.000000 138.000000
#|- tic 78 2101.079208 -449.951568 0.000 z 128.000000 floor 128.000000 eye 41.000000 thinkers 10 sector 145 136.000000 260.000000
#|- tic 79 2101.079208 -449.951568 0.000 z 128.000000 floor 128.000000 eye 41.000000 thinkers 9 sector 145 136.000000 260.000000
#|back tic 119 1846.728271 -450.053344 0.000 z 136.000000 floor 136.000000 eye 28.955810 thinkers 9 sector 145 136.000000 260.000000
#|-
#|lift run tic 35 11.349639 256.160812 0.000 z 0.000000 floor 0.000000 eye 33.430175 thinkers 9 sector 98 12.000000 128.000000
#|- tic 39 62.115066 256.179794 0.000 z 12.000000 floor 12.000000 eye 25.687744 thinkers 9 sector 98 12.000000 128.000000
#|over tic 40 71.977874 256.183471 0.000 z 8.000000 floor 8.000000 eye 33.644653 thinkers 10 sector 98 8.000000 128.000000
#|- tic 73 163.614135 256.215759 0.000 z -124.000000 floor -124.000000 eye 44.989715 thinkers 10 sector 98 -124.000000 128.000000
#|- tic 74 163.961135 256.215820 0.000 z -124.000000 floor -124.000000 eye 40.988113 thinkers 10 sector 98 -124.000000 128.000000
#|- tic 179 166.744613 256.215911 0.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 -124.000000 128.000000
#|- tic 180 166.744613 256.215911 0.000 z -120.000000 floor -120.000000 eye 37.000000 thinkers 10 sector 98 -120.000000 128.000000
#|- tic 213 166.744613 256.215911 0.000 z 12.000000 floor 12.000000 eye 37.000000 thinkers 10 sector 98 12.000000 128.000000
#|- tic 214 166.744613 256.215911 0.000 z 12.000000 floor 12.000000 eye 41.000000 thinkers 9 sector 98 12.000000 128.000000
#|lift switch walk tic 10 208.160308 255.986923 180.000 z -124.000000 floor -124.000000 eye 40.314453 thinkers 9 sector 98 12.000000 128.000000
#|use tic 11 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 40.500000 thinkers 10 sector 98 8.000000 128.000000
#|- tic 12 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 4.000000 128.000000
#|use tic 13 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 0.000000 128.000000
#|- tic 184 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 12.000000 128.000000
#|- tic 185 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 9 sector 98 12.000000 128.000000
#|use tic 186 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 8.000000 128.000000
#|-
#|blue walk tic 30 831.941818 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.024505 thinkers 9 sector 71 -128.000000 -128.000000
#|use tic 31 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000
#|- tic 41 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000
#|-
#|exit first tic use tic 1 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended False special 11
#|- tic 20 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended False special 11
#|use tic 21 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended True special 0
#|walk held use tic 21 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended True special 0
#|-
#|lights tic 0 sector 32 176 sector 33 176 sector 48 140 sector 90 192
#|lights tic 1 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 35 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 36 sector 32 176 sector 33 176 sector 48 140 sector 90 192
#|lights tic 40 sector 32 176 sector 33 176 sector 48 140 sector 90 192
#|lights tic 41 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 64 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 65 sector 32 144 sector 33 140 sector 48 120 sector 90 160
#|lights tic 66 sector 32 144 sector 33 140 sector 48 120 sector 90 160
#|lights tic 67 sector 32 144 sector 33 140 sector 48 120 sector 90 160
#|lights tic 69 sector 32 144 sector 33 176 sector 48 140 sector 90 160
#|lights tic 71 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 131 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 132 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 134 sector 32 176 sector 33 140 sector 48 120 sector 90 160
#|lights tic 135 sector 32 176 sector 33 140 sector 48 120 sector 90 160
#|lights tic 136 sector 32 176 sector 33 140 sector 48 120 sector 90 160
#|lights tic 137 sector 32 176 sector 33 176 sector 48 120 sector 90 160
#|lights tic 138 sector 32 144 sector 33 176 sector 48 120 sector 90 160
#|lights tic 142 sector 32 144 sector 33 176 sector 48 140 sector 90 160
#|lights tic 143 sector 32 144 sector 33 176 sector 48 140 sector 90 160
#|end
