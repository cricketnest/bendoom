# Freedoom's song's opening, as tools/opening.bend renders it: the frame
# count, an FNV-1a hash of the frames (each a 32-bit word, left in the
# low half), and the frames on either side of the first note, sampled
# through the opening, and the last. The expected lines are Chocolate
# Doom's, read in nushell from a real-time capture (tools/listen.nu
# --keep) as the same words:
#
#   let c = open --raw music.raw | bytes at 0..<(9389 * 4) | chunks 4 | each { into int --endian little }
#   $c | reduce --fold 2166136261 {|x, h| (($h | bits xor $x) * 16777619) mod 4294967296 }
import Base
import ../src/bytes.bend as B
import ../src/music.bend as M

def Test.hash(frames: List<&2, U32>, +h: U32) -> U32:
  match frames:
    case []:
      h
    case lr <> rest:
      Test.hash(rest, ((h .^. lr) * 16777619 : U32))

def Test.signed(+x: U32) -> String:
  Bool.pick(String, U32.is_ge(x, 32768), "-" ++ U32.show((65536 - x : U32)), U32.show(x))

def Test.frame(+frames: List<&2, U32>, +i: U32) -> String:
  +lr = Maybe.default(&2, U32, List.get(&2, U32, frames, U32.to_nat(i)), 0)
  U32.show(i) ++ " " ++ Test.signed((lr .&. 65535 : U32)) ++ " " ++ Test.signed((lr >> 16n : U32))

def Test.lumps(p: Array<U32> & M.Music.Lumps) -> IO(Unit):
  (a, lumps) = p
  +frames = List.reverse(&2, U32, M.Music.opening(lumps))
  do IO<Unit>:
    IO.print("frames " ++ Nat.show(List.length(&2, U32, frames)))
    IO.print("hash " ++ U32.show(Test.hash(frames, 2166136261)))
    IO.print(Test.frame(frames, 4535))
    IO.print(Test.frame(frames, 4536))
    IO.print(Test.frame(frames, 4537))
    IO.print(Test.frame(frames, 6000))
    IO.print(Test.frame(frames, 8000))
    IO.print(Test.frame(frames, 9388))

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    Test.lumps(M.Music.lumps(bytes))

#|frames 9389
#|hash 2798912565
#|4535 0 0
#|4536 29 0
#|4537 83 37
#|6000 357 11
#|8000 833 1492
#|9388 -12 -132
