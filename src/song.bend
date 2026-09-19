# E1M1's song as Chocolate Doom plays it. Its SDL driver (opl/opl_sdl.c)
# fills 4096-frame buffers, each cut at every callback due in it: a cut
# is the whole frames that reach the callback's time, and time advances
# by the cut's microseconds, rounded down. The callbacks wait in
# opl_queue.c's heap and read the song's tracks (i_oplmusic.c). The
# song's time counts microseconds from its start.
import Base
import ./bytes.bend as B
import ./wad.bend as W
import ./opl.bend as O
import ./midi.bend as M
import ./player.bend as P

type Song.Entry is Data:
  Entry{time: U32, track: U32}

# The chip with the frames made so far, the player, the tracks, the
# callback heap as opl_queue.c's array, now (current_time), fill (the
# frames of the buffer in progress), the tempo in microseconds a beat,
# and the song's ticks a beat.
type Song is Data:
  Song{sound: O.Opl.Frames, player: P.Player, tracks: List<&2, M.Midi.Track>,
    heap: List<&2, Song.Entry>, now: U32, fill: U32, tempo: U32, division: U32}

type Song.Env is Data:
  Env{roms: O.Opl.Roms, tabs: P.Player.Tabs}

# The callback heap
# -----------------

def Song.time(+e: Song.Entry) -> U32:
  Entry{time, track} = e
  time

def Song.track(+e: Song.Entry) -> U32:
  Entry{time, track} = e
  track

def Song.at(+q: List<&2, Song.Entry>, +i: U32) -> Song.Entry:
  Maybe.default(&2, Song.Entry, List.get(&2, Song.Entry, q, U32.to_nat(i)), Entry{0, 0})

def Song.put(q: List<&2, Song.Entry>, +i: U32, e: Song.Entry) -> List<&2, Song.Entry>:
  List.set(&2, Song.Entry, q, U32.to_nat(i), e)

def Song.size(+q: List<&2, Song.Entry>) -> U32:
  U32.from_nat(List.length(&2, Song.Entry, q))

def Song.settled(+q: List<&2, Song.Entry>, +id: U32, +e: Song.Entry) -> Bool:
  U32.is_eq(id, 0) || U32.is_ge(Song.time(e), Song.time(Song.at(q, ((id - 1) / 2 : U32))))

def Song.up(n: Nat, stop: Bool, +q: List<&2, Song.Entry>, +id: U32, +e: Song.Entry) ->
  List<&2, Song.Entry>:
  match n stop:
    case _ True{}:
      Song.put(q, id, e)
    case 0n False{}:
      Song.put(q, id, e)
    case 1n+m False{}:
      +parent = ((id - 1) / 2 : U32)
      +q2 = Song.put(q, id, Song.at(q, parent))
      Song.up(m, Song.settled(q2, parent, e), q2, parent, e)

# OPL_Queue_Push.
def Song.push(+q: List<&2, Song.Entry>, +e: Song.Entry) -> List<&2, Song.Entry>:
  +q2 = List.append(&2, Song.Entry, q, [e])
  Song.up(8n, Song.settled(q2, Song.size(q), e), q2, Song.size(q), e)

# Where OPL_Queue_Pop's percolation takes the last entry from i: the
# lesser child earlier than it, if any.
def Song.child(+q: List<&2, Song.Entry>, +n: U32, +i: U32, +last: Song.Entry) -> Maybe<&2, U32>:
  +c1 = ((i * 2) + 1 : U32)
  +c2 = ((i * 2) + 2 : U32)
  +t1 = Song.time(Song.at(q, c1))
  +t2 = Song.time(Song.at(q, c2))
  Bool.pick(Maybe<&2, U32>, U32.is_lt(c1, n) && U32.is_lt(t1, Song.time(last)),
    Some{Bool.pick(U32, U32.is_lt(c2, n) && U32.is_lt(t2, t1), c2, c1)},
    Bool.pick(Maybe<&2, U32>, U32.is_lt(c2, n) && U32.is_lt(t2, Song.time(last)), Some{c2}, None{}))

def Song.down(f: Nat, next: Maybe<&2, U32>, +q: List<&2, Song.Entry>, +i: U32, +last: Song.Entry,
  +n: U32) -> List<&2, Song.Entry>:
  match f next:
    case _ None{}:
      Song.put(q, i, last)
    case 0n Some{c}:
      Song.put(q, i, last)
    case 1n+m Some{+c}:
      +q2 = Song.put(q, i, Song.at(q, c))
      Song.down(m, Song.child(q2, n, c, last), q2, c, last, n)

type Song.Popped is Data:
  Popped{entry: Song.Entry, heap: List<&2, Song.Entry>}

