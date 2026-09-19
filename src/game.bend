# The game's state and its frame loop: each frame draws the latest tic's
# state, shows it, folds the frame's key events into the held keys, and
# runs the tics the clock owes. The game runs it without end; the window
# bench runs it for a count of frames.
import Base
import ./level.bend as L
import ./gfx.bend as G
import ./keys.bend as K
import ./sim.bend as S
import ./project.bend as P
import ./render.bend as R
import ./show.bend as V
import ./demo.bend as D

# The clock is read each frame; the tics it owes accumulate in
# thousandths of a tic, and at most eight run per frame, the rest
# forgiven, so a stall cannot snowball. The array is the frame and the
# graphics, redrawn each frame from the latest tic's state, so an ended
# level holds its last frame. The level is the map as loaded, which a
# fresh state is built from. Again is whether Space or Enter is down.
# The demo is the one being recorded, until the level ends.
type Game is Type:
  Game{level: L.Level, gfx: G.Gfx, tables: P.Project.Tables, state: S.State, input: K.Input,
    again: Bool, last: Nat, owed: Nat, mem: Array<U32>, demo: Maybe<D.Demo.Rec>}

def Game.shown(level: L.Level, gfx: G.Gfx, tables: P.Project.Tables, state: S.State, input: K.Input,
  again: Bool, last: Nat, owed: Nat, demo: Maybe<D.Demo.Rec>, p: Array<U32> & Image) -> Game & Image:
  (mem, image) = p
  (Game{level, gfx, tables, state, input, again, last, owed, mem, demo}, image)

def Game.view(g: Game) -> Game & Image:
  Game{level, +gfx, +tables, +state, input, again, last, owed, mem, demo} = g
  Game.shown(level, gfx, tables, state, input, again, last, owed, demo,
    V.Show.image(R.Render.frame(tables, gfx, state, mem)))

def Game.key(+code: U32, +down: Bool, g: Game) -> Game:
  Game{level, gfx, tables, state, input, again, last, owed, mem, demo} = g
  Game{level, gfx, tables, state, K.Input.press(code, down, input),
    K.Keys.set(U32.is_eq(code, 32) || U32.is_eq(code, 13), down, again), last, owed, mem, demo}

def Game.quit(p: Bool & Game) -> Bool & Game:
  (quit, g) = p
  (True{}, g)

def Game.press(+code: U32, +down: Bool, p: Bool & Game) -> Bool & Game:
  (quit, g) = p
  (quit, Game.key(code, down, g))

# The frame's events folded in, and whether one of them quits.
def Game.event(e: Event, p: Bool & Game) -> Bool & Game:
  match e:
    case Key{27, True{}}:
      Game.quit(p)
    case Key{code, down}:
      Game.press(code, down, p)
    case Close{}:
      Game.quit(p)
    case _:
      p

def Game.events(events: List<Event>, p: Bool & Game) -> Bool & Game:
  match events:
    case []:
      p
    case e <> rest:
      Game.events(rest, Game.event(e, p))

def Game.owed(capped: Bool, due: Nat) -> Nat:
  match capped:
    case True{}:
      0n
    case False{}:
      Nat.mod(due, 1000n)

# The level's time as Doom's tally counts it: the clock over 35, in
# minutes and seconds.
def Game.time(+clock: U32) -> String:
  +seconds = (clock / 35 % 60 : U32)
  "Time " ++ U32.show((clock / 2100 : U32)) ++ Bool.pick(String, U32.is_lt(seconds, 10), ":0", ":")
    ++ U32.show(seconds)

# The frame whose tics ended the level prints the time and ends the
# demo.
def Game.ended(ending: Bool, clock: U32, demo: Maybe<D.Demo.Rec>) -> IO(Maybe<D.Demo.Rec>):
  match ending:
    case True{}:
      do IO<Maybe<D.Demo.Rec>>:
        IO.print(Game.time(clock))
        D.Demo.stop(demo)
        return None{}
    case False{}:
      IO.pure(Maybe<D.Demo.Rec>, demo)

def Game.advanced(+from: S.State, played: Maybe<D.Demo.Rec> & List<&2, K.Cmd>, level: L.Level, gfx: G.Gfx,
  tables: P.Project.Tables, input: K.Input, again: Bool, last: Nat, owed: Nat, mem: Array<U32>) ->
  IO(Maybe<Game>):
  (demo, cmds) = played
  +next = S.Sim.replay(cmds, from)
  do IO<Maybe<Game>>:
    kept : Maybe<D.Demo.Rec> <- Game.ended(Bool.and(S.State.ended(next), Bool.not(S.State.ended(from))),
      S.State.clock(next), demo)
    return Some{Game{level, gfx, tables, next, input, again, last, owed, mem, kept}}

