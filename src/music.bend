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

type Music.Entry is Data:
  Entry{time: U32, track: U32}

# The chip with the frames made so far, the player, the tracks, the
# callback queue as the heap's array, now (current_time), fill (the
# frames of the buffer in progress), the tempo in microseconds a beat,
# and the song's ticks a beat.
type Music is Data:
  Music{sound: O.Opl.Frames, player: P.Player, tracks: List<&2, M.Midi.Track>,
    queue: List<&2, Music.Entry>, now: U32, fill: U32, tempo: U32, division: U32}

type Music.Env is Data:
  Env{roms: O.Opl.Roms, tabs: P.Player.Tabs}

# The callback queue
# ------------------

def Music.time(+e: Music.Entry) -> U32:
  Entry{time, track} = e
  time

def Music.track(+e: Music.Entry) -> U32:
  Entry{time, track} = e
  track

def Music.at(+q: List<&2, Music.Entry>, +i: U32) -> Music.Entry:
  Maybe.default(&2, Music.Entry, List.get(&2, Music.Entry, q, U32.to_nat(i)), Entry{0, 0})

def Music.put(q: List<&2, Music.Entry>, +i: U32, e: Music.Entry) -> List<&2, Music.Entry>:
  List.set(&2, Music.Entry, q, U32.to_nat(i), e)

def Music.size(+q: List<&2, Music.Entry>) -> U32:
  U32.from_nat(List.length(&2, Music.Entry, q))

def Music.settled(+q: List<&2, Music.Entry>, +id: U32, +e: Music.Entry) -> Bool:
  U32.is_eq(id, 0) || U32.is_ge(Music.time(e), Music.time(Music.at(q, ((id - 1) / 2 : U32))))

def Music.up(n: Nat, stop: Bool, +q: List<&2, Music.Entry>, +id: U32, +e: Music.Entry) ->
  List<&2, Music.Entry>:
  match n stop:
    case _ True{}:
      Music.put(q, id, e)
    case 0n False{}:
      Music.put(q, id, e)
    case 1n+m False{}:
      +parent = ((id - 1) / 2 : U32)
      +q2 = Music.put(q, id, Music.at(q, parent))
      Music.up(m, Music.settled(q2, parent, e), q2, parent, e)

# OPL_Queue_Push.
def Music.push(+q: List<&2, Music.Entry>, +e: Music.Entry) -> List<&2, Music.Entry>:
  +q2 = List.append(&2, Music.Entry, q, [e])
  Music.up(8n, Music.settled(q2, Music.size(q), e), q2, Music.size(q), e)

# Where OPL_Queue_Pop's percolation takes the last entry from i: the
# lesser child earlier than it, 64 for none.
def Music.child(+q: List<&2, Music.Entry>, +n: U32, +i: U32, +last: Music.Entry) -> U32:
  +c1 = ((i * 2) + 1 : U32)
  +c2 = ((i * 2) + 2 : U32)
  +t1 = Music.time(Music.at(q, c1))
  +t2 = Music.time(Music.at(q, c2))
  Bool.pick(U32, U32.is_lt(c1, n) && U32.is_lt(t1, Music.time(last)),
    Bool.pick(U32, U32.is_lt(c2, n) && U32.is_lt(t2, t1), c2, c1),
    Bool.pick(U32, U32.is_lt(c2, n) && U32.is_lt(t2, Music.time(last)), c2, 64))

def Music.down(f: Nat, stay: Bool, +q: List<&2, Music.Entry>, +i: U32, +c: U32, +last: Music.Entry,
  +n: U32) -> List<&2, Music.Entry>:
  match f stay:
    case _ True{}:
      Music.put(q, i, last)
    case 0n False{}:
      Music.put(q, i, last)
    case 1n+m False{}:
      +q2 = Music.put(q, i, Music.at(q, c))
      +next = Music.child(q2, n, c, last)
      Music.down(m, U32.is_eq(next, 64), q2, c, next, last, n)

type Music.Popped is Data:
  Popped{entry: Music.Entry, queue: List<&2, Music.Entry>}

# OPL_Queue_Pop.
def Music.pop(+q: List<&2, Music.Entry>) -> Music.Popped:
  +n = (Music.size(q) - 1 : U32)
  +last = Music.at(q, n)
  +q2 = List.take(&2, Music.Entry, q, U32.to_nat(n))
  +c = Music.child(q2, n, 0, last)
  Popped{Music.at(q, 0), Music.down(8n, U32.is_eq(c, 64), q2, 0, c, last, n)}

def Music.adjust(q: List<&2, Music.Entry>, +now: U32, +factor: F32) -> List<&2, Music.Entry>:
  match q:
    case []:
      []
    case e <> rest:
      Entry{+time, track} = e
      Entry{(now + F32.to_u32((U32.to_f32((time - now : U32)) / factor : F32)) : U32), track} <>
        Music.adjust(rest, now, factor)

# Callbacks
# ---------

