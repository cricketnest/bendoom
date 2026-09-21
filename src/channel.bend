# Doom's s_sound.c channels: the eight voices a level's sounds are
# allotted. They live outside the sim's state because vanilla frees a
# channel when the device has finished it and not on a tic. A channel is
# the open file of the sound it plays, the sound and the source that
# made it, and the left and right volumes the device was given for it.
# The mixer reads the files; this module allots them.
import Base
import ./sound.bend as Sn

# A playing sound, its file open at the frame the mixer writes next.
type Channel is Type:
  Chan{file: File, sfx: U32, source: Sn.Sound.Source, left: U32, right: U32}

# snd_channels at Chocolate Doom's default, every one free.
def Channel.none() -> List<Maybe<Channel>>:
  [None{}, None{}, None{}, None{}, None{}, None{}, None{}, None{}]

# One side of I_SDL_UpdateSoundParams: a share of the separation times
# the volume over 127, clamped to a byte.
def Channel.side(+share: U32, +vol: U32) -> U32:
  U32.min(((share * vol : U32) / 127 : U32), 255)

# Its left, ((254 - sep) * vol) / 127. A separation of 255 leaves the
# share below zero, which C divides toward zero and clamps to none, so
# the share stops at 0 here.
def Channel.left(+vol: U32, +sep: U32) -> U32:
  Channel.side((254 - U32.min(sep, 254) : U32), vol)

# Its right, (sep * vol) / 127.
def Channel.right(+vol: U32, +sep: U32) -> U32:
  Channel.side(sep, vol)

# The file the sounds node left for a sound, beside the others.
def Channel.path(+dir: String, +sfx: U32) -> String:
  dir ++ "/" ++ Sn.Sound.lump(Sn.Sound.table(), sfx) ++ ".raw"

def Channel.hush.gone(+hit: Bool, file: File, +sfx: U32, source: Sn.Sound.Source, +left: U32, +right: U32) ->
  IO(Maybe<Channel>):
  match hit:
    case True{}:
      do IO<Maybe<Channel>>:
        File.close(file)
        return None{}
    case False{}:
      IO.pure(Maybe<Channel>, Some{Chan{file, sfx, source, left, right}})

def Channel.hush.slot(+source: Sn.Sound.Source, c: Maybe<Channel>) -> IO(Maybe<Channel>):
  match c:
    case None{}:
      IO.pure(Maybe<Channel>, None{})
    case Some{Chan{file, sfx, +was, left, right}}:
      Channel.hush.gone(Sn.Sound.Source.same(source, was), file, sfx, was, left, right)

# S_StopSound: the source's channel is freed and its file closed. A
# source holds one channel at a time, so there is at most one to free.
def Channel.hush(+source: Sn.Sound.Source, chans: List<Maybe<Channel>>) -> IO(List<Maybe<Channel>>):
  match chans:
    case []:
      IO.pure(List<Maybe<Channel>>, [])
    case c <> rest:
      do IO<List<Maybe<Channel>>>:
        kept : Maybe<Channel> <- Channel.hush.slot(source, c)
        cs : List<Maybe<Channel>> <- Channel.hush(source, rest)
        return kept <> cs

# A sound with no channel to play it is dropped, and the file opened for
# it closes again.
def Channel.put.gone(new: Channel) -> IO(List<Maybe<Channel>>):
  Chan{file, sfx, source, left, right} = new
  do IO<List<Maybe<Channel>>>:
    File.close(file)
    return []

def Channel.put.here(new: Channel, rest: List<Maybe<Channel>>, old: Maybe<Channel>) ->
  IO(List<Maybe<Channel>>):
  match old:
    case None{}:
      IO.pure(List<Maybe<Channel>>, Some{new} <> rest)
    case Some{Chan{file, sfx, source, left, right}}:
      do IO<List<Maybe<Channel>>>:
        File.close(file)
        return Some{new} <> rest

# The sound put in the channel of that number, whose own sound stops,
# S_GetChannel's S_StopChannel. A number past the last channel is the
# sound dropped.
def Channel.put(chans: List<Maybe<Channel>>, n: Nat, new: Channel) -> IO(List<Maybe<Channel>>):
  match chans n:
    case [] _:
      Channel.put.gone(new)
    case c <> rest 0n:
      Channel.put.here(new, rest, c)
    case c <> rest 1n+m:
      do IO<List<Maybe<Channel>>>:
        cs : List<Maybe<Channel>> <- Channel.put(rest, m, new)
        return c <> cs

def Channel.slot.busy(+take: Bool, c: Channel, p: List<Maybe<Channel>> & U32 & U32) ->
  List<Maybe<Channel>> & U32 & U32:
  (rest, free, victim) = p
  (Some{c} <> rest, (free + 1 : U32), Bool.pick(U32, take, 0, (victim + 1 : U32)))

def Channel.slot(+pri: U32, c: Maybe<Channel>, p: List<Maybe<Channel>> & U32 & U32) ->
  List<Maybe<Channel>> & U32 & U32:
  match c:
    case None{}:
      (rest, free, victim) = p
      (None{} <> rest, 0, (victim + 1 : U32))
    case Some{Chan{file, +sfx, source, left, right}}:
      Channel.slot.busy(U32.is_ge(Sn.Sound.priority(Sn.Sound.table(), sfx), pri),
        Chan{file, sfx, source, left, right}, p)