# After the exit a press of Space or Enter starts the level again, from
# the map as loaded. A match and not a pick, which would build the fresh
# state every frame.
def Game.from(again: Bool, +level: L.Level, state: S.State) -> S.State:
  match again:
    case True{}:
      S.State.start(level)
    case False{}:
      state

# The sim runs the tics the clock owes since the last frame, each on the
# command built from the held keys, as the demo holds it. A press is a
# key down now that was up a frame ago: a held key repeats as a release
# and a press within one frame's events, or as presses alone, and
# neither is one.
def Game.advance(+now: Nat, was: Bool, g: Game) -> IO(Maybe<Game>):
  Game{+level, gfx, tables, +state, +input, +again, last, owed, mem, demo} = g
  +due = Nat.add(owed, Nat.mul(Nat.sub(now, last), 35n))
  +capped = Nat.is_gt(Nat.div(due, 1000n), 8n)
  +tics = Bool.pick(Nat, capped, 8n, Nat.div(due, 1000n))
  +from = Game.from(Bool.and(Bool.and(again, Bool.not(was)), S.State.ended(state)), level, state)
  do IO<Maybe<Game>>:
    played : Maybe<D.Demo.Rec> & List<&2, K.Cmd> <- D.Demo.record(demo, K.Input.script(tics, input))
    Game.advanced(from, played, level, gfx, tables, K.Input.after(tics, input), again, now,
      Game.owed(capped, due), mem)

# Quitting ends the demo.
def Game.step(quit: Bool, now: Nat, was: Bool, g: Game) -> IO(Maybe<Game>):
  match quit:
    case True{}:
      Game{level, gfx, tables, state, input, again, last, owed, mem, demo} = g
      do IO<Maybe<Game>>:
        D.Demo.stop(demo)
        return None{}
    case False{}:
      Game.advance(now, was, g)

def Game.stepped(now: Nat, was: Bool, p: Bool & Game) -> IO(Maybe<Game>):
  (quit, g) = p
  Game.step(quit, now, was, g)

# A frame of the loop at a time: the events folded in, then the tics.
def Game.frame(now: Nat, events: List<Event>, g: Game) -> IO(Maybe<Game>):
  Game{level, gfx, tables, state, input, +again, last, owed, mem, demo} = g
  Game.stepped(now, again, Game.events(events, (False{}, Game{level, gfx, tables, state, input, again, last,
    owed, mem, demo})))

def Game.tick(events: List<Event>, g: Game) -> IO(Maybe<Game>):
  do IO<Maybe<Game>>:
    now : Nat <- IO.now()
    Game.frame(now, events, g)

def Game.turn(shown: Window & Image & List<Event>, g: Game,
  rest: Window -> Game -> IO(Unit)) -> IO(Unit):
  (window, image, events) = shown
  IO.bind(Maybe<Game>, Unit, Game.tick(events, g), App.next(Game, window, rest))

def Game.draw(window: Window, drawn: Game & Image, rest: Window -> Game -> IO(Unit)) ->
  IO(Unit):
  (g, image) = drawn
  do IO<Unit>:
    shown : Window & Image & List<Event> <- Window.frame(window, image)
    Game.turn(shown, g, rest)

# Base's App.run drops each frame on the GPU lane, which makes the
# binary compile for the GPU at launch; this loop draws the same way
# without it.
def Game.loop(fuel: Nat, window: Window, g: Game) -> IO(Unit):
  match fuel:
    case 0n:
      Window.close(window)
    case 1n+f:
      Game.draw(window, Game.view(g), w => h => Game.loop(f, w, h))

def Game.start.go(frames: Nat, input: K.Input, script: List<&2, K.Cmd>, demo: Maybe<D.Demo.Rec>, now: Nat,
  mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  do IO<Unit>:
    window : Window <- IO.try(Window, Window.open("Bendoom", 1280, 960))
    Game.loop(frames, window, Game{level, gfx, P.Project.tables(level),
      S.Sim.replay(script, S.State.start(level)), input, False{}, now, 0n, mem, demo})

# The window opened and the loop run for at most so many frames, from
# the player 1 start after a script, with the given input at first,
# recording the demo if one is open.
def Game.start(frames: Nat, input: K.Input, script: List<&2, K.Cmd>, demo: Maybe<D.Demo.Rec>, now: Nat,
  world: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = world
  Game.start.go(frames, input, script, demo, now, mem, gl)
