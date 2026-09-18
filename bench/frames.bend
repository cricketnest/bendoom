# A measurement, not a test: the game's frame without the window, a
# hundred times over: E1M1 rendered from the player 1 start and folded
# into the window's image. Build natively and time it:
#
#   bend bench/frames.bend -o frames
#   time ./frames
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/sim.bend as S
import ../src/project.bend as P
import ../src/render.bend as R
import ../src/show.bend as V

def Bench.drop(p: Array<U32> & Image) -> Array<U32>:
  (mem, image) = p
  mem

def Bench.go(n: Nat, +tables: P.Project.Tables, +level: L.Level, +gfx: G.Gfx, +p: S.Player,
  mem: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Bench.go(m, tables, level, gfx, p, Bench.drop(V.Show.image(R.Render.frame(tables, level, gfx, p, mem))))

def Bench.peek(p: Array<U32> & U32) -> U32:
  (mem, v) = p
  v

def Bench.frames(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  IO.print("centre " ++ U32.show(Bench.peek(B.Bytes.at(Bench.go(100n, P.Project.tables(level), level, gfx,
    S.Player.start(level), mem), (84 * 320 + 160 : U32)))))

def Bench.start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  Bench.frames(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    world : Array<U32> & G.Gfx & L.Level <- IO.pass(Array<U32> & G.Gfx & L.Level, G.Gfx.load(W.Wad.dir(bytes)))
    Bench.start(world)
