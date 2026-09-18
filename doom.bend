# Bendoom. The WAD named by BENDOOM_IWAD loads, E1M1 shows in a window
# from the player's eye, and the keyboard walks the player at Doom's 35
# tics a second whatever the frame rate; Esc or Close quits.
import Base
import ./src/bytes.bend as B
import ./src/wad.bend as W
import ./src/level.bend as L
import ./src/gfx.bend as G
import ./src/keys.bend as K
import ./src/game.bend as M

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    world : Array<U32> & G.Gfx & L.Level <- IO.pass(Array<U32> & G.Gfx & L.Level, G.Gfx.load(W.Wad.dir(bytes)))
    now : Nat <- IO.now()
    M.Game.start(U32.to_nat(4294967295), K.Keys.none(), now, world)
