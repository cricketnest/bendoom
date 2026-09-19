# The render named by BENDOOM_MUSIC streamed as the game streams it, in
# pieces of varying frame counts, printing the pass, the frames read
# from it, and the frames themselves where the song begins, at each end
# of a pass and at each start after one. Freedoom's passes are 5,759,883
# and 5,759,888 frames, so the pull after the last frame of a pass reads
# none, which is the end the second pass opens again on. The expected
# frames are read from the render's files in nushell:
#
#   def frames [file: path, off: int, n: int] {
#     open --raw $file | bytes at $off..<($off + $n * 4) | chunks 4 | each {|c|
#       let l = ($c | bytes at 0..<2 | into int --endian little)
#       let r = ($c | bytes at 2..<4 | into int --endian little)
#       [(if $l >= 32768 { $l - 65536 } else { $l }) (if $r >= 32768 { $r - 65536 } else { $r })]
#     } | flatten | str join " "
#   }
#   frames $"($env.BENDOOM_MUSIC)/first.raw" 0 3
#   frames $"($env.BENDOOM_MUSIC)/first.raw" (23039532 - 12) 3
#   frames $"($env.BENDOOM_MUSIC)/second.raw" 0 3
#   frames $"($env.BENDOOM_MUSIC)/second.raw" (23039552 - 12) 3
import Base
import ../src/stream.bend as A

def int(+x: U32) -> String:
  Bool.pick(String, U32.is_lt(x, 32768), U32.show(x), "-" ++ U32.show((65536 - x : U32)))

def frames(fs: List<&2, U32>) -> String:
  match fs:
    case []:
      ""
    case +f <> rest:
      " " ++ int((f .&. 65535 : U32)) ++ " " ++ int((f >> 16n : U32)) ++ frames(rest)

def line(tag: String, second: Bool, +at: U32, fs: List<&2, U32>) -> String:
  tag ++ " " ++ Bool.pick(String, second, "second", "first") ++ " " ++ U32.show(at) ++ frames(fs)

def told(tag: String, p: A.Stream.Tape & List<&2, U32>) -> IO(A.Stream.Tape):
  (tape, fs) = p
  A.Tape{file, path, at} = tape
  A.At{+second, +now} = at
  do IO<A.Stream.Tape>:
    IO.print(line(tag, second, now, fs))
    return A.Tape{file, path, A.At{second, now}}

# A pull of so many frames, its place and its frames printed.
def show(tag: String, k: U32, tape: A.Stream.Tape) -> IO(A.Stream.Tape):
  IO.bind(A.Stream.Tape & List<&2, U32>, A.Stream.Tape, A.Stream.pull(k, tape), p => told(tag, p))

def dropped(p: A.Stream.Tape & List<&2, U32>, rest: A.Stream.Tape -> IO(A.Stream.Tape)) ->
  IO(A.Stream.Tape):
  (tape, fs) = p
  rest(tape)

# The piece counts a span takes in turn; once they run out it goes in
# the 3072 frames a game frame asks for.
def sizes() -> List<&2, U32>:
  [1, 7, 100, 2048, 33, 999, 3072, 5]

def next(ss: List<&2, U32>) -> U32 & List<&2, U32>:
  match ss:
    case []:
      (3072, [])
    case s <> rest:
      (s, rest)

# One piece of a span, cut to what is left of it, dropped; then what is
# left, the piece counts after it and the tape.
def piece(+n: Nat, q: U32 & List<&2, U32>, tape: A.Stream.Tape,
  rest: Bool -> Nat -> List<&2, U32> -> A.Stream.Tape -> IO(A.Stream.Tape)) -> IO(A.Stream.Tape):
  (s, ss) = q
  +k = U32.from_nat(Nat.min(n, U32.to_nat(s)))
  +left = Nat.sub(n, U32.to_nat(k))
  IO.bind(A.Stream.Tape & List<&2, U32>, A.Stream.Tape, A.Stream.pull(k, tape),
    p => dropped(p, t => rest(Nat.is_eq(left, 0n), left, ss, t)))

# The next n frames read and thrown away.
def span(fuel: Nat, done: Bool, n: Nat, ss: List<&2, U32>, tape: A.Stream.Tape) -> IO(A.Stream.Tape):
  match fuel done:
    case _ True{}:
      IO.pure(A.Stream.Tape, tape)
    case 0n _:
      IO.die(A.Stream.Tape, 1, "tests/stream.bend: the span outran its fuel")
    case 1n+f False{}:
      piece(n, next(ss), tape, d => m => more => t => span(f, d, m, more, t))

def opened(m: Maybe<A.Stream.Tape>) -> IO(A.Stream.Tape):
  match m:
    case None{}:
      IO.die(A.Stream.Tape, 1, "tests/stream.bend: BENDOOM_MUSIC names no render")
    case Some{t}:
      IO.pure(A.Stream.Tape, t)

def shut(tape: A.Stream.Tape) -> IO(Unit):
  A.Tape{file, path, at} = tape
  File.close(file)

def main() -> IO(Unit):
  do IO<Unit>:
    dir : String <- IO.try(String, IO.get_env("BENDOOM_MUSIC"))
    first : Maybe<A.Stream.Tape> <- A.Stream.tape(dir)
    t0 : A.Stream.Tape <- opened(first)
    t1 : A.Stream.Tape <- show("start", 3, t0)
    t2 : A.Stream.Tape <- span(U32.to_nat(4294967295), False{}, U32.to_nat(5759877), sizes(), t1)
    t3 : A.Stream.Tape <- show("first end", 3, t2)
    t4 : A.Stream.Tape <- show("boundary", 3, t3)
    t5 : A.Stream.Tape <- show("second start", 3, t4)
    t6 : A.Stream.Tape <- span(U32.to_nat(4294967295), False{}, U32.to_nat(5759882), sizes(), t5)
    t7 : A.Stream.Tape <- show("second end", 3, t6)
    t8 : A.Stream.Tape <- show("wrap", 3, t7)
    t9 : A.Stream.Tape <- show("again", 3, t8)
    shut(t9)

#|start first 3 0 0 0 0 0 0
#|first end first 5759883 268 286 249 264 233 247
#|boundary second 0
#|second start second 3 216 229 204 215 196 204
#|second end second 5759888 167 186 159 179 156 172
#|wrap second 0
#|again second 3 216 229 204 215 196 204
