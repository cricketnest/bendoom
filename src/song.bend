# E1M1's song as Chocolate Doom plays it. Its SDL driver (opl/opl_sdl.c)
# fills 4096-frame buffers, each cut at every callback due in it: a cut
# is the whole frames that reach the callback's time, and time advances
# by the cut's microseconds, rounded down. The callbacks wait in
# opl_queue.c's heap and read the song's tracks (i_oplmusic.c). The
# song's time counts microseconds from its start.
import Base
import ./bytes.bend as B
import ./wad.bend as W
import ./fixed.bend as F
import ./opl.bend as O
import ./midi.bend as M
import ./player.bend as P

# A callback: a track's next event (TrackTimerCallback), or the restart
# 5 ms after the last track ends (RestartSong), where the pass ends.
type Song.Entry is Data:
  Next{time: U32, track: U32}
  Restart{time: U32}

# The chip with the frames made so far, the player, the tracks, the
# callback heap as opl_queue.c's array, now (current_time), the frames
# made, the tracks still running, the tempo in microseconds a beat, and
# the song's ticks a beat.
type Song is Data:
  Song{sound: O.Opl.Frames, player: P.Player, tracks: List<&2, M.Midi.Track>,
    heap: List<&2, Song.Entry>, now: U32, made: U32, running: U32, tempo: U32, division: U32}

type Song.Env is Data:
  Env{roms: O.Opl.Roms, tabs: P.Player.Tabs}

# The callback heap
# -----------------

def Song.time(+e: Song.Entry) -> U32:
  match e:
    case Next{time, track}:
      time
    case Restart{time}:
      time

def Song.at(+q: List<&2, Song.Entry>, +i: U32) -> Song.Entry:
  Maybe.default(&2, Song.Entry, List.get(&2, Song.Entry, q, U32.to_nat(i)), Restart{0})

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

# OPL_Queue_Pop, less the entry it hands out.
def Song.pop(+q: List<&2, Song.Entry>) -> List<&2, Song.Entry>:
  +n = (Song.size(q) - 1 : U32)
  +last = Song.at(q, n)
  +q2 = List.take(&2, Song.Entry, q, U32.to_nat(n))
  Song.down(8n, Song.child(q2, n, 0, last), q2, 0, last, n)

# OPL_Queue_AdjustCallbacks for one time: its offset from now, an int64
# made a float, over the factor, truncated toward zero (cvttss2si, which
# gcc emits for the cast to uint64_t below 2^63) and added back. An
# offset below zero, a callback overdue as the tempo changes, stays
# overdue.
def Song.rescale(+now: U32, +factor: F32, +time: U32) -> U32:
  +off = (time - now : U32)
  +neg = F.Fixed.is_neg(off)
  +q = F32.to_u32((U32.to_f32(Bool.pick(U32, neg, (0 - off : U32), off)) / factor : F32))
  (now + Bool.pick(U32, neg, (0 - q : U32), q) : U32)

def Song.adjust(q: List<&2, Song.Entry>, +now: U32, +factor: F32) -> List<&2, Song.Entry>:
  match q:
    case []:
      []
    case Next{+time, k} <> rest:
      Next{Song.rescale(now, factor, time), k} <> Song.adjust(rest, now, factor)
    case Restart{+time} <> rest:
      Restart{Song.rescale(now, factor, time)} <> Song.adjust(rest, now, factor)

# Callbacks
# ---------

# ScheduleTrack: the track's next event after its delta in ticks, turned
# to microseconds at the tempo.
def Song.schedule(+k: U32, t: M.Midi.Track, m: Song) -> Song:
  Song{sound, player, tracks, heap, +now, made, running, +tempo, +division} = m
  +delta = M.Midi.delta(t)
  Song{sound, player, tracks, Song.push(heap, Next{(now + (delta * (tempo / division)) +
    (((delta * (tempo % division)) / division)) : U32), k}), now, made, running, tempo, division}

# A channel event: the player's writes go to the chip's buffer.
def Song.event(+env: Song.Env, +kind: U32, +raw: U32, +p1: U32, +p2: U32, m: Song) -> Song:
  Env{roms, +tabs} = env
  Song{sound, player, tracks, heap, now, made, running, tempo, division} = m
  +p = P.Player.event(tabs, kind, raw, p1, p2, player)
  Song{O.Opl.Frames.queue(P.Player.taken(p), sound), P.Player.clear(p), tracks, heap, now, made, running,
    tempo, division}

# MetaSetTempo: the heap rescaled by the old tempo over the new, in
# single precision.
def Song.retempo(+new: U32, m: Song) -> Song:
  Song{sound, player, tracks, heap, +now, made, running, tempo, division} = m
  Song{sound, player, tracks, Song.adjust(heap, now, (U32.to_f32(tempo) / U32.to_f32(new) : F32)), now,
    made, running, new, division}

def Song.last(done: Bool, +now: U32, heap: List<&2, Song.Entry>) -> List<&2, Song.Entry>:
  match done:
    case True{}:
      Song.push(heap, Restart{(now + 5000 : U32)})
    case False{}:
      heap

# A track's end: it is not scheduled again, and the last track's end
# schedules the restart.
def Song.ended(m: Song) -> Song:
  Song{sound, player, tracks, heap, +now, made, +running, tempo, division} = m
  Song{sound, player, tracks, Song.last(U32.is_eq(running, 1), now, heap), now, made, (running - 1 : U32),
    tempo, division}

