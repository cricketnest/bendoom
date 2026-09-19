# E1M1's song, read an event at a time as Chocolate Doom's player gets
# it. A MIDI lump is read as midifile.c reads it: each event after its
# delta, a data byte where a status belongs repeating the last status
# byte, meta events included. A MUS lump is read as midifile.c reads what
# mus2mid.c converts it to, with no MIDI bytes made in between. What
# either would refuse reads as a Bad track.
import Base

# A MIDI track at its next event, and the last status byte; a MUS track
# at its next event, the delta before it, the MUS channels in the order
# of their first use, and each MIDI channel's last velocity; or a track
# Chocolate Doom refuses, and why.
type Midi.Track is Data:
  Track{bytes: List<&2, U32>, status: U32}
  Mus{bytes: List<&2, U32>, delta: U32, chans: List<&2, U32>, vels: List<&2, U32>}
  Bad{why: String}

# A channel event: kind is the status's high nibble (0x80 note off, 0x90
# note on, 0xB0 controller, 0xC0 program, 0xE0 pitch bend, ...), p2 zero
# for the one-parameter kinds. Of the meta events, set tempo with the
# three bytes i_oplmusic.c takes, and end of track; any other is Other.
type Midi.Event is Data:
  Chan{kind: U32, ch: U32, p1: U32, p2: U32}
  Tempo{us: U32}
  End{}
  Other{}

# A value read, the bytes after it, and whether every byte it took was
# there and well formed.
type Midi.Read is Data:
  Read{val: U32, rest: List<&2, U32>, ok: Bool}

type Midi.Got is Data:
  Got{event: Midi.Event, track: Midi.Track}

def Midi.byte(bytes: List<&2, U32>, ok: Bool) -> Midi.Read:
  match bytes:
    case []:
      Read{0, [], False{}}
    case b <> rest:
      Read{b, rest, ok}

def Midi.byte.after(r: Midi.Read) -> Midi.Read:
  Read{val, rest, ok} = r
  Midi.byte(rest, ok)

# A variable-length quantity: seven bits a byte, the top bit set on all
# but the last, in at most `left` bytes.
def Midi.vlq.go(bytes: List<&2, U32>, more: Bool, +left: U32, ok: Bool, +acc: U32) -> Midi.Read:
  match bytes more:
    case [] False{}:
      Read{acc, [], ok}
    case [] True{}:
      Read{acc, [], False{}}
    case b <> rest False{}:
      Read{acc, b <> rest, ok}
    case +b <> rest True{}:
      Midi.vlq.go(rest, U32.is_ge(b, 128), (left - 1 : U32), ok && U32.is_ne(left, 0),
        ((acc << 7n) .|. (b .&. 127) : U32))

# midifile.c's ReadVariableLength: four bytes at most.
def Midi.vlq(bytes: List<&2, U32>, ok: Bool) -> Midi.Read:
  Midi.vlq.go(bytes, True{}, 4, ok, 0)

# The bytes after the first n, if there are n.
def Midi.drop(n: Nat, bytes: List<&2, U32>, ok: Bool) -> Midi.Read:
  match n bytes:
    case 0n Nil{}:
      Read{0, [], ok}
    case 0n b <> rest:
      Read{0, b <> rest, ok}
    case 1n+m Nil{}:
      Read{0, [], False{}}
    case 1n+m b <> rest:
      Midi.drop(m, rest, ok)

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
  Read{val, rest, ok} = r
  val

# MIDI
# ----

def Midi.track(ok: Bool, rest: List<&2, U32>, +status: U32) -> Midi.Track:
  match ok:
    case True{}:
      Track{rest, status}
    case False{}:
      Bad{"a MIDI track midifile.c refuses: cut short, a number of five bytes, or a status byte it does not know"}

def Midi.meta.event(end: Bool, tempo: Bool, data: List<&2, U32>) -> Midi.Event:
  match end tempo:
    case True{} _:
      End{}
    case False{} True{}:
      Tempo{Midi.be(3n, data)}
    case False{} False{}:
      Other{}

