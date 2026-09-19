# The song as the game hears it: the render in the directory named by
# BENDOOM_MUSIC, streamed to the sound device a frame of the loop at a
# time. first.raw plays once and second.raw for as long as the game
# runs, both raw 16-bit little-endian stereo at 44100 Hz, left then
# right. The open file is the song's place, and nothing but the queue's
# top-up is ever held.
import Base
import ./bytes.bend as B

# A pass being read: the open file and the path of second.raw, which
# opens again at every pass's end.
type Stream.Tape is Type:
  Tape{file: File, path: String}

# The music being played: the device, the pass feeding it, and the
# game frames whose top-up found the device's queue empty, which the
# window bench reports.
type Stream is Type:
  Stream{audio: Audio, tape: Stream.Tape, dry: U32}

# A 16-bit sample as the device takes it: its sign bit flipped is its
# value over 32768, offset by a half.
def Stream.sample(+x: U32) -> F32:
  +half = U32.to_f32(32768)
  ((U32.to_f32((x .^. 32768 : U32)) - half : F32) / half : F32)

# The bytes of a read as the samples Audio.write takes, left then right.
def Stream.samples(bytes: List<&2, U32>) -> List<&2, F32>:
  match bytes:
    case lo <> hi <> rest:
      Stream.sample(B.Bytes.le16(lo, hi)) <> Stream.samples(rest)
    case _:
      []

# The file to read next: a read cut short is the pass's end, where the
# open one closes and second.raw opens again, since Base cannot seek.
def Stream.turned(short: Bool, +path: String, file: File) -> IO(File):
  match short:
    case True{}:
      do IO<File>:
        File.close(file)
        next : File <- IO.try(File, File.open(path, "r"))
        return next
    case False{}:
      IO.pure(File, file)

def Stream.counted(+want: U32, +path: String, file: File, +bytes: List<&2, U32>) ->
  IO(Stream.Tape & List<&2, U32>):
  +short = U32.is_lt(U32.from_nat(List.length(&2, U32, bytes)), (want * 4 : U32))
  IO.bind(File, Stream.Tape & List<&2, U32>, Stream.turned(short, path, file),
    next => IO.pure(Stream.Tape & List<&2, U32>, (Tape{next, path}, bytes)))

# A failed read reads as a read of no bytes, which ends the pass.
def Stream.got(+want: U32, path: String, p: File & Result<&1, &1, U32 & String, List<&2, U32>>) ->
  IO(Stream.Tape & List<&2, U32>):
  (file, got) = p
  Stream.counted(want, path, file, Result.default(&1, &1, U32 & String, List<&2, U32>, got, []))

# The bytes of the song's next frames, at most the rest of the open pass,
# and the tape after them.
def Stream.pull(+want: U32, tape: Stream.Tape) -> IO(Stream.Tape & List<&2, U32>):
  Tape{file, path} = tape
  IO.bind(File & Result<&1, &1, U32 & String, List<&2, U32>>, Stream.Tape & List<&2, U32>,
    File.read_bytes(file, (want * 4 : U32)), p => Stream.got(want, path, p))

# The frames the device holds between top-ups, of the ring's 4096: 69.7
# ms at 44100 Hz, so a game frame longer than that lets the ring run
# dry.
def Stream.top() -> U32:
  3072

def Stream.wrote(tape: Stream.Tape, dry: U32, p: Audio & U32) -> IO(Stream):
  (audio, queued) = p
  IO.pure(Stream, Stream{audio, tape, dry})

def Stream.filled(audio: Audio, dry: U32, p: Stream.Tape & List<&2, U32>) -> IO(Stream):
  (tape, frames) = p
  IO.bind(Audio & U32, Stream, Audio.write(audio, Stream.samples(frames)), q => Stream.wrote(tape, dry, q))

def Stream.topped(tape: Stream.Tape, +dry: U32, p: Audio & U32) -> IO(Stream):
  (audio, +queued) = p
  IO.bind(Stream.Tape & List<&2, U32>, Stream, Stream.pull((Stream.top() - queued : U32), tape),
    r => Stream.filled(audio, (dry + Bool.to_u32(U32.is_zero(queued)) : U32), r))

# A frame of music: a write of no samples reads the queue, and the
# frames that bring it back to the top follow it. The song's place
# therefore follows the device's clock, not the tic clock.
def Stream.frame(m: Stream) -> IO(Stream):
  Stream{audio, tape, dry} = m
  IO.bind(Audio & U32, Stream, Audio.write(audio, []), p => Stream.topped(tape, dry, p))

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
      Some{Tape{f, dir ++ "/second.raw"}}

def Stream.probed(+dir: String, second: Result<&1, &1, U32 & String, File>) -> IO(Maybe<Stream.Tape>):
  match second:
    case Fail{e}:
      IO.pure(Maybe<Stream.Tape>, None{})
    case Done{f}:
      do IO<Maybe<Stream.Tape>>:
        File.close(f)
        first : Result<&1, &1, U32 & String, File> <- File.open(dir ++ "/first.raw", "r")
        return Stream.rolled(dir, first)

# The first pass of the render in the given directory, open at its
# first frame, if the second opens too.
def Stream.tape(+dir: String) -> IO(Maybe<Stream.Tape>):
  IO.bind(Result<&1, &1, U32 & String, File>, Maybe<Stream.Tape>, File.open(dir ++ "/second.raw", "r"),
    s => Stream.probed(dir, s))

def Stream.first(audio: Audio, tape: Maybe<Stream.Tape>) -> IO(Maybe<Stream>):
  match tape:
    case None{}:
      do IO<Maybe<Stream>>:
        Audio.close(audio)
        Stream.silent("BENDOOM_MUSIC holds no first.raw and second.raw")
    case Some{t}:
      IO.pure(Maybe<Stream>, Some{Stream{audio, t, 0}})

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

# The device and the file closed; the frames that found the queue
# empty, if the music played.
def Stream.stop(m: Maybe<Stream>) -> IO(Maybe<U32>):
  match m:
    case None{}:
      IO.pure(Maybe<U32>, None{})
    case Some{Stream{audio, Tape{file, path}, dry}}:
      do IO<Maybe<U32>>:
        Audio.close(audio)
        File.close(file)
        return Some{dry}