def Song.handle(e: M.Midi.Event, +env: Song.Env, +k: U32, t: M.Midi.Track, m: Song) -> Song:
  match e:
    case M.Chan{kind, raw, p1, p2}:
      Song.schedule(k, t, Song.event(env, kind, raw, p1, p2, m))
    case M.Tempo{us}:
      Song.schedule(k, t, Song.retempo(us, m))
    case M.End{}:
      Song.ended(m)
    case M.Other{}:
      Song.schedule(k, t, m)

def Song.got(+env: Song.Env, +k: U32, m: Song, g: M.Midi.Got) -> Song:
  Song{sound, player, tracks, heap, now, made, running, tempo, division} = m
  M.Got{event, +t} = g
  Song.handle(event, env, k, t,
    Song{sound, player, List.set(&2, M.Midi.Track, tracks, U32.to_nat(k), t), heap, now, made, running, tempo,
      division})

# TrackTimerCallback for track k, the heap's first entry.
def Song.callback(+env: Song.Env, +k: U32, m: Song) -> Song:
  Song{sound, player, +tracks, +heap, now, made, running, tempo, division} = m
  Song.got(env, k, Song{sound, player, tracks, Song.pop(heap), now, made, running, tempo, division},
    M.Midi.next(Maybe.default(&2, M.Midi.Track, List.get(&2, M.Midi.Track, tracks, U32.to_nat(k)),
      M.Track{[], 0})))

# One cut of OPL_Mix_Callback's loop: frames up to the next callback's
# time, d microseconds away, or the buffer's end, and no further than
# the span. Past 100 ms a cut is the buffer's rest.
def Song.cut(+env: Song.Env, +d: U32, +span: U32, m: Song) -> Song:
  Env{+roms, tabs} = env
  Song{sound, player, tracks, heap, +now, +made, running, tempo, division} = m
  +n = U32.min(U32.min((((d * 441) + 9999) / 10000 : U32), (4096 - (made % 4096) : U32)), (span - made : U32))
  Song{O.Opl.frames(U32.to_nat(n), roms, sound), player, tracks, heap, (now + ((n * 10000) / 441) : U32),
    (made + n : U32), running, tempo, division}

# What OPL_Mix_Callback does next: cut toward the next callback, run it
# if due, or stop at the restart or the span's end.
type Song.Step is Data:
  Cut{d: U32}
  Call{track: U32}
  Stop{}

def Song.wait(+now: U32, +time: U32) -> U32:
  U32.min((time - now : U32), 100000)

def Song.step.at(+now: U32, +full: Bool, e: Song.Entry) -> Song.Step:
  match e:
    case Next{+time, k}:
      Bool.pick(Song.Step, full, Stop{},
        Bool.pick(Song.Step, U32.is_ge(now, time), Call{k}, Cut{Song.wait(now, time)}))
    case Restart{+time}:
      Bool.pick(Song.Step, full || U32.is_ge(now, time), Stop{}, Cut{Song.wait(now, time)})

def Song.step.top(+now: U32, +full: Bool, top: Maybe<&2, Song.Entry>) -> Song.Step:
  match top:
    case None{}:
      Bool.pick(Song.Step, full, Stop{}, Cut{100000})
    case Some{e}:
      Song.step.at(now, full, e)

def Song.step(+span: U32, +m: Song) -> Song.Step:
  Song{sound, player, tracks, +heap, +now, +made, running, tempo, division} = m
  Song.step.top(now, U32.is_ge(made, span), List.head(&2, Song.Entry, heap))

def Song.play(n: Nat, s: Song.Step, +span: U32, +env: Song.Env, m: Song) -> Song:
  match n s:
    case _ Stop{}:
      m
    case 0n Cut{d}:
      m
    case 0n Call{k}:
      m
    case 1n+f Cut{+d}:
      +m2 = Song.cut(env, d, span, m)
      Song.play(f, Song.step(span, m2), span, env, m2)
    case 1n+f Call{+k}:
      +m2 = Song.callback(env, k, m)
      Song.play(f, Song.step(span, m2), span, env, m2)

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
  M.File{division, +tracks} = f
  Song{O.Frames{O.Opl.reset(), []}, P.Player.start(), tracks, [], 0, 0,
    U32.from_nat(List.length(&2, M.Midi.Track, tracks)), 500000, division}

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
  Song{sound, player, +tracks, heap, now, made, running, tempo, division} = m
  Song.start(tracks, 0,
    Song{O.Opl.Frames.queue(P.Player.setup(), O.Opl.frames(U32.to_nat(4096), roms, sound)), player, tracks,
      heap, now, 4096, running, tempo, division})

def Song.song(+l: Song.Lumps) -> List<&2, U32>:
  Lumps{genmidi, song} = l
  song

def Song.render.go(+span: U32, +env: Song.Env, +m: Song) -> Song:
  Song.play(U32.to_nat(100000000), Song.step(span, m), span, env, m)

# The idle buffer, then the song's first pass, up to the restart or the
# span's frames if fewer.
def Song.render(+span: U32, +l: Song.Lumps) -> Song:
  +env = Song.env(l)
  Song.render.go(span, env, Song.idle(env, Song.file(M.Midi.file(Song.song(l)))))

# The frames made, latest first.
def Song.out(m: Song) -> List<&2, U32>:
  Song{sound, player, tracks, heap, now, made, running, tempo, division} = m
  O.Opl.Frames.out(sound)

def Song.made(+m: Song) -> U32:
  Song{sound, player, tracks, heap, now, made, running, tempo, division} = m
  made
