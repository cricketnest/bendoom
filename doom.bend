# Bendoom. The WAD named by BENDOOM_IWAD loads, then a window opens on a
# blank frame; Esc or Close quits.
import Base
import ./src/bytes.bend as B
import ./src/wad.bend as W

type Game is Data:
  Game{lumps: List<&2, W.Wad.Lump>}

def Game.view(g: Game) -> Game & Image:
  (g, Pix{4653056})

def Game.event(e: Event, g: Game) -> Maybe<Game>:
  match e:
    case Key{27, True{}}:
      None{}
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

def Game.tick(events: List<Event>, g: Game) -> IO(Maybe<Game>):
  IO.pure(Maybe<Game>, Game.events(events, g))

def Game.start(p: Array<U32> & List<&2, W.Wad.Lump>) -> IO(Unit):
  (bytes, +lumps) = p
  do IO<Unit>:
    IO.print("Bendoom: " ++ Nat.show(List.length(&2, W.Wad.Lump, lumps))
      ++ " lumps")
    App.run(~Game, ~App{Game.view, Game.tick}, "Bendoom", 640, 400,
      Game{lumps})

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    Game.start(W.Wad.dir(bytes))
