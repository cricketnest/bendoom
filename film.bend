# A demo as raw video: E1M1 from the WAD named by BENDOOM_IWAD, the demo
# named by DEMO played from the player 1 start, and each tic's frame
# written to standard output in the window's colours, 320 by 200 RGB
# triples, 35 frames a second. nix run .#film encodes it.
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

def Film.more(bytes: List<&2, U32>, file: File, more: File -> IO(List<&2, U32>)) -> IO(List<&2, U32>):
  match bytes:
    case []:
      do IO<List<&2, U32>>:
        File.close(file)
        return []
    case b <> rest:
      IO.bind(List<&2, U32>, List<&2, U32>, more(file),
        after => IO.pure(List<&2, U32>, List.append(&2, U32, b <> rest, after)))

def Film.chunk(p: File & Result<&1, &1, U32 & String, List<&2, U32>>, more: File -> IO(List<&2, U32>)) ->
  IO(List<&2, U32>):
  (file, got) = p
  IO.bind(List<&2, U32>, List<&2, U32>, IO.pass(List<&2, U32>, got), bytes => Film.more(bytes, file, more))

# The file's bytes, read 64 KiB at a time until a read comes back empty.
def Film.read(fuel: Nat, file: File) -> IO(List<&2, U32>):
  match fuel:
    case 0n:
      IO.pure(List<&2, U32>, [])
    case 1n+f:
      IO.bind(File & Result<&1, &1, U32 & String, List<&2, U32>>, List<&2, U32>, File.read_bytes(file, 65536),
        p => Film.chunk(p, h => Film.read(f, h)))

def Film.rgb(colours: List<&2, U32>) -> List<&2, U32>:
  match colours:
    case []:
      []
    case +c <> rest:
      ((c >> 16n) .&. 255 : U32) <> ((c >> 8n) .&. 255 : U32) <> (c .&. 255 : U32) <> Film.rgb(rest)

def Film.shot(out: File, p: Array<U32> & List<&2, U32>, rest: File -> Array<U32> -> IO(Unit)) -> IO(Unit):
  (mem, colours) = p
  do IO<Unit>:
    kept : File <- B.Bytes.put(out, Film.rgb(colours))
    rest(kept, mem)

def Film.go(cmds: List<&2, K.Cmd>, +tables: P.Project.Tables, +gfx: G.Gfx, state: S.State, out: File,
  mem: Array<U32>) -> IO(Unit):
  match cmds:
    case []:
      File.close(out)
    case cmd <> rest:
      +next = S.Sim.tic(cmd, state)
      Film.shot(out, B.Bytes.each(~U32, ~V.Show.colour, B.Bytes.fields(U32.to_nat(64000), 0, 1, [0]),
        R.Render.frame(tables, gfx, next, mem)), o => m => Film.go(rest, tables, gfx, next, o, m))

def Film.play(demo: List<&2, U32>, out: File, mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  Film.go(D.Demo.play(demo), P.Project.tables(level), gfx, S.State.start(level), out, mem)

def Film.start(demo: List<&2, U32>, out: File, w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  Film.play(demo, out, mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("DEMO"))
    file : File <- IO.try(File, File.open(path, "r"))
    demo : List<&2, U32> <- Film.read(U32.to_nat(65536), file)
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    out : File <- IO.try(File, File.open("/dev/stdout", "w"))
    Film.start(demo, out, world)
