# A measurement, not a test: the game's own loop in its window for 600
# frames, and the frames a second it made. WALK=1 holds the run and up
# keys, so the player runs east from the start, down the step and off
# the ledge into the pit; without it the player stands at the start.
# Build natively and run it where a window can open:
#
#   bend bench/window.bend -o window
#   ./window; WALK=1 ./window
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/game.bend as M

def Bench.keys(+walk: Bool) -> K.Keys:
  K.Keys{walk, False{}, False{}, False{}, False{}, False{}, walk}

def Bench.rate(+t0: Nat, +t1: Nat) -> String:
  Nat.show(Nat.div(U32.to_nat(600000), Nat.sub(t1, t0))) ++ " frames a second (600 frames in "
    ++ Nat.show(Nat.sub(t1, t0)) ++ " ms)"

def Bench.run(+t0: Nat, keys: K.Keys, world: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  do IO<Unit>:
    M.Game.start(600n, keys, t0, world)
    t1 : Nat <- IO.now()
    IO.print(Bench.rate(t0, t1))

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    walk : Result<&1, &1, U32 & String, String> <- IO.get_env("WALK")
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    world : Array<U32> & G.Gfx & L.Level <- IO.pass(Array<U32> & G.Gfx & L.Level, G.Gfx.load(W.Wad.dir(bytes)))
    t0 : Nat <- IO.now()
    Bench.run(t0, Bench.keys(Result.is_done(&1, &1, U32 & String, String, walk)), world)
