# Freedoom's song as Chocolate Doom plays it, from the WAD named by
# BENDOOM_IWAD: the chip's idle first buffer, then the song's first pass,
# or its first BENDOOM_FRAMES frames if set. It prints eight hex digits a
# frame, the bytes in the capture's order (left then right, 16-bit
# little-endian), as one line. tools/listen.nu compares it with a capture.
#
#   bend tools/render.bend -o render
import Base
import ../src/song.bend as S

def Render.digit(+d: U32) -> Char:
  Char.from_u32(Bool.pick(U32, U32.is_lt(d, 10), (48 + d : U32), (87 + d : U32)))

def Render.byte(+b: U32, rest: List<&2, Char>) -> List<&2, Char>:
  Render.digit(((b >> 4n) .&. 15 : U32)) <> Render.digit((b .&. 15 : U32)) <> rest

def Render.hex(+lr: U32) -> String:
  String.from_list(Render.byte(lr, Render.byte((lr >> 8n : U32), Render.byte((lr >> 16n : U32),
    Render.byte((lr >> 24n : U32), [])))))

def Render.print(frames: List<&2, U32>) -> IO(Unit):
  match frames:
    case []:
      IO.print("")
    case +lr <> rest:
      do IO<Unit>:
        IO.write(Render.hex(lr))
        Render.print(rest)

def Render.span(r: Result<&1, &1, U32 & String, String>) -> U32:
  match r:
    case Done{s}:
      Maybe.default(&2, U32, U32.read(s), 4294967295)
    case Fail{e}:
      4294967295

def main() -> IO(Unit):
  do IO<Unit>:
    lumps : S.Song.Lumps <- S.Song.load()
    span : Result<&1, &1, U32 & String, String> <- IO.get_env("BENDOOM_FRAMES")
    Render.print(List.reverse(&2, U32, S.Song.out(S.Song.render(Render.span(span), lumps))))