# OPL_Queue_Pop.
def Song.pop(+q: List<&2, Song.Entry>) -> Song.Popped:
  +n = (Song.size(q) - 1 : U32)
  +last = Song.at(q, n)
  +q2 = List.take(&2, Song.Entry, q, U32.to_nat(n))
  Popped{Song.at(q, 0), Song.down(8n, Song.child(q2, n, 0, last), q2, 0, last, n)}

def Song.adjust(q: List<&2, Song.Entry>, +now: U32, +factor: F32) -> List<&2, Song.Entry>:
  match q:
    case []:
      []
    case e <> rest:
      Entry{+time, track} = e
      Entry{(now + F32.to_u32((U32.to_f32((time - now : U32)) / factor : F32)) : U32), track} <>
        Song.adjust(rest, now, factor)

# Callbacks
# ---------

def Song.due(+m: Song) -> Bool:
  Song{sound, player, tracks, +heap, +now, fill, tempo, division} = m
  Bool.not(List.is_empty(&2, Song.Entry, heap)) && U32.is_ge(now, Song.time(Song.at(heap, 0)))

# ScheduleTrack: the track's next event after its delta in ticks, turned
# to microseconds at the tempo.
def Song.schedule(+k: U32, t: M.Midi.Track, m: Song) -> Song:
  Song{sound, player, tracks, heap, +now, fill, +tempo, +division} = m
  +delta = M.Midi.delta(t)
  Song{sound, player, tracks, Song.push(heap, Entry{(now + (delta * (tempo / division)) +
    (((delta * (tempo % division)) / division)) : U32), k}), now, fill, tempo, division}

# A channel event: the player's writes go to the chip's buffer.
def Song.event(+env: Song.Env, +kind: U32, +raw: U32, +p1: U32, +p2: U32, m: Song) -> Song:
  Env{roms, +tabs} = env
  Song{sound, player, tracks, heap, now, fill, tempo, division} = m
  +p = P.Player.event(tabs, kind, raw, p1, p2, player)
  Song{O.Opl.Frames.queue(P.Player.taken(p), sound), P.Player.clear(p), tracks, heap, now, fill, tempo,
    division}

# MetaSetTempo: the heap rescaled by the old tempo over the new, in
# single precision, as OPL_Queue_AdjustCallbacks does.
def Song.retempo(+new: U32, m: Song) -> Song:
  Song{sound, player, tracks, heap, +now, fill, tempo, division} = m
  Song{sound, player, tracks, Song.adjust(heap, now, (U32.to_f32(tempo) / U32.to_f32(new) : F32)), now,
    fill, new, division}

def Song.handle(e: M.Midi.Event, +env: Song.Env, +k: U32, t: M.Midi.Track, m: Song) -> Song:
  match e:
    case M.Chan{kind, raw, p1, p2}:
      Song.schedule(k, t, Song.event(env, kind, raw, p1, p2, m))
    case M.Tempo{us}:
      Song.schedule(k, t, Song.retempo(us, m))
    case M.End{}:
      m
    case M.Other{}:
      Song.schedule(k, t, m)

def Song.got(+env: Song.Env, +k: U32, m: Song, g: M.Midi.Got) -> Song:
  Song{sound, player, tracks, heap, now, fill, tempo, division} = m
  M.Got{event, +t} = g
  Song.handle(event, env, k, t,
    Song{sound, player, List.set(&2, M.Midi.Track, tracks, U32.to_nat(k), t), heap, now, fill, tempo,
      division})

def Song.run(+env: Song.Env, m: Song, p: Song.Popped) -> Song:
  Song{sound, player, +tracks, heap, now, fill, tempo, division} = m
  Popped{+entry, q} = p
  Song.got(env, Song.track(entry), Song{sound, player, tracks, q, now, fill, tempo, division},
    M.Midi.next(Maybe.default(&2, M.Midi.Track,
      List.get(&2, M.Midi.Track, tracks, U32.to_nat(Song.track(entry))), M.Track{[], 0})))

def Song.heap(+m: Song) -> List<&2, Song.Entry>:
  Song{sound, player, tracks, heap, now, fill, tempo, division} = m
  heap

# TrackTimerCallback for the heap's first entry.
def Song.callback(+env: Song.Env, +m: Song) -> Song:
  Song.run(env, m, Song.pop(Song.heap(m)))

# AdvanceTime's loop: every callback due by now, in heap order.
def Song.advance(n: Nat, due: Bool, +env: Song.Env, m: Song) -> Song:
  match n due:
    case _ False{}:
      m
    case 0n True{}:
      m
    case 1n+f True{}:
      +m2 = Song.callback(env, m)
      Song.advance(f, Song.due(m2), env, m2)

