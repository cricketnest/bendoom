# Freedoom's song as tools/render.bend renders it, over its first
# 72000 frames: the idle buffer, the song's two tempo changes at tick 0,
# which rescale every track's first callback, its first note at frame
# 4536 and its first voice steal, a note on channel 9 with all nine
# voices busy. Frame 67843 is the first the steal changes. It prints the
# frame count, an FNV-1a hash of the frames (each a 32-bit word, left in
# the low half), and frames on either side of the first note and of the
# steal. The expected lines are Chocolate Doom's, read in nushell from a
# real-time capture (tools/listen.nu --keep) as the same words:
#
#   let c = open --raw music.raw | bytes at 0..<(72000 * 4) | chunks 4 | each { into int --endian little }
#   $c | reduce --fold 2166136261 {|x, h| (($h | bits xor $x) * 16777619) mod 4294967296 }
#   $c | get 67843 | [($in | bits and 65535) ($in | bits shr 16)] | each { if $in >= 32768 { $in - 65536 } else { $in } }
#
# Last, OPL_Queue_AdjustCallbacks on callbacks overdue as the tempo
# changes, worked by hand from C's conversions: 993 at now 1000 with the
# factor (float) 500000 / 480000 is 1000 + (int64) (-7 / 1.0416666f) =
# 994, and 90 at now 100 with the factor 0.75 is 100 + (int64) (-10 /
# 0.75f) = 87. Freedoom reaches that path only with the factor 1.
import Base
import ../src/fnv.bend as H
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
    IO.print("hash " ++ U32.show(H.Fnv.words(frames)))
    IO.print(Test.frame(frames, 4535))
    IO.print(Test.frame(frames, 4536))
    IO.print(Test.frame(frames, 67842))
    IO.print(Test.frame(frames, 67843))
    IO.print(Test.frame(frames, 70000))
    IO.print(Test.frame(frames, 71999))
    IO.print("rescale " ++ U32.show(S.Song.rescale(1000, (U32.to_f32(500000) / U32.to_f32(480000) : F32), 993))
      ++ " " ++ U32.show(S.Song.rescale(100, (U32.to_f32(3) / U32.to_f32(4) : F32), 90)))

def main() -> IO(Unit):
  do IO<Unit>:
    lumps : S.Song.Lumps <- S.Song.load()
    Test.print(lumps)

#|frames 72000
#|hash 1145462143
#|4535 0 0
#|4536 29 0
#|67842 1862 1895
#|67843 1875 1881
#|70000 649 662
#|71999 1518 1335
#|rescale 994 87
