# E1M1 from the WAD named by BENDOOM_IWAD, loaded by the game's loader,
# and a scripted walk through the game's step: the player 1 start, then
# the position, facing and floor after each run of held keys (U up, D
# down, L left, R right, A strafe left, S strafe right, ! run).
# Freedoom's first map is not id's: the shareware start is 1056, -3616
# facing 90, and its first tic forward lands at 1055.999694, -3615.218765.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/sim.bend as S

def line(tag: String, +p: S.Player) -> String:
  tag ++ " " ++ F.Fixed.show(S.Player.x(p)) ++ " " ++ F.Fixed.show(S.Player.y(p)) ++ " "
    ++ A.Angle.show(S.Player.angle(p)) ++ " floor " ++ F.Fixed.show(S.Player.floorz(p))

def step(+level: L.Level, tag: String, n: Nat, keys: K.Keys, p: S.Player) -> IO(S.Player):
  +q = S.Sim.run(n, level, keys, p)
  do IO<S.Player>:
    IO.print(line(tag, q))
    return q

def free(+level: L.Level, +p: S.Player) -> IO(S.Player):
  do IO<S.Player>:
    IO.print("free at start " ++ Bool.show(S.Sim.free(level, S.Player.x(p), S.Player.y(p))))
    return p

def walk(p: Array<U32> & L.Level) -> IO(Unit):
  (a, +level) = p
  do IO<Unit>:
    s : S.Player <- step(level, "start", 0n, K.Keys.none(), S.Player.start(level))
    p0 : S.Player <- free(level, s)
    p1 : S.Player <- step(level, "U:1", 1n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}}, p0)
    p2 : S.Player <- step(level, "U!:34", 34n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}}, p1)
    p3 : S.Player <- step(level, "L:20", 20n, K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}}, p2)
    p4 : S.Player <- step(level, "U!:200", 200n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}}, p3)
    p5 : S.Player <- step(level, "-:40", 40n, K.Keys{False{}, False{}, False{}, False{}, False{}, False{}, False{}}, p4)
    p6 : S.Player <- step(level, "R:10", 10n, K.Keys{False{}, False{}, False{}, True{}, False{}, False{}, False{}}, p5)
    p7 : S.Player <- step(level, "U!:70", 70n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}}, p6)
    p8 : S.Player <- step(level, "L:30", 30n, K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}}, p7)
    p9 : S.Player <- step(level, "U:100", 100n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}}, p8)
    p10 : S.Player <- step(level, "S:60", 60n, K.Keys{False{}, False{}, False{}, False{}, False{}, True{}, False{}}, p9)
    p11 : S.Player <- step(level, "D!:100", 100n, K.Keys{False{}, True{}, False{}, False{}, False{}, False{}, True{}}, p10)
    p12 : S.Player <- step(level, "R:40", 40n, K.Keys{False{}, False{}, False{}, True{}, False{}, False{}, False{}}, p11)
    p13 : S.Player <- step(level, "U!:120", 120n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}}, p12)
    p14 : S.Player <- step(level, "A!:40", 40n, K.Keys{False{}, False{}, False{}, False{}, True{}, False{}, True{}}, p13)
    IO.print("end")

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    walk(L.Level.load(W.Wad.dir(bytes)))

#|start -416.000000 256.000000 0.000 floor 0.000000
#|free at start True
#|U:1 -415.218765 256.000289 0.000 floor 0.000000
#|U!:34 3.282882 256.157440 0.000 floor 0.000000
#|L:20 137.245544 256.206893 61.523 floor 12.000000
#|U!:200 704.131713 495.831344 61.523 floor 0.000000
#|-:40 703.507431 495.994827 61.523 floor 0.000000
#|R:10 703.507431 495.994827 35.156 floor 0.000000
#|U!:70 735.929946 464.013916 35.156 floor 0.000000
#|L:30 735.929946 464.013916 131.835 floor 0.000000
#|U:100 592.012496 495.984558 131.835 floor 0.000000
#|S:60 728.447845 471.251831 131.835 floor 0.000000
#|D!:100 735.918228 464.025604 131.835 floor 0.000000
#|R:40 735.961837 464.012374 0.000 floor 0.000000
#|U!:120 735.961837 464.012374 0.000 floor 0.000000
#|A!:40 690.653869 495.963272 0.000 floor 0.000000
#|end