def Music.due(+m: Music) -> Bool:
  Music{sound, player, tracks, +queue, +now, fill, tempo, division} = m
  Bool.not(List.is_empty(&2, Music.Entry, queue)) && U32.is_ge(now, Music.time(Music.at(queue, 0)))

# ScheduleTrack: the track's next event after its delta in ticks, turned
# to microseconds at the tempo.
def Music.schedule(+k: U32, t: M.Midi.Track, m: Music) -> Music:
  Music{sound, player, tracks, queue, +now, fill, +tempo, +division} = m
  +delta = M.Midi.delta(t)
  Music{sound, player, tracks, Music.push(queue, Entry{(now + (delta * (tempo / division)) +
    (((delta * (tempo % division)) / division)) : U32), k}), now, fill, tempo, division}

# A channel event: the player's writes go to the chip's buffer.
def Music.written(+p: P.Player, f: O.Opl.Frames) -> O.Opl.Frames:
  O.Frames{opl, out} = f
  O.Frames{O.Opl.queue(P.Player.taken(p), opl), out}

def Music.play(+env: Music.Env, +kind: U32, +raw: U32, +p1: U32, +p2: U32, m: Music) -> Music:
  Env{roms, +tabs} = env
  Music{sound, player, tracks, queue, now, fill, tempo, division} = m
  +p = P.Player.event(tabs, kind, raw, p1, p2, player)
  Music{Music.written(p, sound), P.Player.clear(p), tracks, queue, now, fill, tempo, division}

# MetaSetTempo: the queue rescaled by the old tempo over the new, in
# single precision, as OPL_Queue_AdjustCallbacks does.
def Music.retempo(+data: List<&2, U32>, m: Music) -> Music:
  Music{sound, player, tracks, queue, +now, fill, tempo, division} = m
  +new = ((O.Opl.at(data, 0) << 16n) .|. (O.Opl.at(data, 1) << 8n) .|. O.Opl.at(data, 2) : U32)
  Music{sound, player, tracks, Music.adjust(queue, now, (U32.to_f32(tempo) / U32.to_f32(new) : F32)), now,
    fill, new, division}

def Music.count(+xs: List<&2, U32>) -> U32:
  U32.from_nat(List.length(&2, U32, xs))

def Music.meta(end: Bool, tempo: Bool, +data: List<&2, U32>, +k: U32, t: M.Midi.Track, m: Music) -> Music:
  match end:
    case True{}:
      m
    case False{}:
      match tempo:
        case True{}:
          Music.schedule(k, t, Music.retempo(data, m))
        case False{}:
          Music.schedule(k, t, m)

def Music.handle(e: M.Midi.Event, +env: Music.Env, +k: U32, t: M.Midi.Track, m: Music) -> Music:
  match e:
    case M.Chan{kind, raw, p1, p2}:
      Music.schedule(k, t, Music.play(env, kind, raw, p1, p2, m))
    case M.Meta{+kind, +data}:
      Music.meta(U32.is_eq(kind, 47), U32.is_eq(kind, 81) && U32.is_eq(Music.count(data), 3), data, k, t, m)

def Music.got(+env: Music.Env, +k: U32, m: Music, g: M.Midi.Got) -> Music:
  Music{sound, player, tracks, queue, now, fill, tempo, division} = m
  M.Got{event, +t} = g
  Music.handle(event, env, k, t,
    Music{sound, player, List.set(&2, M.Midi.Track, tracks, U32.to_nat(k), t), queue, now, fill, tempo,
      division})

def Music.run(+env: Music.Env, m: Music, p: Music.Popped) -> Music:
  Music{sound, player, +tracks, queue, now, fill, tempo, division} = m
  Popped{+entry, q} = p
  Music.got(env, Music.track(entry), Music{sound, player, tracks, q, now, fill, tempo, division},
    M.Midi.next(Maybe.default(&2, M.Midi.Track,
      List.get(&2, M.Midi.Track, tracks, U32.to_nat(Music.track(entry))), M.Track{[], 0})))

def Music.queue(+m: Music) -> List<&2, Music.Entry>:
  Music{sound, player, tracks, queue, now, fill, tempo, division} = m
  queue

# TrackTimerCallback for the queue's first entry.
def Music.callback(+env: Music.Env, +m: Music) -> Music:
  Music.run(env, m, Music.pop(Music.queue(m)))

# AdvanceTime's loop: every callback due by now, in queue order.
def Music.advance(n: Nat, due: Bool, +env: Music.Env, m: Music) -> Music:
  match n due:
    case _ False{}:
      m
    case 0n True{}:
      m
    case 1n+f True{}:
      +m2 = Music.callback(env, m)
      Music.advance(f, Music.due(m2), env, m2)

# One cut of OPL_Mix_Callback's loop: frames up to the next callback's
# time or the buffer's end. Past 100 ms a cut is the buffer's rest.
def Music.cut(+env: Music.Env, m: Music) -> Music:
  Env{+roms, tabs} = env
  Music{sound, player, tracks, +queue, +now, +fill, tempo, division} = m
  +d = U32.min((Music.time(Music.at(queue, 0)) - now : U32), 100000)
  +n = U32.min((((d * 441) + 9999) / 10000 : U32), (4096 - fill : U32))
  Music{O.Opl.frames(U32.to_nat(n), roms, sound), player, tracks, queue, (now + ((n * 10000) / 441) : U32),
    ((fill + n) % 4096 : U32), tempo, division}

