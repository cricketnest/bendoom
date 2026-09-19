# Freedoom's E1M1 from the player 1 start with no key, along the route
# milestone 4 wrote for an empty map: a command script in a demo's
# units, leg by leg, and after each leg the clock, the player, the
# thinkers running and whether the level has ended. The route: east
# onto the lift its west line calls and down with it; across the pit to
# the first door; through it and over the big room to the door in its
# west wall; through that, north over the walk-over line and along the
# north room. Then the run south meets the tech column at -192, 1600,
# record 59, which holds the player back: the use meant for the exit
# room's door falls short and starts nothing, the run west ends in front
# of it, and the use meant for the exit switch finds none, so the level
# does not end. Chocolate Doom, with every thing kept, plays the same
# script to the same frames: none of its pixels differs after the run
# south or at the end, where the ticket 06 build differs in 47586 after
# the run south. The positions are regression pins until ticket 11
# routes around the column.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/sim.bend as S

def idle(n: Nat) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.idle())

def run(n: Nat) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.demo(50, 0, 0, False{}))

def turn(by: U32) -> List<&2, K.Cmd>:
  [K.Cmd.demo(0, 0, by, False{})]

def use() -> List<&2, K.Cmd>:
  [K.Cmd.demo(0, 0, 0, True{})]

def line(tag: String, +s: S.State) -> String:
  +p = S.State.player(s)
  tag ++ " tic " ++ U32.show(S.State.clock(s)) ++ " " ++ F.Fixed.show(S.Player.x(p)) ++ " "
    ++ F.Fixed.show(S.Player.y(p)) ++ " " ++ A.Angle.show(S.Player.angle(p)) ++ " z "
    ++ F.Fixed.show(S.Player.z(p)) ++ " thinkers "
    ++ Nat.show(List.length(&2, S.Thinker, S.State.thinkers(s))) ++ " ended " ++ Bool.show(S.State.ended(s))

def leg(tag: String, runs: List<&2, List<&2, K.Cmd>>, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.concat(&2, K.Cmd, runs), s)
  do IO<S.State>:
    IO.print(line(tag, q))
    return q

def route(p: Array<U32> & L.Level) -> IO(Unit):
  (a, +level) = p
  do IO<Unit>:
    r1 : S.State <- leg("lift bottom", [run(35n), idle(40n)], S.State.start(level))
    r2 : S.State <- leg("first door", [turn(14), run(50n), turn(32), run(10n), turn(18), run(12n), idle(10n)], r1)
    r3 : S.State <- leg("through it", [use(), idle(62n), run(20n)], r2)
    r4 : S.State <- leg("west door", [turn(30), run(20n), turn(34),
      List.replicate(K.Cmd, 10n, K.Cmd.demo(25, 0, 0, False{})), idle(10n)], r3)
    r5 : S.State <- leg("north room", [use(), idle(62n), run(16n), turn(4294967232), run(40n), turn(64), run(36n),
      idle(12n)], r4)
    r6 : S.State <- leg("south to the column", [turn(64), run(22n), idle(10n)], r5)
    r7 : S.State <- leg("use short of the exit door", [use(), idle(36n), run(8n), idle(22n)], r6)
    r8 : S.State <- leg("west", [turn(4294967232), run(9n), idle(20n)], r7)
    r9 : S.State <- leg("use", [use()], r8)
    r10 : S.State <- leg("after", [idle(5n)], r9)
    return Unit{}

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    route(L.Level.load(W.Wad.dir(bytes)))
#|lift bottom tic 75 164.275604 256.215866 0.000 z -124.000000 thinkers 10 ended False
#|first door tic 160 832.991958 495.952957 90.000 z -128.000000 thinkers 10 ended False
#|through it tic 243 837.883972 690.665405 90.000 z -128.000000 thinkers 10 ended False
#|west door tic 285 576.143997 1053.525039 180.000 z -128.000000 thinkers 10 ended False
#|north room tic 454 -191.832733 1711.947463 180.000 z -128.000000 thinkers 10 ended False
#|south to the column tic 487 -227.955474 1488.071182 270.000 z -128.000000 thinkers 10 ended False
#|use short of the exit door tic 554 -229.367279 1416.050430 270.000 z -128.000000 thinkers 10 ended False
#|west tic 584 -239.953552 1416.029861 180.000 z -128.000000 thinkers 9 ended False
#|use tic 585 -239.953552 1416.029861 180.000 z -128.000000 thinkers 9 ended False
#|after tic 590 -239.953552 1416.029861 180.000 z -128.000000 thinkers 9 ended False