# One cut of OPL_Mix_Callback's loop: frames up to the next callback's
# time or the buffer's end. Past 100 ms a cut is the buffer's rest.
def Song.cut(+env: Song.Env, m: Song) -> Song:
  Env{+roms, tabs} = env
  Song{sound, player, tracks, +heap, +now, +fill, tempo, division} = m
  +d = U32.min((Song.time(Song.at(heap, 0)) - now : U32), 100000)
  +n = U32.min((((d * 441) + 9999) / 10000 : U32), (4096 - fill : U32))
  Song{O.Opl.frames(U32.to_nat(n), roms, sound), player, tracks, heap, (now + ((n * 10000) / 441) : U32),
    ((fill + n) % 4096 : U32), tempo, division}

# Cuts until a callback is due.
def Song.until(n: Nat, due: Bool, +env: Song.Env, m: Song) -> Song:
  match n due:
    case _ True{}:
      m
    case 0n False{}:
      m
    case 1n+f False{}:
      +m2 = Song.cut(env, m)
      Song.until(f, Song.due(m2), env, m2)

# Starting
# --------

type Song.Lumps is Data:
  Lumps{genmidi: List<&2, U32>, song: List<&2, U32>}

def Song.read(a: Array<U32>, at: U32 & U32) -> Array<U32> & List<&2, U32>:
  (pos, size) = at
  B.Bytes.list(a, pos, size)

def Song.lumps.fin(genmidi: List<&2, U32>, p: Array<U32> & List<&2, U32>) -> Array<U32> & Song.Lumps:
  (a, song) = p
  (a, Lumps{genmidi, song})

def Song.lumps.song(song: U32 & U32, p: Array<U32> & List<&2, U32>) -> Array<U32> & Song.Lumps:
  (a, genmidi) = p
  Song.lumps.fin(genmidi, Song.read(a, song))

def Song.lumps.dir(p: Array<U32> & List<&2, W.Wad.Lump>) -> Array<U32> & Song.Lumps:
  (a, +lumps) = p
  Song.lumps.song(W.Wad.find(lumps, "D_E1M1"), Song.read(a, W.Wad.find(lumps, "GENMIDI")))

# GENMIDI and E1M1's song, D_E1M1, from a WAD's bytes.
def Song.lumps(a: Array<U32>) -> Array<U32> & Song.Lumps:
  Song.lumps.dir(W.Wad.dir(a))

def Song.lumps.only(p: Array<U32> & Song.Lumps) -> Song.Lumps:
  (a, l) = p
  l

# The lumps of the WAD named by BENDOOM_IWAD.
def Song.load() -> IO(Song.Lumps):
  do IO<Song.Lumps>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    IO.pure(Song.Lumps, Song.lumps.only(Song.lumps(bytes)))

def Song.env(+l: Song.Lumps) -> Song.Env:
  Lumps{genmidi, song} = l
  Env{O.Opl.roms(), P.Player.tabs(genmidi)}

def Song.file(f: M.Midi.File) -> Song:
  M.File{division, tracks} = f
  Song{O.Frames{O.Opl.reset(), []}, P.Player.start(), tracks, [], 0, 0, 500000, division}

# I_OPL_PlaySong: each track's first event scheduled at the default tempo.
def Song.start(ts: List<&2, M.Midi.Track>, +k: U32, m: Song) -> Song:
  match ts:
    case []:
      m
    case t <> rest:
      Song.start(rest, (k + 1 : U32), Song.schedule(k, t, m))

# Chocolate Doom's first buffer: the chip, reset as the sound starts,
# makes 4096 frames before the game reaches the level. Then
# OPL_InitRegisters' writes join the buffer, and the song starts at the
# next buffer's first frame.
def Song.idle(+env: Song.Env, m: Song) -> Song:
  Env{+roms, tabs} = env
  Song{sound, player, +tracks, heap, now, fill, tempo, division} = m
  Song.start(tracks, 0, Song{O.Opl.Frames.queue(P.Player.setup(), O.Opl.frames(U32.to_nat(4096), roms, sound)),
    player, tracks, heap, now, fill, tempo, division})

def Song.out(m: Song) -> List<&2, U32>:
  Song{sound, player, tracks, heap, now, fill, tempo, division} = m
  O.Opl.Frames.out(sound)

def Song.song(+l: Song.Lumps) -> List<&2, U32>:
  Lumps{genmidi, song} = l
  song

def Song.opening.go(+env: Song.Env, +song: List<&2, U32>) -> List<&2, U32>:
  +m = Song.cut(env, Song.idle(env, Song.file(M.Midi.file(song))))
  +m2 = Song.advance(U32.to_nat(100000), Song.due(m), env, m)
  Song.out(Song.until(U32.to_nat(100000), Song.due(m2), env, m2))

# The opening: the idle buffer, then the song from its start to the
# callback after its first, the frames latest first.
def Song.opening(+l: Song.Lumps) -> List<&2, U32>:
  Song.opening.go(Song.env(l), Song.song(l))