# Cuts until a callback is due.
def Music.until(n: Nat, due: Bool, +env: Music.Env, m: Music) -> Music:
  match n due:
    case _ True{}:
      m
    case 0n False{}:
      m
    case 1n+f False{}:
      +m2 = Music.cut(env, m)
      Music.until(f, Music.due(m2), env, m2)

# Starting
# --------

type Music.Lumps is Data:
  Lumps{genmidi: List<&2, U32>, song: List<&2, U32>}

def Music.lump(+lumps: List<&2, W.Wad.Lump>, +name: String) -> W.Wad.Lump:
  Maybe.default(&2, W.Wad.Lump, List.get(&2, W.Wad.Lump, lumps,
    Maybe.default(&1, Nat, W.Wad.index(name, lumps), 0n)), W.Lump{0, 0, ""})

def Music.pos(+l: W.Wad.Lump) -> U32:
  W.Lump{pos, size, name} = l
  pos

def Music.bytes(+l: W.Wad.Lump) -> U32:
  W.Lump{pos, size, name} = l
  size

def Music.lumps.fin(genmidi: List<&2, U32>, p: Array<U32> & List<&2, U32>) -> Array<U32> & Music.Lumps:
  (a, song) = p
  (a, Lumps{genmidi, song})

def Music.lumps.song(+song: W.Wad.Lump, p: Array<U32> & List<&2, U32>) -> Array<U32> & Music.Lumps:
  (a, genmidi) = p
  Music.lumps.fin(genmidi, B.Bytes.list(a, Music.pos(song), Music.bytes(song)))

def Music.lumps.dir(p: Array<U32> & List<&2, W.Wad.Lump>) -> Array<U32> & Music.Lumps:
  (a, +lumps) = p
  +gm = Music.lump(lumps, "GENMIDI")
  Music.lumps.song(Music.lump(lumps, "D_E1M1"), B.Bytes.list(a, Music.pos(gm), Music.bytes(gm)))

# GENMIDI and E1M1's song, D_E1M1, from a WAD's bytes.
def Music.lumps(a: Array<U32>) -> Array<U32> & Music.Lumps:
  Music.lumps.dir(W.Wad.dir(a))

def Music.env(+l: Music.Lumps) -> Music.Env:
  Lumps{genmidi, song} = l
  Env{O.Opl.roms(), P.Player.tabs(genmidi)}

def Music.file(f: M.Midi.File) -> Music:
  M.File{division, tracks} = f
  Music{O.Frames{O.Opl.reset(), []}, P.Player.start(), tracks, [], 0, 0, 500000, division}

# I_OPL_PlaySong: each track's first event scheduled at the default tempo.
def Music.play_song(ts: List<&2, M.Midi.Track>, +k: U32, m: Music) -> Music:
  match ts:
    case []:
      m
    case t <> rest:
      Music.play_song(rest, (k + 1 : U32), Music.schedule(k, t, m))

def Music.tracks(+m: Music) -> List<&2, M.Midi.Track>:
  Music{sound, player, tracks, queue, now, fill, tempo, division} = m
  tracks

def Music.setup(f: O.Opl.Frames) -> O.Opl.Frames:
  O.Frames{opl, out} = f
  O.Frames{O.Opl.queue(P.Player.setup(), opl), out}

# Chocolate Doom's first buffer: the chip, reset as the sound starts,
# makes 4096 frames before the game reaches the level. Then
# OPL_InitRegisters' writes join the buffer, and the song starts at the
# next buffer's first frame.
def Music.idle(+env: Music.Env, m: Music) -> Music:
  Env{+roms, tabs} = env
  Music{sound, player, +tracks, queue, now, fill, tempo, division} = m
  Music.play_song(tracks, 0, Music{Music.setup(O.Opl.frames(U32.to_nat(4096), roms, sound)), player, tracks, queue,
    now, fill, tempo, division})

def Music.out(m: Music) -> List<&2, U32>:
  Music{sound, player, tracks, queue, now, fill, tempo, division} = m
  O.Opl.Frames.out(sound)

def Music.song(+l: Music.Lumps) -> List<&2, U32>:
  Lumps{genmidi, song} = l
  song

def Music.opening.go(+env: Music.Env, +song: List<&2, U32>) -> List<&2, U32>:
  +m = Music.cut(env, Music.idle(env, Music.file(M.Midi.file(song))))
  +m2 = Music.advance(U32.to_nat(100000), Music.due(m), env, m)
  Music.out(Music.until(U32.to_nat(100000), Music.due(m2), env, m2))

# The opening: the idle buffer, then the song from its start to the
# callback after its first, the frames latest first.
def Music.opening(+l: Music.Lumps) -> List<&2, U32>:
  Music.opening.go(Music.env(l), Music.song(l))
