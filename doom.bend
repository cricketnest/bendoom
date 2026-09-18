# Bendoom. The WAD named by BENDOOM_IWAD loads, E1M1 opens in a window
# as a top-down view, and the keyboard walks the player at Doom's 35
# tics a second whatever the frame rate; Esc or Close quits.
import Base
import ./src/bytes.bend as B
import ./src/wad.bend as W
import ./src/level.bend as L
import ./src/keys.bend as K
import ./src/sim.bend as S
import ./src/view.bend as V

# The clock is read each frame; the tics it owes accumulate in
# thousandths of a tic, and at most eight run per frame, the rest
# forgiven, so a stall cannot snowball.
type Game is Data:
  Game{level: L.Level, player: S.Player, keys: K.Keys, last: Nat, owed: Nat}

def Game.view(g: Game) -> Game & Image:
  Game{+level, +player, keys, last, owed} = g
  (Game{level, player, keys, last, owed}, V.View.frame(level, player))

def Game.event(e: Event, g: Game) -> Maybe<Game>:
  match e:
    case Key{27, True{}}:
      None{}
    case Key{code, down}:
      Game{level, player, keys, last, owed} = g
      Some{Game{level, player, K.Keys.press(code, down, keys), last, owed}}
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

# The sim runs the tics the clock owes since the last frame.
def Game.advance(+now: Nat, g: Game) -> Game:
  Game{+level, player, +keys, last, owed} = g
  +due = Nat.add(owed, Nat.mul(Nat.sub(now, last), 35n))
  +capped = Nat.is_gt(Nat.div(due, 1000n), 8n)
  Game{level, S.Sim.run(Bool.pick(Nat, capped, 8n, Nat.div(due, 1000n)), level, keys, player),
    keys, now, Game.owed(capped, due)}

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
  do IO<Unit>:
    Unit <- IO.pure(Unit, Image.drop(image))
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

def Game.start(now: Nat, p: Array<U32> & L.Level) -> IO(Unit):
  (bytes, +level) = p
  do IO<Unit>:
    window : Window <- IO.try(Window, Window.open("Bendoom", 1280, 800))
    Game.loop(U32.to_nat(4294967295), window,
      Game{level, S.Player.start(level), K.Keys.none(), now, 0n})

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    now : Nat <- IO.now()
    Game.start(now, L.Level.load(W.Wad.dir(bytes)))
