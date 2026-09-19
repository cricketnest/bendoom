# E1M1's song from the WAD, as the render reads and plays it. First the
# song as the reader hands it to the player: its length in ticks (its
# longest track's) and its events by kind, as tools/wad.nu counts them
# from the lump:
#
#   nu -c 'source tools/wad.nu; open --raw $env.BENDOOM_IWAD | song-events | song-counts'
#
# Then Freedoom's song as music.bend renders it with BENDOOM_IDLE,
# over its first 72000 frames: the idle buffer, the song's two tempo
# changes at tick 0, which rescale every track's first callback, its
# first note at frame 4536 and its first voice steal, a note on channel
# 9 with all nine voices busy. Frame 67843 is the first the steal
# changes. It prints an FNV-1a hash of the frames (each a 32-bit word,
# left in the low half), and frames on either side of the first note and
# of the steal. The expected lines are Chocolate Doom's, read in nushell
# from a real-time capture (tools/listen.nu --keep) as the same words:
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
import ../src/midi.bend as M
import ../src/song.bend as S

# Events by kind: the channel events by their status's high nibble from
# 0x80, then tempo, end and any other.
def Test.kinds() -> List<&2, String>:
  ["off", "on", "touch", "controller", "program", "pressure", "bend", "tempo", "end", "other"]

def Test.slot(e: M.Midi.Event) -> U32:
  match e:
    case M.Chan{kind, ch, p1, p2}:
      ((kind >> 4n) - 8 : U32)
    case M.Tempo{us}:
      7
    case M.End{}:
      8
    case M.Other{}:
      9

def Test.bump(+counts: List<&2, U32>, +i: U32) -> List<&2, U32>:
  List.set(&2, U32, counts, U32.to_nat(i),
    (Maybe.default(&2, U32, List.get(&2, U32, counts, U32.to_nat(i)), 0) + 1 : U32))

# A track's length in ticks and its events by kind.
type Test.Tally is Data:
  Tally{ticks: U32, counts: List<&2, U32>}

# The events from g on, the first d ticks after the track's last.
def Test.walk(n: Nat, g: M.Midi.Got, +d: U32, +ticks: U32, counts: List<&2, U32>) -> Test.Tally:
  match n g:
    case _ M.Got{M.End{}, rest}:
      Tally{(ticks + d : U32), Test.bump(counts, 8)}
    case 0n M.Got{e, rest}:
      Tally{ticks, counts}
    case 1n+m M.Got{+e, +rest}:
      Test.walk(m, M.Midi.next(rest), M.Midi.delta(rest), (ticks + d : U32), Test.bump(counts, Test.slot(e)))

def Test.add(xs: List<&2, U32>, ys: List<&2, U32>) -> List<&2, U32>:
  match xs ys:
    case [] _:
      ys
    case x <> xr Nil{}:
      x <> xr
    case x <> xr y <> yr:
      (x + y : U32) <> Test.add(xr, yr)

def Test.merge(a: Test.Tally, b: Test.Tally) -> Test.Tally:
  Tally{+ta, ca} = a
  Tally{+tb, cb} = b
  Tally{U32.max(ta, tb), Test.add(ca, cb)}

def Test.tracks(ts: List<&2, M.Midi.Track>) -> Test.Tally:
  match ts:
    case []:
      Tally{0, List.replicate(U32, 10n, 0)}
    case +t <> rest:
      Test.merge(Test.walk(U32.to_nat(M.Midi.most()), M.Midi.next(t), M.Midi.delta(t), 0, List.replicate(U32, 10n, 0)),
        Test.tracks(rest))

def Test.named(names: List<&2, String>, counts: List<&2, U32>) -> List<&2, String>:
  match names counts:
    case [] _:
      []
    case n <> nr Nil{}:
      []
    case n <> nr c <> cr:
      (n ++ " " ++ U32.show(c)) <> Test.named(nr, cr)

def Test.sum(xs: List<&2, U32>, +acc: U32) -> U32:
  match xs:
    case []:
      acc
    case x <> rest:
      Test.sum(rest, (acc + x : U32))

def Test.counts(t: Test.Tally) -> String:
  Tally{ticks, +counts} = t
  "song ticks " ++ U32.show(ticks) ++ " events " ++ U32.show(Test.sum(counts, 0)) ++ " "
    ++ String.join(Test.named(Test.kinds(), counts), " ")

def Test.song(f: M.Midi.File) -> String:
  M.File{division, tracks} = f
  Test.counts(Test.tracks(tracks))

def Test.signed(+x: U32) -> String:
  Bool.pick(String, U32.is_ge(x, 32768), "-" ++ U32.show((65536 - x : U32)), U32.show(x))

def Test.frame(+frames: List<&2, U32>, +i: U32) -> String:
  +lr = Maybe.default(&2, U32, List.get(&2, U32, frames, U32.to_nat(i)), 0)
  U32.show(i) ++ " " ++ Test.signed((lr .&. 65535 : U32)) ++ " " ++ Test.signed((lr >> 16n : U32))

# The song's first 72000 frames, in order: the turn that makes them may
# pass 72000, and what it passes by is dropped.
def Test.first(+m: S.Song) -> List<&2, U32>:
  List.reverse(&2, U32, List.drop(&2, U32, S.Song.out(m), U32.to_nat((S.Song.made(m) - 72000 : U32))))

def Test.frames(t: S.Song.Turn) -> List<&2, U32>:
  match t:
    case S.More{+m}:
      Test.first(m)
    case S.Ended{+m}:
      Test.first(m)
    case S.Stuck{}:
      []

def Test.print(+env: S.Song.Env) -> IO(Unit):
  +frames = Test.frames(S.Song.turn(72000, env, S.Song.start(True{}, env)))
  do IO<Unit>:
    IO.print(Test.song(S.Song.file(env)))
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
    env : S.Song.Env <- S.Song.load()
    Test.print(env)

#|song ticks 26114 events 12478 off 5483 on 5483 touch 0 controller 439 program 80 pressure 0 bend 955 tempo 3 end 18 other 17
#|hash 1145462143
#|4535 0 0
#|4536 29 0
#|67842 1862 1895
#|67843 1875 1881
#|70000 649 662
#|71999 1518 1335
#|rescale 994 87
