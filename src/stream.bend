# The song as the game hears it: the render in the directory named by
# BENDOOM_MUSIC, streamed to the sound device a frame of the loop at a
# time. first.raw plays once and second.raw for as long as the game
# runs, both raw 16-bit little-endian stereo at 44100 Hz, left then
# right. Nothing but the queue's top-up is ever held.
import Base

# The song's position: the pass the open file is, and the frames read
# from it.
type Stream.At is Data:
  At{second: Bool, at: U32}

# A pass being read: the open file, the path of second.raw, which opens
# again at every pass's end, and the position.
type Stream.Tape is Type:
  Tape{file: File, path: String, at: Stream.At}

# The music being played: the device and the pass feeding it.
type Stream is Type:
  Music{audio: Audio, tape: Stream.Tape}

def Stream.one(p: Stream.At) -> Stream.At:
  At{second, +at} = p
  At{second, (at + 1 : U32)}

# The position n frames on, counted one frame at a time: the law that
# two reads land where one of their sum does then follows the count's
# shape, where a word's sum would leave the checker stuck.
def Stream.took(n: Nat, p: Stream.At) -> Stream.At:
  match n:
    case 0n:
      p
    case 1n+m:
      Stream.took(m, Stream.one(p))

# The position after a read of n frames. A read cut short is the pass's
# end, and the second pass's first frame follows it, as vanilla's chip
# runs on into its repeat.
def Stream.after(short: Bool, n: Nat, p: Stream.At) -> Stream.At:
  match short:
    case True{}:
      At{True{}, 0}
    case False{}:
      Stream.took(n, p)

# A 16-bit sample as the device takes it: its sign bit flipped is its
# value over 32768, offset by a half.
def Stream.sample(+x: U32) -> F32:
  +half = U32.to_f32(32768)
  ((U32.to_f32((x .^. 32768 : U32)) - half : F32) / half : F32)

# The frames interleaved, left then right, as Audio.write takes them.
def Stream.samples(frames: List<&2, U32>) -> List<&2, F32>:
  match frames:
    case []:
      []
    case +f <> rest:
      Stream.sample((f .&. 65535 : U32)) <> Stream.sample((f >> 16n : U32)) <> Stream.samples(rest)

# The bytes of a read as frames, left in the low half.
def Stream.frames(bytes: List<&2, U32>) -> List<&2, U32>:
  match bytes:
    case l0 <> l1 <> r0 <> r1 <> rest:
      (l0 .|. (l1 << 8n) .|. (r0 << 16n) .|. (r1 << 24n) : U32) <> Stream.frames(rest)
    case _:
      []

# The file to read next: at a pass's end the open one closes and
# second.raw opens again, since Base cannot seek.
def Stream.turned(short: Bool, +path: String, file: File) -> IO(File):
  match short:
    case True{}:
      do IO<File>:
        File.close(file)
        next : File <- IO.try(File, File.open(path, "r"))
        return next
    case False{}:
      IO.pure(File, file)

def Stream.moved(+short: Bool, n: Nat, +path: String, at: Stream.At, frames: List<&2, U32>, file: File) ->
  IO(Stream.Tape & List<&2, U32>):
  IO.bind(File, Stream.Tape & List<&2, U32>, Stream.turned(short, path, file),
    next => IO.pure(Stream.Tape & List<&2, U32>, (Tape{next, path, Stream.after(short, n, at)}, frames)))

def Stream.counted(+want: Nat, path: String, at: Stream.At, file: File, +frames: List<&2, U32>) ->
  IO(Stream.Tape & List<&2, U32>):
  +n = List.length(&2, U32, frames)
  Stream.moved(Nat.is_lt(n, want), n, path, at, frames, file)

# A failed read reads as a read of no frames, which ends the pass.
def Stream.got(+want: Nat, path: String, at: Stream.At,
  p: File & Result<&1, &1, U32 & String, List<&2, U32>>) -> IO(Stream.Tape & List<&2, U32>):
  (file, got) = p
  Stream.counted(want, path, at, file,
    Stream.frames(Result.default(&1, &1, U32 & String, List<&2, U32>, got, [])))

# The song's next frames and the tape after them, at most the rest of
# the open pass.
def Stream.pull(+want: U32, tape: Stream.Tape) -> IO(Stream.Tape & List<&2, U32>):
  Tape{file, path, at} = tape
  IO.bind(File & Result<&1, &1, U32 & String, List<&2, U32>>, Stream.Tape & List<&2, U32>,
    File.read_bytes(file, (want * 4 : U32)), p => Stream.got(U32.to_nat(want), path, at, p))