def Midi.meta.data(+kind: U32, +n: U32, data: List<&2, U32>, r: Midi.Read) -> Midi.Got:
  Read{val, rest, ok} = r
  Got{Midi.meta.event(U32.is_eq(kind, 47), U32.is_eq(kind, 81) && U32.is_eq(n, 3), data),
    Midi.track(ok, rest, 255)}

def Midi.meta.len(+kind: U32, r: Midi.Read) -> Midi.Got:
  Read{+n, +rest, ok} = r
  Midi.meta.data(kind, n, rest, Midi.drop(U32.to_nat(n), rest, ok))

def Midi.meta(r: Midi.Read) -> Midi.Got:
  Read{kind, rest, ok} = r
  Midi.meta.len(kind, Midi.vlq(rest, ok))

def Midi.chan.two(+status: U32, +p1: U32, r: Midi.Read) -> Midi.Got:
  Read{p2, rest, ok} = r
  Got{Chan{(status .&. 240 : U32), (status .&. 15 : U32), p1, p2}, Midi.track(ok, rest, status)}

def Midi.chan(two: Bool, +status: U32, r: Midi.Read) -> Midi.Got:
  match two:
    case True{}:
      Read{p1, rest, ok} = r
      Midi.chan.two(status, p1, Midi.byte(rest, ok))
    case False{}:
      Read{p1, rest, ok} = r
      Got{Chan{(status .&. 240 : U32), (status .&. 15 : U32), p1, 0}, Midi.track(ok, rest, status)}

def Midi.sysex.data(+status: U32, r: Midi.Read) -> Midi.Got:
  Read{val, rest, ok} = r
  Got{Other{}, Midi.track(ok, rest, status)}

# A sysex event: its length, then as many bytes of data, which the player
# ignores.
def Midi.sysex(+status: U32, r: Midi.Read) -> Midi.Got:
  Read{+n, rest, ok} = r
  Midi.sysex.data(status, Midi.drop(U32.to_nat(n), rest, ok))

# A channel event's status is 0x80 to 0xEF. Any other, as 0xF1 to 0xFE
# but 0xF7, or a running status before the first status byte, fails the
# load.
def Midi.event.go(meta: Bool, sysex: Bool, +status: U32, bytes: List<&2, U32>, ok: Bool) -> Midi.Got:
  match meta sysex:
    case True{} _:
      Midi.meta(Midi.byte(bytes, ok))
    case False{} True{}:
      Midi.sysex(status, Midi.vlq(bytes, ok))
    case False{} False{}:
      Midi.chan(Bool.not(U32.is_eq((status .&. 224 : U32), 192)), status,
        Midi.byte(bytes, ok && U32.is_ge(status, 128) && U32.is_lt(status, 240)))

# The event of a status byte: meta 0xFF, sysex 0xF0 or 0xF7, or a channel
# event.
def Midi.event(+status: U32, bytes: List<&2, U32>, ok: Bool) -> Midi.Got:
  Midi.event.go(U32.is_eq(status, 255), U32.is_eq(status, 240) || U32.is_eq(status, 247), status, bytes, ok)

def Midi.event.status(fresh: Bool, +b: U32, +last: U32, rest: List<&2, U32>, ok: Bool) -> Midi.Got:
  match fresh:
    case True{}:
      Midi.event(b, rest, ok)
    case False{}:
      Midi.event(last, b <> rest, ok)

# A status byte, or the last one again before a data byte.
def Midi.status(+last: U32, r: Midi.Read) -> Midi.Got:
  Read{+b, rest, ok} = r
  Midi.event.status(U32.is_ge(b, 128), b, last, rest, ok)

# MUS
# ---

