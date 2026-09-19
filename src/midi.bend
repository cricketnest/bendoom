# A MIDI file's tracks, read an event at a time as Chocolate Doom's
# midifile.c hands them to the player: each event after its delta, a data
# byte where a status belongs repeating the last status byte, meta events
# included.
import Base

type Midi.Track is Data:
  Track{bytes: List<&2, U32>, status: U32}

# A channel event: kind is the status's high nibble (0x80 note off, 0x90
# note on, 0xB0 controller, 0xC0 program, 0xE0 pitch bend, ...), p2 zero
# for the one-parameter kinds. Of the meta events, set tempo with the
# three bytes i_oplmusic.c takes, and end of track; any other is Other.
type Midi.Event is Data:
  Chan{kind: U32, ch: U32, p1: U32, p2: U32}
  Tempo{us: U32}
  End{}
  Other{}

type Midi.Read is Data:
  Read{val: U32, rest: List<&2, U32>}

type Midi.Got is Data:
  Got{event: Midi.Event, track: Midi.Track}

def Midi.byte(bytes: List<&2, U32>) -> Midi.Read:
  match bytes:
    case []:
      Read{0, []}
    case b <> rest:
      Read{b, rest}

def Midi.vlq.go(bytes: List<&2, U32>, more: Bool, +acc: U32) -> Midi.Read:
  match bytes more:
    case [] _:
      Read{acc, []}
    case b <> rest False{}:
      Read{acc, b <> rest}
    case +b <> rest True{}:
      Midi.vlq.go(rest, U32.is_ge(b, 128), ((acc << 7n) .|. (b .&. 127) : U32))

# A variable-length quantity: seven bits a byte, the top bit set on all
# but the last.
def Midi.vlq(bytes: List<&2, U32>) -> Midi.Read:
  Midi.vlq.go(bytes, True{}, 0)

def Midi.be.go(n: Nat, bytes: List<&2, U32>, +acc: U32) -> U32:
  match n bytes:
    case 0n _:
      acc
    case 1n+m Nil{}:
      acc
    case 1n+m b <> rest:
      Midi.be.go(m, rest, ((acc << 8n) .|. b : U32))

# The big-endian number in the first n bytes.
def Midi.be(n: Nat, bytes: List<&2, U32>) -> U32:
  Midi.be.go(n, bytes, 0)

def Midi.Read.val(r: Midi.Read) -> U32:
  Read{val, rest} = r
  val

# The delta before a track's next event, in ticks.
def Midi.delta(t: Midi.Track) -> U32:
  Track{bytes, status} = t
  Midi.Read.val(Midi.vlq(bytes))

def Midi.meta.event(+kind: U32, +n: U32, +data: List<&2, U32>) -> Midi.Event:
  Bool.pick(Midi.Event, U32.is_eq(kind, 47), End{},
    Bool.pick(Midi.Event, U32.is_eq(kind, 81) && U32.is_eq(n, 3), Tempo{Midi.be(3n, data)}, Other{}))

def Midi.meta.data(+kind: U32, r: Midi.Read) -> Midi.Got:
  Read{+n, +rest} = r
  Got{Midi.meta.event(kind, n, rest), Track{List.drop(&2, U32, rest, U32.to_nat(n)), 255}}

def Midi.meta(r: Midi.Read) -> Midi.Got:
  Read{kind, rest} = r
  Midi.meta.data(kind, Midi.vlq(rest))

def Midi.chan.two(+status: U32, p1: U32, r: Midi.Read) -> Midi.Got:
  Read{p2, rest} = r
  Got{Chan{(status .&. 240 : U32), (status .&. 15 : U32), p1, p2}, Track{rest, status}}

def Midi.chan(two: Bool, +status: U32, r: Midi.Read) -> Midi.Got:
  match two:
    case True{}:
      Read{p1, rest} = r
      Midi.chan.two(status, p1, Midi.byte(rest))
    case False{}:
      Read{p1, rest} = r
      Got{Chan{(status .&. 240 : U32), (status .&. 15 : U32), p1, 0}, Track{rest, status}}

def Midi.event(meta: Bool, +status: U32, bytes: List<&2, U32>) -> Midi.Got:
  match meta:
    case True{}:
      Midi.meta(Midi.byte(bytes))
    case False{}:
      Midi.chan(Bool.not(U32.is_eq((status .&. 224 : U32), 192)), status, Midi.byte(bytes))

def Midi.event.status(fresh: Bool, +b: U32, +last: U32, rest: List<&2, U32>) -> Midi.Got:
  match fresh:
    case True{}:
      Midi.event(U32.is_eq(b, 255), b, rest)
    case False{}:
      Midi.event(U32.is_eq(last, 255), last, b <> rest)

# A status byte, or the last one again before a data byte.
def Midi.status(+last: U32, r: Midi.Read) -> Midi.Got:
  Read{+b, +rest} = r
  Midi.event.status(U32.is_ge(b, 128), b, last, rest)

def Midi.Read.rest(r: Midi.Read) -> List<&2, U32>:
  Read{val, rest} = r
  rest

# The track's next event, and the track after it.
def Midi.next(t: Midi.Track) -> Midi.Got:
  Track{bytes, +status} = t
  Midi.status(status, Midi.byte(Midi.Read.rest(Midi.vlq(bytes))))

def Midi.tracks.one(n: Nat, +bytes: List<&2, U32>) -> List<&2, Midi.Track>:
  match n:
    case 0n:
      []
    case 1n+m:
      +len = U32.to_nat(Midi.be(4n, List.drop(&2, U32, bytes, 4n)))
      +body = List.drop(&2, U32, bytes, 8n)
      Track{List.take(&2, U32, body, len), 0} <> Midi.tracks.one(m, List.drop(&2, U32, body, len))

# A standard MIDI file's division (ticks a beat) and its tracks.
type Midi.File is Data:
  File{division: U32, tracks: List<&2, Midi.Track>}

def Midi.file(+bytes: List<&2, U32>) -> Midi.File:
  File{Midi.be(2n, List.drop(&2, U32, bytes, 12n)),
    Midi.tracks.one(U32.to_nat(Midi.be(2n, List.drop(&2, U32, bytes, 10n))), List.drop(&2, U32, bytes, 14n))}
