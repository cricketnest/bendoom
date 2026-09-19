# Freedoom's song as tools/render.bend renders it, over its first 72000
# frames: the idle buffer, the song's two tempo changes at tick 0, which
# rescale every track's first callback, its first note at frame 4536 and
# its first voice steal, a note on channel 9 with all nine voices busy,
# whose callback runs after frame 67613. It prints the frame count, an
# FNV-1a hash of the frames (each a 32-bit word, left in the low half),
# and frames on either side of the first note and of the steal. The
# expected lines are Chocolate Doom's, read in nushell from a real-time
# capture (tools/listen.nu --keep) as the same words:
#
#   let c = open --raw music.raw | bytes at 0..<(72000 * 4) | chunks 4 | each { into int --endian little }
#   $c | reduce --fold 2166136261 {|x, h| (($h | bits xor $x) * 16777619) mod 4294967296 }
#   $c | get 67613 | [($in | bits and 65535) ($in | bits shr 16)] | each { if $in >= 32768 { $in - 65536 } else { $in } }
import Base
import ../src/opl.bend as O
import ../src/song.bend as S

def Test.signed(+x: U32) -> String:
  Bool.pick(String, U32.is_ge(x, 32768), "-" ++ U32.show((65536 - x : U32)), U32.show(x))

def Test.frame(+frames: List<&2, U32>, +i: U32) -> String:
  +lr = Maybe.default(&2, U32, List.get(&2, U32, frames, U32.to_nat(i)), 0)
  U32.show(i) ++ " " ++ Test.signed((lr .&. 65535 : U32)) ++ " " ++ Test.signed((lr >> 16n : U32))

def Test.print(+lumps: S.Song.Lumps) -> IO(Unit):
  +song = S.Song.render(72000, lumps)
  +frames = List.reverse(&2, U32, S.Song.out(song))
  do IO<Unit>:
    IO.print("frames " ++ U32.show(S.Song.made(song)))
    IO.print("hash " ++ U32.show(O.Opl.hash(frames)))
    IO.print(Test.frame(frames, 4535))
    IO.print(Test.frame(frames, 4536))
    IO.print(Test.frame(frames, 67613))
    IO.print(Test.frame(frames, 67614))
    IO.print(Test.frame(frames, 67700))
    IO.print(Test.frame(frames, 70000))
    IO.print(Test.frame(frames, 71999))

def main() -> IO(Unit):
  do IO<Unit>:
    lumps : S.Song.Lumps <- S.Song.load()
    Test.print(lumps)

#|frames 72000
#|hash 1145462143
#|4535 0 0
#|4536 29 0
#|67613 -248 -314
#|67614 -324 -159
#|67700 1928 1946
#|70000 649 662
#|71999 1518 1335
