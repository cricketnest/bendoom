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

# The clock is read each frame; the tics it owes accumulate in
# thousandths of a tic, and at most eight run per frame, the rest
# forgiven, so a stall cannot snowball. The array is the frame and the
# graphics, redrawn each frame from the latest tic's state. The level is
# the map as loaded, which a fresh state is built from.
type Game is Type:
  Game{level: L.Level, gfx: G.Gfx, tables: P.Project.Tables, state: S.State, input: K.Input,
    last: Nat, owed: Nat, mem: Array<U32>}

def Game.shown(level: L.Level, gfx: G.Gfx, tables: P.Project.Tables, state: S.State, input: K.Input,
  last: Nat, owed: Nat, p: Array<U32> & Image) -> Game & Image:
  (mem, image) = p
  (Game{level, gfx, tables, state, input, last, owed, mem}, image)

def Game.view(g: Game) -> Game & Image:
  Game{level, +gfx, +tables, +state, input, last, owed, mem} = g
  Game.shown(level, gfx, tables, state, input, last, owed,
    V.Show.image(R.Render.frame(tables, gfx, state, mem)))

def Game.event(e: Event, g: Game) -> Maybe<Game>:
  match e:
    case Key{27, True{}}:
      None{}
    case Key{code, down}:
      Game{level, gfx, tables, state, input, last, owed, mem} = g
      Some{Game{level, gfx, tables, state, K.Input.press(code, down, input), last, owed, mem}}
    case Close{}:
      None{}
    case _:
      Some{g}

def Game.events(events: List<Event>, g: Game) -> Maybe<Game>:
  match events:
    case []:
      Some{g}
    case e <> rest:
      Maybe.bind(&1, Game, Game, Game.event(e, g), h => Game.events(rest, h))

def Game.owed(capped: Bool, due: Nat) -> Nat:
  match capped:
    case True{}:
      0n
    case False{}:
      Nat.mod(due, 1000n)

# The sim runs the tics the clock owes since the last frame, each on the
# command built from the held keys.
def Game.advance(+now: Nat, g: Game) -> Game:
  Game{level, gfx, tables, state, +input, last, owed, mem} = g
  +due = Nat.add(owed, Nat.mul(Nat.sub(now, last), 35n))
  +capped = Nat.is_gt(Nat.div(due, 1000n), 8n)
  +tics = Bool.pick(Nat, capped, 8n, Nat.div(due, 1000n))
  Game{level, gfx, tables, S.Sim.replay(K.Input.script(tics, input), state),
    K.Input.after(tics, input), now, Game.owed(capped, due), mem}

def Game.step(now: Nat, m: Maybe<Game>) -> Maybe<Game>:
  match m:
    case None{}:
      None{}
    case Some{g}:
      Some{Game.advance(now, g)}

def Game.tick(events: List<Event>, g: Game) -> IO(Maybe<Game>):
  do IO<Maybe<Game>>:
    now : Nat <- IO.now()
    return Game.step(now, Game.events(events, g))

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

def Game.start.go(frames: Nat, input: K.Input, now: Nat, mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  do IO<Unit>:
    window : Window <- IO.try(Window, Window.open("Bendoom", 1280, 960))
    Game.loop(frames, window, Game{level, gfx, P.Project.tables(level),
      S.State.start(level), input, now, 0n, mem})

# The window opened and the loop run from the player 1 start for at most
# so many frames, with the given input at first.
def Game.start(frames: Nat, input: K.Input, now: Nat, world: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = world
  Game.start.go(frames, input, now, mem, gl)

