# A frame as hex rows: E1M1 from the WAD named by BENDOOM_IWAD, the
# player put at rest on the floor at the position and angle FRAME names
# ("x y degrees", map units, the angle in steps of 45 as a thing's is),
# the commands SCRIPT names replayed through the sim (runs a space
# apart, each "count,forward,side,turn,use" in a demo file's units, the
# use 0 or 1; unset for none), and the frame rendered through the game's
# renderer, printed as 200 lines of 320 palette indices, two hex digits
# each. tools/oracle.nu diffs it against Chocolate Doom's frame after
# the same commands from the same place.
#
#   bend tools/frame.bend -o frame
#   FRAME="-416 256 0" SCRIPT="20,0,0,0,0 34,50,0,0,0" ./frame
import Base
import ../src/bytes.bend as B
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/project.bend as P
import ../src/render.bend as R

# A whole number with its sign, in U32's wrapping arithmetic.
def Frame.int(s: String) -> U32:
  match s:
    case SCon{Chr{45}, rest}:
      (0 - Maybe.default(&2, U32, U32.read(rest), 0) : U32)
    case other:
      Maybe.default(&2, U32, U32.read(other), 0)

def Frame.place(words: List<&2, String>) -> L.Level.Start:
  match words:
    case x <> y <> degrees <> rest:
      L.Start{(Frame.int(x) << 16n : U32), (Frame.int(y) << 16n : U32), A.Angle.of_thing(Frame.int(degrees))}
    case _:
      L.Start{0, 0, 0}

def Frame.run(fields: List<&2, String>) -> List<&2, K.Cmd>:
  match fields:
    case [n, forward, side, turn, use]:
      List.replicate(K.Cmd, U32.to_nat(Frame.int(n)),
        K.Cmd.demo(Frame.int(forward), Frame.int(side), Frame.int(turn), U32.is_eq(Frame.int(use), 1)))
    case _:
      []

def Frame.script(runs: List<&2, String>) -> List<&2, K.Cmd>:
  match runs:
    case []:
      []
    case run <> rest:
      List.append(&2, K.Cmd, Frame.run(String.split(run, ',')), Frame.script(rest))

def Frame.digit(+d: U32) -> Char:
  Char.from_u32(Bool.pick(U32, U32.is_lt(d, 10), (48 + d : U32), (87 + d : U32)))

def Frame.hex(xs: List<&2, U32>) -> List<&2, Char>:
  match xs:
    case []:
      []
    case +x <> rest:
      Frame.digit((x >> 4n : U32)) <> Frame.digit((x .&. 15 : U32)) <> Frame.hex(rest)

def Frame.line(p: Array<U32> & List<&2, U32>) -> Array<U32> & String:
  (mem, xs) = p
  (mem, String.from_list(Frame.hex(xs)))

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
  (gfx, +level) = gl
  Frame.rows(200n, 0, R.Render.frame(P.Project.tables(level), level, gfx,
    S.Sim.replay(script, level, S.Player.at(level, place)), mem))

def Frame.start(place: L.Level.Start, script: List<&2, K.Cmd>, w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  Frame.draw(place, script, mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    spot : String <- IO.try(String, IO.get_env("FRAME"))
    script : Result<&1, &1, U32 & String, String> <- IO.get_env("SCRIPT")
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    Frame.start(Frame.place(String.split(spot, ' ')),
      Frame.script(String.split(Result.default(&1, &1, U32 & String, String, script, ""), ' ')), world)
