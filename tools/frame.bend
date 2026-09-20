# A frame as hex rows: E1M1 from the WAD named by BENDOOM_IWAD, the
# player put at rest on the floor at the place FRAME names, the commands
# SCRIPT names replayed through the sim (tools/script.bend has both
# forms; unset for none), and the frame rendered through the game's
# renderer, printed as 200 lines of 320 palette indices, two hex digits
# each. tools/oracle.nu diffs it against Chocolate Doom's frame after
# the same commands from the same place. It draws no heads-up message,
# as the Chocolate Doom it is compared with runs with show_messages 0;
# message pixels are checked in tests/render.bend instead.
#
#   bend tools/frame.bend -o frame
#   FRAME="-416 256 0" SCRIPT="20,0,0,0,0 34,50,0,0,0" ./frame
import Base
import ../src/bytes.bend as B
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/project.bend as P
import ../src/render.bend as R
import ./script.bend as T

def Frame.line(p: Array<U32> & List<&2, U32>) -> Array<U32> & String:
  (mem, xs) = p
  (mem, B.Bytes.hex(xs))

def Frame.print(p: Array<U32> & String) -> IO(Array<U32>):
  (mem, text) = p
  do IO<Array<U32>>:
    IO.print(text)
    return mem

def Frame.rows(n: Nat, +row: U32, mem: Array<U32>) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+m:
      do IO<Unit>:
        next : Array<U32> <- Frame.print(Frame.line(B.Bytes.each(~U32, ~B.Bytes.at,
          B.Bytes.fields(320n, (G.Gfx.frame() + row * 320 : U32), 1, [0]), mem)))
        Frame.rows(m, (row + 1 : U32), next)

def Frame.draw(place: L.Level.Start, script: List<&2, K.Cmd>, mem: Array<U32>, gl: G.Gfx & L.Level) ->
  IO(Unit):
  (+gfx, +level) = gl
  Frame.rows(200n, 0, R.Render.frame(P.Project.tables(level), gfx,
    S.Sim.replay(script, S.State.at(level, place)), False{}, mem))

def Frame.start(place: L.Level.Start, script: List<&2, K.Cmd>, w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  Frame.draw(place, script, mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    spot : String <- IO.try(String, IO.get_env("FRAME"))
    script : Result<&1, &1, U32 & String, String> <- IO.get_env("SCRIPT")
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    Frame.start(T.Script.place(String.split(spot, ' ')), List.concat(&2, K.Cmd,
      T.Script.runs(String.split(Result.default(&1, &1, U32 & String, String, script, ""), ' '))), world)