def Midi.mus.track(ok: Bool, rest: List<&2, U32>, +delta: U32, chans: List<&2, U32>, vels: List<&2, U32>) ->
  Midi.Track:
  match ok:
    case True{}:
      Mus{rest, delta, chans, vels}
    case False{}:
      Bad{"MUS data mus2mid.c refuses: cut short, an event or controller it does not know, or a delay of 2^28 ticks or more"}

def Midi.mus.delay(r: Midi.Read, chans: List<&2, U32>, vels: List<&2, U32>) -> Midi.Track:
  Read{+delay, rest, ok} = r
  Midi.mus.track(ok && U32.is_lt(delay, 268435456), rest, delay, chans, vels)

# The track after an event. A descriptor's top bit ends its group, and
# the delay before the next group follows, in as many bytes as it takes.
# WriteTime writes a delay of 2^28 ticks or more in five bytes, which
# midifile.c refuses.
def Midi.mus.after(last: Bool, rest: List<&2, U32>, ok: Bool, chans: List<&2, U32>, vels: List<&2, U32>) ->
  Midi.Track:
  match last:
    case True{}:
      Midi.mus.delay(Midi.vlq.go(rest, True{}, 4294967295, ok, 0), chans, vels)
    case False{}:
      Midi.mus.track(ok, rest, 0, chans, vels)

# mus2mid.c's controller_map: MUS controller c's MIDI number.
def Midi.mus.controller(+c: U32) -> U32:
  Maybe.default(&2, U32, List.get(&2, U32,
    [0, 32, 1, 7, 10, 11, 91, 93, 64, 67, 120, 123, 126, 127, 121], U32.to_nat(c)), 0)

def Midi.mus.release(+ch: U32, last: Bool, chans: List<&2, U32>, vels: List<&2, U32>, r: Midi.Read) -> Midi.Got:
  Read{+key, rest, ok} = r
  Got{Chan{128, ch, (key .&. 127 : U32), 0}, Midi.mus.after(last, rest, ok, chans, vels)}

def Midi.mus.pressed(+ch: U32, +key: U32, last: Bool, chans: List<&2, U32>, +vels: List<&2, U32>,
  rest: List<&2, U32>, ok: Bool) -> Midi.Got:
  Got{Chan{144, ch, (key .&. 127 : U32), Maybe.default(&2, U32, List.get(&2, U32, vels, U32.to_nat(ch)), 127)},
    Midi.mus.after(last, rest, ok, chans, vels)}

def Midi.mus.velocity(+ch: U32, +key: U32, last: Bool, chans: List<&2, U32>, vels: List<&2, U32>,
  r: Midi.Read) -> Midi.Got:
  Read{+v, rest, ok} = r
  Midi.mus.pressed(ch, key, last, chans, List.set(&2, U32, vels, U32.to_nat(ch), (v .&. 127 : U32)), rest, ok)

def Midi.mus.press.go(given: Bool, +ch: U32, +key: U32, last: Bool, chans: List<&2, U32>, vels: List<&2, U32>,
  rest: List<&2, U32>, ok: Bool) -> Midi.Got:
  match given:
    case True{}:
      Midi.mus.velocity(ch, key, last, chans, vels, Midi.byte(rest, ok))
    case False{}:
      Midi.mus.pressed(ch, key, last, chans, vels, rest, ok)

# A key press: a key with its top bit set is followed by a velocity,
# which the channel keeps for later presses.
def Midi.mus.press(+ch: U32, last: Bool, chans: List<&2, U32>, vels: List<&2, U32>, r: Midi.Read) -> Midi.Got:
  Read{+key, rest, ok} = r
  Midi.mus.press.go(U32.is_ge(key, 128), ch, key, last, chans, vels, rest, ok)

def Midi.mus.pitch(+ch: U32, last: Bool, chans: List<&2, U32>, vels: List<&2, U32>, r: Midi.Read) -> Midi.Got:
  Read{+b, rest, ok} = r
  Got{Chan{224, ch, ((b .&. 1) << 6n : U32), (b >> 1n : U32)}, Midi.mus.after(last, rest, ok, chans, vels)}