# S_GetChannel's two searches, in one walk of the table: the first free
# channel, and the first playing a sound no more important than this
# one, each counted from the front and eight for none.
def Channel.slots(+pri: U32, chans: List<Maybe<Channel>>) -> List<Maybe<Channel>> & U32 & U32:
  match chans:
    case []:
      ([], 0, 0)
    case c <> rest:
      Channel.slot(pri, c, Channel.slots(pri, rest))

def Channel.opened(+sfx: U32, source: Sn.Sound.Source, +left: U32, +right: U32, chans: List<Maybe<Channel>>,
  n: Nat, r: Result<&1, &1, U32 & String, File>) -> IO(List<Maybe<Channel>>):
  match r:
    case Fail{e}:
      IO.pure(List<Maybe<Channel>>, chans)
    case Done{f}:
      Channel.put(chans, n, Chan{f, sfx, source, left, right})

# S_GetChannel: a free channel takes the sound, or else the first
# channel of no greater importance is kicked out, and if every one is
# more important the sound is dropped. A sound whose file will not open
# is dropped too, which is the game with no sounds directory.
def Channel.start(+dir: String, +sfx: U32, source: Sn.Sound.Source, +left: U32, +right: U32,
  p: List<Maybe<Channel>> & U32 & U32) -> IO(List<Maybe<Channel>>):
  (chans, +free, victim) = p
  IO.bind(Result<&1, &1, U32 & String, File>, List<Maybe<Channel>>, File.open(Channel.path(dir, sfx), "r"),
    r => Channel.opened(sfx, source, left, right, chans,
      U32.to_nat(Bool.pick(U32, U32.is_lt(free, 8), free, victim)), r))

# What the sim reported, played: S_StartSound's tail after the
# audibility test, where the source's old sound is stopped and the new
# one takes a channel at the sides the volume and separation give.
def Channel.event(+dir: String, e: Sn.Sound.Event, chans: List<Maybe<Channel>>) ->
  IO(List<Maybe<Channel>>):
  match e:
    case Sn.Start{+sfx, +source, +vol, +sep}:
      do IO<List<Maybe<Channel>>>:
        hushed : List<Maybe<Channel>> <- Channel.hush(source, chans)
        Channel.start(dir, sfx, source, Channel.left(vol, sep), Channel.right(vol, sep),
          Channel.slots(Sn.Sound.priority(Sn.Sound.table(), sfx), hushed))
    case Sn.Stop{source}:
      Channel.hush(source, chans)

# The channels after the sounds of a frame's tics, in the order the tics
# made them.
def Channel.hear(+dir: String, events: List<&2, Sn.Sound.Event>, chans: List<Maybe<Channel>>) ->
  IO(List<Maybe<Channel>>):
  match events:
    case []:
      IO.pure(List<Maybe<Channel>>, chans)
    case e <> rest:
      do IO<List<Maybe<Channel>>>:
        cs : List<Maybe<Channel>> <- Channel.event(dir, e, chans)
        Channel.hear(dir, rest, cs)

def Channel.moved(c: Channel, p: U32 & U32) -> IO(Maybe<Channel>):
  Chan{file, sfx, source, left, right} = c
  (+vol, +sep) = p
  Channel.hush.gone(U32.is_zero(vol), file, sfx, source, Channel.left(vol, sep), Channel.right(vol, sep))

def Channel.update.slot(~Ctx: Data, ~params: Ctx -> Sn.Sound.Source -> U32 & U32, +ctx: Ctx, c: Maybe<Channel>) -> IO(Maybe<Channel>):
  match c:
    case None{}:
      IO.pure(Maybe<Channel>, None{})
    case Some{Chan{file, sfx, +source, left, right}}:
      Channel.moved(Chan{file, sfx, source, left, right}, params(ctx, source))

# S_UpdateSounds follows the current listener and source positions.
def Channel.update(~Ctx: Data, ~params: Ctx -> Sn.Sound.Source -> U32 & U32, +ctx: Ctx, chans: List<Maybe<Channel>>) ->
  IO(List<Maybe<Channel>>):
  match chans:
    case []:
      IO.pure(List<Maybe<Channel>>, [])
    case c <> rest:
      do IO<List<Maybe<Channel>>>:
        moved : Maybe<Channel> <- Channel.update.slot(~Ctx, ~params, ctx, c)
        cs : List<Maybe<Channel>> <- Channel.update(~Ctx, ~params, ctx, rest)
        return moved <> cs

# Every channel's file closed, when the game lets the device go.
def Channel.stop(chans: List<Maybe<Channel>>) -> IO(Unit):
  match chans:
    case []:
      IO.pure(Unit, Unit{})
    case None{} <> rest:
      Channel.stop(rest)
    case Some{Chan{file, sfx, source, left, right}} <> rest:
      do IO<Unit>:
        File.close(file)
        Channel.stop(rest)
