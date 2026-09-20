# A demo as raw video: E1M1 from the WAD named by BENDOOM_IWAD, the demo
# named by DEMO played from the player 1 start, and each tic's frame
# printed in the window's colours, 320 by 200 RGB triples as a line of
# hex, 35 frames a second. nix run .#film decodes and encodes it.
import Base
import ./src/bytes.bend as B
import ./src/level.bend as L
import ./src/gfx.bend as G
import ./src/keys.bend as K
import ./src/sim.bend as S
import ./src/project.bend as P
import ./src/render.bend as R
import ./src/show.bend as V
import ./src/demo.bend as D

def Film.rgb(colours: List<&2, U32>) -> List<&2, U32>:
  match colours:
    case []:
      []
    case +c <> rest:
      ((c >> 16n) .&. 255 : U32) <> ((c >> 8n) .&. 255 : U32) <> (c .&. 255 : U32) <> Film.rgb(rest)

def Film.shot(p: Array<U32> & List<&2, U32>, rest: Array<U32> -> IO(Unit)) -> IO(Unit):
  (mem, colours) = p
  do IO<Unit>:
    IO.print(B.Bytes.hex(Film.rgb(colours)))
    rest(mem)

def Film.go(cmds: List<&2, K.Cmd>, +tables: P.Project.Tables, +gfx: G.Gfx, state: S.State, mem: Array<U32>) ->
  IO(Unit):
  match cmds:
    case []:
      IO.pure(Unit, Unit{})
    case cmd <> rest:
      +next = S.Sim.tic(cmd, state)
      Film.shot(V.Show.rgb(R.Render.frame(tables, gfx, next, True{}, mem)),
        m => Film.go(rest, tables, gfx, next, m))

def Film.play(demo: List<&2, U32>, mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  Film.go(D.Demo.play(demo), P.Project.tables(level), gfx, S.State.start(level), mem)

def Film.start(demo: List<&2, U32>, w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  Film.play(demo, mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("DEMO"))
    file : File <- IO.try(File, File.open(path, "r"))
    demo : List<&2, U32> <- B.Bytes.fold(~List<&2, U32>, ~(chunk => read => List.append(&2, U32, read, chunk)), file, [])
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    Film.start(demo, world)