# A system event: controllers 10 to 14, with the value 0.
def Midi.mus.system(+ch: U32, last: Bool, chans: List<&2, U32>, vels: List<&2, U32>, r: Midi.Read) -> Midi.Got:
  Read{+c, rest, ok} = r
  Got{Chan{176, ch, Midi.mus.controller(c), 0},
    Midi.mus.after(last, rest, ok && U32.is_ge(c, 10) && U32.is_le(c, 14), chans, vels)}

def Midi.mus.value(+ch: U32, +c: U32, last: Bool, chans: List<&2, U32>, vels: List<&2, U32>, r: Midi.Read) ->
  Midi.Got:
  Read{+v, rest, ok} = r
  +patch = U32.is_eq(c, 0)
  Got{Chan{Bool.pick(U32, patch, 192, 176), ch, Bool.pick(U32, patch, (v .&. 127 : U32), Midi.mus.controller(c)),
    Bool.pick(U32, patch, 0, U32.min(v, 127))}, Midi.mus.after(last, rest, ok && U32.is_le(c, 9), chans, vels)}

# A controller change: controller 0 is a program change, and 1 to 9 map
# to MIDI's with values past 127 cut to 127.
def Midi.mus.control(+ch: U32, last: Bool, chans: List<&2, U32>, vels: List<&2, U32>, r: Midi.Read) -> Midi.Got:
  Read{+c, rest, ok} = r
  Midi.mus.value(ch, c, last, chans, vels, Midi.byte(rest, ok))

# The kinds of MUS event, by the descriptor's bits 4 to 6.
type Midi.Op is Data:
  Release{}
  Press{}
  Pitch{}
  System{}
  Control{}
  Finish{}
  Refused{}

def Midi.mus.op(+d: U32) -> Midi.Op:
  Maybe.default(&2, Midi.Op, List.get(&2, Midi.Op,
    [Release{}, Press{}, Pitch{}, System{}, Control{}, Refused{}, Finish{}, Refused{}],
    U32.to_nat(((d >> 4n) .&. 7 : U32))), Refused{})

def Midi.mus.event(op: Midi.Op, +ch: U32, last: Bool, chans: List<&2, U32>, vels: List<&2, U32>,
  rest: List<&2, U32>, ok: Bool) -> Midi.Got:
  match op:
    case Release{}:
      Midi.mus.release(ch, last, chans, vels, Midi.byte(rest, ok))
    case Press{}:
      Midi.mus.press(ch, last, chans, vels, Midi.byte(rest, ok))
    case Pitch{}:
      Midi.mus.pitch(ch, last, chans, vels, Midi.byte(rest, ok))
    case System{}:
      Midi.mus.system(ch, last, chans, vels, Midi.byte(rest, ok))
    case Control{}:
      Midi.mus.control(ch, last, chans, vels, Midi.byte(rest, ok))
    case Finish{}:
      Got{End{}, Midi.mus.track(ok, rest, 0, chans, vels)}
    case Refused{}:
      Got{End{}, Midi.mus.track(False{}, rest, 0, chans, vels)}

# The position of MUS channel c among those used so far, or their count
# if it is new.
def Midi.mus.index(chans: List<&2, U32>, +c: U32, +i: U32) -> U32:
  match chans:
    case []:
      i
    case +x <> rest:
      Bool.pick(U32, U32.is_eq(x, c), i, Midi.mus.index(rest, c, (i + 1 : U32)))

# The first use of a MUS channel sends its MIDI channel an all-notes-off,
# after the delta, and the event itself follows at once.
def Midi.mus.chan(fresh: Bool, +ch: U32, +c: U32, +d: U32, bytes: List<&2, U32>, chans: List<&2, U32>,
  vels: List<&2, U32>, rest: List<&2, U32>, ok: Bool) -> Midi.Got:
  match fresh:
    case True{}:
      Got{Chan{176, ch, 123, 0}, Mus{bytes, 0, List.append(&2, U32, chans, [c]), vels}}
    case False{}:
      Midi.mus.event(Midi.mus.op(d), ch, U32.is_ge(d, 128), chans, vels, rest, ok)

