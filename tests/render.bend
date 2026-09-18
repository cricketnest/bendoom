# Frames of E1M1 from the WAD named by BENDOOM_IWAD, rendered through
# the function the game draws with: for each, a 32-bit FNV-1a hash of the
# view's 320 by 168 palette indices and the indices at four pixels (the
# view's centre, near its top left, near its bottom right, and high on
# its centre column). Pinned to Freedoom.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/sim.bend as S
import ../src/project.bend as P
import ../src/draw.bend as D
import ../src/render.bend as R

type Hash is Type:
  Hash{mem: Array<U32>, h: U32}

def hash.mix(h: U32, p: Array<U32> & U32) -> Hash:
  (mem, v) = p
  Hash{mem, ((h .^. v) * 16777619 : U32)}

def hash.px(i: Nat, st: Hash) -> Hash:
  Hash{mem, h} = st
  hash.mix(h, B.Bytes.at(mem, (G.Gfx.frame() + U32.from_nat(i) : U32)))

def shows(xs: List<&2, U32>) -> List<&2, String>:
  match xs:
    case []:
      []
    case x <> rest:
      U32.show(x) <> shows(rest)

def pixels(h: U32, p: Array<U32> & List<&2, U32>) -> Array<U32> & String:
  (mem, xs) = p
  (mem, "hash " ++ U32.show(h) ++ " pixels " ++ String.join(shows(xs), " "))

def line(st: Hash) -> Array<U32> & String:
  Hash{mem, h} = st
  pixels(h, B.Bytes.each(~U32, ~B.Bytes.at, [(G.Gfx.frame() + 84 * 320 + 160 : U32),
    (G.Gfx.frame() + 10 * 320 + 10 : U32), (G.Gfx.frame() + 150 * 320 + 300 : U32),
    (G.Gfx.frame() + 20 * 320 + 160 : U32)], mem))

def print(tag: String, p: Array<U32> & String) -> IO(Array<U32>):
  (mem, text) = p
  do IO<Array<U32>>:
    IO.print(tag ++ " " ++ text)
    return mem

# A frame from the player, its line printed, and the array back.
def frame(tag: String, tables: P.Project.Tables, +level: L.Level, +gfx: G.Gfx, p: S.Player,
  mem: Array<U32>) -> IO(Array<U32>):
  print(tag, line(D.Draw.each(~Hash, ~hash.px, U32.to_nat(53760), 0n,
    Hash{R.Render.frame(tables, level, gfx, p, mem), 2166136261})))

def frames(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  +tables = P.Project.tables(level)
  do IO<Unit>:
    m1 : Array<U32> <- frame("start", tables, level, gfx, S.Player.start(level), mem)
    IO.print("end")

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  frames(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    world : Array<U32> & G.Gfx & L.Level <- IO.pass(Array<U32> & G.Gfx & L.Level, G.Gfx.load(W.Wad.dir(bytes)))
    start(world)

#|start hash 1193745378 pixels 1 1 0 0
#|end
