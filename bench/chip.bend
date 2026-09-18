# A measurement, not a test: 100 s of the OPL chip's output, 4,410,000
# frames, one note held. Every operator runs every sample whether it
# sounds or not, so this is the chip's cost at any point of a song.
# Build natively and time it against 100 s:
#
#   bend bench/chip.bend -o chip
#   time ./chip --threads 1
import Base
import ../src/opl.bend as O

def Bench.hash(frames: List<&2, U32>, +h: U32) -> U32:
  match frames:
    case []:
      h
    case lr <> rest:
      Bench.hash(rest, ((h .^. lr) * 16777619 : U32))

def Bench.out(f: O.Opl.Frames) -> String:
  U32.show(Bench.hash(O.Opl.Frames.out(f), 2166136261))

# Channel 0's carrier at full level and fastest attack, keyed at f-num
# 0x244, block 4.
def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Bench.out(O.Opl.frames(U32.to_nat(4410000), O.Opl.roms(),
      O.Frames{O.Opl.queue([17152, 25584, 41028, 45106], O.Opl.reset()), []})))