# GetMIDIChannel: MUS channel 15 is MIDI's percussion channel 9, and the
# others take MIDI channels in the order of their first use, skipping 9.
def Midi.mus.next(bytes: List<&2, U32>, +chans: List<&2, U32>, vels: List<&2, U32>, r: Midi.Read) -> Midi.Got:
  Read{+d, rest, ok} = r
  +c = (d .&. 15 : U32)
  +i = Midi.mus.index(chans, c, 0)
  +perc = U32.is_eq(c, 15)
  Midi.mus.chan(Bool.not(perc) && U32.is_eq(i, U32.from_nat(List.length(&2, U32, chans))),
    Bool.pick(U32, perc, 9, Bool.pick(U32, U32.is_ge(i, 9), (i + 1 : U32), i)), c, d, bytes, chans, vels, rest, ok)

# Reading
# -------

# The track's next event, and the track after it.
def Midi.next(t: Midi.Track) -> Midi.Got:
  match t:
    case Track{bytes, +status}:
      Midi.status(status, Midi.byte.after(Midi.vlq(bytes, True{})))
    case Mus{+bytes, delta, chans, vels}:
      Midi.mus.next(bytes, chans, vels, Midi.byte(bytes, True{}))
    case Bad{why}:
      Got{End{}, Bad{why}}

# The delta before a track's next event, in ticks.
def Midi.delta(t: Midi.Track) -> U32:
  match t:
    case Track{bytes, status}:
      Midi.Read.val(Midi.vlq(bytes, True{}))
    case Mus{bytes, delta, chans, vels}:
      delta
    case Bad{why}:
      0

# The track after its end-of-track event, reading at most n events.
def Midi.end(n: Nat, g: Midi.Got) -> Midi.Track:
  match n g:
    case _ Got{End{}, t}:
      t
    case 0n Got{e, t}:
      t
    case 1n+m Got{e, t}:
      Midi.end(m, Midi.next(t))

def Midi.Track.bytes(t: Midi.Track) -> List<&2, U32>:
  match t:
    case Track{bytes, status}:
      bytes
    case Mus{bytes, delta, chans, vels}:
      bytes
    case Bad{why}:
      []

def Midi.tracks.start(mtrk: Bool, bytes: List<&2, U32>) -> Midi.Track:
  match mtrk:
    case True{}:
      Track{List.drop(&2, U32, bytes, 8n), 0}
    case False{}:
      Bad{"a MIDI track without its MTrk header"}

# Each track as midifile.c's ReadTrack reads it: from after its eight-byte
# header up to its end-of-track event, the next header following that
# event. A track keeps the rest of the file after it, since the player
# reads no further than the end-of-track. i_oplmusic.c takes no MIDI lump
# of 96 KiB or more, so no track holds that many events.
def Midi.tracks(n: Nat, +bytes: List<&2, U32>) -> List<&2, Midi.Track>:
  match n:
    case 0n:
      []
    case 1n+m:
      +t = Midi.tracks.start(U32.is_eq(Midi.be(4n, bytes), 1297379947), bytes)
      t <> Midi.tracks(m, Midi.Track.bytes(Midi.end(U32.to_nat(98304), Midi.next(t))))

# A song's division (ticks a beat) and its tracks.
type Midi.File is Data:
  File{division: U32, tracks: List<&2, Midi.Track>}

# MIDI_GetFileTimeDivision: a negative division d, SMPTE's, is
# -(d / 256) * (d & 0xFF) in C's signed arithmetic.
def Midi.division(+d: U32) -> U32:
  Bool.pick(U32, U32.is_ge(d, 32768), (((65536 - d) / 256) * (d .&. 255) : U32), d)