# The frames the device holds between top-ups, of the ring's 4096: 70 ms
# at 44100 Hz, which a frame rate above 14 a second never runs dry.
def Stream.top() -> U32:
  3072

def Stream.wrote(tape: Stream.Tape, p: Audio & U32) -> IO(Stream):
  (audio, queued) = p
  IO.pure(Stream, Music{audio, tape})

def Stream.filled(audio: Audio, p: Stream.Tape & List<&2, U32>) -> IO(Stream):
  (tape, frames) = p
  IO.bind(Audio & U32, Stream, Audio.write(audio, Stream.samples(frames)), q => Stream.wrote(tape, q))

def Stream.topped(tape: Stream.Tape, p: Audio & U32) -> IO(Stream):
  (audio, +queued) = p
  IO.bind(Stream.Tape & List<&2, U32>, Stream, Stream.pull((Stream.top() - queued : U32), tape),
    r => Stream.filled(audio, r))

# A frame of music: a write of no samples reads the queue, and the
# frames that bring it back to the top follow it. The song's place
# therefore follows the device's clock, not the tic clock.
def Stream.frame(m: Stream) -> IO(Stream):
  Music{audio, tape} = m
  IO.bind(Audio & U32, Stream, Audio.write(audio, []), p => Stream.topped(tape, p))

def Stream.play(m: Maybe<Stream>) -> IO(Maybe<Stream>):
  match m:
    case None{}:
      IO.pure(Maybe<Stream>, None{})
    case Some{s}:
      IO.bind(Stream, Maybe<Stream>, Stream.frame(s), kept => IO.pure(Maybe<Stream>, Some{kept}))

# A game with no music says so once and plays on in silence.
def Stream.silent(why: String) -> IO(Maybe<Stream>):
  do IO<Maybe<Stream>>:
    IO.print_err("bendoom: " ++ why ++ "; playing silent")
    return None{}

def Stream.rolled(+dir: String, file: Result<&1, &1, U32 & String, File>) -> Maybe<Stream.Tape>:
  match file:
    case Fail{e}:
      None{}
    case Done{f}:
      Some{Tape{f, dir ++ "/second.raw", At{False{}, 0}}}

# The first pass of the render in the given directory, open at its
# first frame.
def Stream.tape(+dir: String) -> IO(Maybe<Stream.Tape>):
  IO.bind(Result<&1, &1, U32 & String, File>, Maybe<Stream.Tape>, File.open(dir ++ "/first.raw", "r"),
    f => IO.pure(Maybe<Stream.Tape>, Stream.rolled(dir, f)))

def Stream.first(audio: Audio, tape: Maybe<Stream.Tape>) -> IO(Maybe<Stream>):
  match tape:
    case None{}:
      do IO<Maybe<Stream>>:
        Audio.close(audio)
        Stream.silent("BENDOOM_MUSIC holds no first.raw")
    case Some{t}:
      IO.pure(Maybe<Stream>, Some{Music{audio, t}})

def Stream.device(dir: String, audio: Result<&1, &1, U32 & String, Audio>) -> IO(Maybe<Stream>):
  match audio:
    case Fail{e}:
      Stream.silent("no sound device")
    case Done{a}:
      IO.bind(Maybe<Stream.Tape>, Maybe<Stream>, Stream.tape(dir), t => Stream.first(a, t))

def Stream.start(dir: Result<&1, &1, U32 & String, String>) -> IO(Maybe<Stream>):
  match dir:
    case Fail{e}:
      Stream.silent("BENDOOM_MUSIC names no render")
    case Done{d}:
      IO.bind(Result<&1, &1, U32 & String, Audio>, Maybe<Stream>, Audio.open(44100),
        a => Stream.device(d, a))

# The device at 44100 Hz and the first pass open, or silence.
def Stream.open() -> IO(Maybe<Stream>):
  IO.bind(Result<&1, &1, U32 & String, String>, Maybe<Stream>, IO.get_env("BENDOOM_MUSIC"), Stream.start)

def Stream.stop(m: Maybe<Stream>) -> IO(Unit):
  match m:
    case None{}:
      IO.pure(Unit, Unit{})
    case Some{Music{audio, Tape{file, path, at}}}:
      do IO<Unit>:
        Audio.close(audio)
        File.close(file)
