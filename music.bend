# E1M1's song from the WAD named by BENDOOM_IWAD, as Chocolate Doom
# plays it looping, written to two files in the current directory: the
# first pass to first.raw, from the song's start to the sample where its
# restart runs, and the second pass to second.raw, up to the next. Both
# are raw 16-bit little-endian stereo at 44100 Hz, left then right, and
# each cut is written as it is made. With BENDOOM_IDLE set, first.raw
# starts with Chocolate Doom's idle first buffer, as a capture does;
# tools/listen.nu sets it to compare the passes with one.
#
#   bend music.bend -o music
import Base
import ./src/bytes.bend as B
import ./src/song.bend as S

# Frames, latest first, as bytes in order.
def Music.bytes(frames: List<&2, U32>, acc: List<&2, U32>) -> List<&2, U32>:
  match frames:
    case []:
      acc
    case +lr <> rest:
      Music.bytes(rest, lr <> (lr >> 8n : U32) <> (lr >> 16n : U32) <> (lr >> 24n : U32) <> acc)

# The pass from a cut's frames on, each next cut written as it is made,
# until the restart is due.
def Music.pass.go(n: Nat, frames: List<&2, U32>, +env: S.Song.Env, file: File, m: S.Song) -> IO(S.Song):
  match n frames:
    case _ Nil{}:
      do IO<S.Song>:
        File.close(file)
        return m
    case 0n _:
      IO.die(S.Song, 1, "music.bend: the pass outran its fuel")
    case 1n+f lr <> rest:
      +next = S.Song.next(env, m)
      do IO<S.Song>:
        kept : File <- B.Bytes.put(file, Music.bytes(lr <> rest, []))
        Music.pass.go(f, S.Song.out(next), env, kept, S.Song.clear(next))

def Music.pass(path: String, +env: S.Song.Env, +m: S.Song) -> IO(S.Song):
  +next = S.Song.next(env, m)
  do IO<S.Song>:
    file : File <- IO.try(File, File.open(path, "w"))
    Music.pass.go(U32.to_nat(4294967295), S.Song.out(next), env, file, S.Song.clear(next))

def Music.render(+env: S.Song.Env, +idle: Bool) -> IO(Unit):
  do IO<Unit>:
    first : S.Song <- Music.pass("first.raw", env, S.Song.start(idle, env))
    second : S.Song <- Music.pass("second.raw", env, S.Song.restart(env, first))
    IO.pure(Unit, Unit{})

def main() -> IO(Unit):
  do IO<Unit>:
    lumps : S.Song.Lumps <- S.Song.load()
    idle : Result<&1, &1, U32 & String, String> <- IO.get_env("BENDOOM_IDLE")
    Music.render(S.Song.env(lumps), Result.is_done(&1, &1, U32 & String, String, idle))
