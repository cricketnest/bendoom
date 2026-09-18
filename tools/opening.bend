# Freedoom's song's opening as Chocolate Doom plays it, from the WAD
# named by BENDOOM_IWAD: the chip's idle first buffer, then the song up
# to the callback after its first, one line of eight hex digits a frame,
# its bytes in the capture's order (left then right, 16-bit
# little-endian). tools/listen.nu compares it with a capture.
#
#   bend tools/opening.bend -o opening
import Base
import ../src/bytes.bend as B
import ../src/music.bend as M

def Opening.digit(+d: U32) -> Char:
  Char.from_u32(Bool.pick(U32, U32.is_lt(d, 10), (48 + d : U32), (87 + d : U32)))

def Opening.byte(+b: U32, rest: List<&2, Char>) -> List<&2, Char>:
  Opening.digit(((b >> 4n) .&. 15 : U32)) <> Opening.digit((b .&. 15 : U32)) <> rest

def Opening.line(+lr: U32) -> String:
  String.from_list(Opening.byte(lr, Opening.byte((lr >> 8n : U32), Opening.byte((lr >> 16n : U32),
    Opening.byte((lr >> 24n : U32), [])))))

def Opening.print(frames: List<&2, U32>) -> IO(Unit):
  match frames:
    case []:
      IO.pure(Unit, Unit{})
    case +lr <> rest:
      do IO<Unit>:
        IO.print(Opening.line(lr))
        Opening.print(rest)

def Opening.lumps(p: Array<U32> & M.Music.Lumps) -> IO(Unit):
  (a, lumps) = p
  Opening.print(List.reverse(&2, U32, M.Music.opening(lumps)))

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    Opening.lumps(M.Music.lumps(bytes))