def Midi.midi(fine: Bool, +division: U32, +bytes: List<&2, U32>) -> Midi.File:
  match fine:
    case True{}:
      File{division, Midi.tracks(U32.to_nat(Midi.be(2n, List.drop(&2, U32, bytes, 10n))),
        List.drop(&2, U32, bytes, 14n))}
    case False{}:
      File{division, [Bad{"a MIDI header midifile.c refuses, or a division of 0, which ScheduleTrack divides by"}]}

# ReadFileHeader: a header chunk of six bytes, format 0 or 1, at least
# one track.
def Midi.header(+bytes: List<&2, U32>) -> Midi.File:
  +division = Midi.division(Midi.be(2n, List.drop(&2, U32, bytes, 12n)))
  Midi.midi(U32.is_eq(Midi.be(4n, List.drop(&2, U32, bytes, 4n)), 6)
    && U32.is_le(Midi.be(2n, List.drop(&2, U32, bytes, 8n)), 1)
    && U32.is_ge(Midi.be(2n, List.drop(&2, U32, bytes, 10n)), 1) && U32.is_ne(division, 0), division, bytes)

# mus2mid.c's one track at 70 ticks a beat, from the score's start, every
# channel's velocity 127.
def Midi.mus(+bytes: List<&2, U32>) -> Midi.File:
  +start = (Midi.be(1n, List.drop(&2, U32, bytes, 6n)) .|. (Midi.be(1n, List.drop(&2, U32, bytes, 7n)) << 8n)
    : U32)
  File{70, [Mus{List.drop(&2, U32, bytes, U32.to_nat(start)), 0, [], List.replicate(U32, 16n, 127)}]}

# Whether there are more than n bytes.
def Midi.over(+bytes: List<&2, U32>, n: Nat) -> Bool:
  Bool.not(List.is_empty(&2, U32, List.drop(&2, U32, bytes, n)))

def Midi.file.of(midi: Bool, mus: Bool, +bytes: List<&2, U32>) -> Midi.File:
  match midi mus:
    case True{} _:
      Midi.header(bytes)
    case False{} True{}:
      Midi.mus(bytes)
    case False{} False{}:
      File{0, [Bad{"neither MUS nor a MIDI lump under 96 KiB"}]}

# I_OPL_RegisterSong reads a lump from "MThd" under 96 KiB as MIDI and
# converts any other as MUS. The render takes as MUS only a lump from
# "MUS" 0x1A with a whole header, 16 bytes.
def Midi.file(+bytes: List<&2, U32>) -> Midi.File:
  +tag = Midi.be(4n, bytes)
  Midi.file.of(U32.is_eq(tag, 1297377380) && Bool.not(Midi.over(bytes, U32.to_nat(98303))),
    U32.is_eq(tag, 1297437466) && Midi.over(bytes, 15n), bytes)

def Midi.fault.of(t: Midi.Track) -> Maybe<&2, String>:
  match t:
    case Bad{why}:
      Some{why}
    case Track{bytes, status}:
      None{}
    case Mus{bytes, delta, chans, vels}:
      None{}

# Each track to its end: every event but MUS's first-use all-notes-offs
# reads a byte, so none has 2^32 events.
def Midi.faults(ts: List<&2, Midi.Track>) -> Maybe<&2, String>:
  match ts:
    case []:
      None{}
    case t <> rest:
      Maybe.or(&2, String, Midi.fault.of(Midi.end(U32.to_nat(4294967295), Midi.next(t))), Midi.faults(rest))

def Midi.fault.file(f: Midi.File) -> Maybe<&2, String>:
  File{division, tracks} = f
  Midi.faults(tracks)

# Why Chocolate Doom would not play the lump, if it would not: the first
# track that fails.
def Midi.fault(+bytes: List<&2, U32>) -> Maybe<&2, String>:
  Midi.fault.file(Midi.file(bytes))
