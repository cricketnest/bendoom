# The game's frame, from the WAD named by BENDOOM_IWAD: a clock reading
# and the frame's key events in, the state and what it prints out. No
# window opens. Each line is the clock, whether the level has ended, the
# player, the thinkers running, the floor and ceiling of sector 64 (the
# exit room's door), line 407's special (the exit switch, 11 as loaded),
# whether its side shows the switch's partner, how many things there
# are, the random index, and the cards held.
# First the state the game starts with. Then a game handed the state
# a script leaves beside Freedoom's exit switch with the room's door
# open behind the player, 50 tics in. A frame 200 ms on with Space
# pressed runs 7 tics: the first ends the level and the rest change
# nothing, and the frame prints the time, 51 tics, a second. A held
# Space repeating, as X sends it, a release and a press in one frame,
# restarts nothing, nor does its release; a press of Enter does,
# and with no time gone the state is the one the game started with:
# the door shut, the switch's special back, the things and the random
# index as they spawned. Then the game is handed the state 21 tics of
# walking into the blue key leave, the level ended there: with Enter let
# go and pressed again, the key is back and the card gone. Esc quits.
# Then the time of a few clocks, worked out by hand in milestone 4's
# ticket 09. The door's height is the hand computation's (4 under
# sector 68's ceiling of -56); the positions are regression pins.
import Base
import ../src/vec.bend as V
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/things.bend as H
import ../src/inventory.bend as I
import ../src/project.bend as P
import ../src/game.bend as M

def pressed(+level: L.Level, sidetex: V.Vec) -> Bool:
  U32.is_eq(V.Vec.get(sidetex, (615 * 3 + 2 : U32)),
    L.Level.switch(level, V.Vec.get(L.Level.sidetex(level), (615 * 3 + 2 : U32))))

def line(tag: String, +s: S.State) -> String:
  +p = S.State.player(s)
  +level = S.State.level(s)
  tag ++ " tic " ++ U32.show(S.State.clock(s)) ++ " ended " ++ Bool.show(S.State.ended(s)) ++ " at "
    ++ F.Fixed.show(S.Player.x(p)) ++ " " ++ F.Fixed.show(S.Player.y(p)) ++ " " ++ A.Angle.show(S.Player.angle(p))
    ++ " thinkers " ++ Nat.show(List.length(&2, S.Thinker, S.State.thinkers(s))) ++ " sector 64 "
    ++ F.Fixed.show(L.Level.floor(level, 64)) ++ " " ++ F.Fixed.show(L.Level.ceil(level, 64)) ++ " special "
    ++ U32.show(L.Level.special(level, 407)) ++ " pressed " ++ Bool.show(pressed(level, S.State.sidetex(s)))
    ++ " things " ++ Nat.show(List.length(&2, H.Thing, H.Things.list(S.State.things(s)))) ++ " random "
    ++ U32.show(S.State.rnd(s))
    ++ " cards " ++ U32.show(I.Inventory.cards(S.Player.inv(p)))

def told(tag: String, +state: S.State, g: M.Game) -> IO(Maybe<M.Game>):
  do IO<Maybe<M.Game>>:
    IO.print(line(tag, state))
    return Some{g}

def report(tag: String, m: Maybe<M.Game>) -> IO(Maybe<M.Game>):
  match m:
    case None{}:
      do IO<Maybe<M.Game>>:
        IO.print(tag ++ " quit")
        return None{}
    case Some{M.Game{level, gfx, tables, +state, input, again, last, owed, mem}}:
      told(tag, state, M.Game{level, gfx, tables, state, input, again, last, owed, mem})

# The game handed a state at a time.
def handed(state: S.State, now: Nat, m: Maybe<M.Game>) -> Maybe<M.Game>:
  match m:
    case None{}:
      None{}
    case Some{M.Game{level, gfx, tables, old, input, again, last, owed, mem}}:
      Some{M.Game{level, gfx, tables, state, input, again, now, owed, mem}}

# A frame of the game, then its state's line; a game that has quit stays
# quit.
def frame(tag: String, now: Nat, events: List<Event>, m: Maybe<M.Game>) -> IO(Maybe<M.Game>):
  match m:
    case None{}:
      IO.pure(Maybe<M.Game>, None{})
    case Some{g}:
      IO.bind(Maybe<M.Game>, Maybe<M.Game>, M.Game.frame(now, events, g), after => report(tag, after))

# The exit room's door used from inside, then the walk to the switch.
def route() -> List<&2, K.Cmd>:
  List.concat(&2, K.Cmd, [List.replicate(K.Cmd, 5n, K.Cmd.idle()), [K.Cmd.demo(0, 0, 0, True{})],
    [K.Cmd.demo(0, 0, 96, False{})], List.replicate(K.Cmd, 12n, K.Cmd.demo(25, 0, 0, False{})),
    [K.Cmd.demo(0, 0, 224, False{})], List.replicate(K.Cmd, 20n, K.Cmd.demo(25, 0, 0, False{})),
    List.replicate(K.Cmd, 10n, K.Cmd.idle())])

def play(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (gfx, +level) = gl
  +beside = S.Sim.replay(route(), S.State.at(level, L.Start{F.Fixed.neg(F.Fixed.of_map(224)), F.Fixed.of_map(1340),
    A.Angle.of_thing(90)}))
  do IO<Unit>:
    IO.print(line("start", S.State.start(level)))
    IO.print(line("beside", beside))
    g1 : Maybe<M.Game> <- frame("space", 200n, [Key{32, True{}}], Some{M.Game{level, gfx,
      P.Project.tables(level), beside, K.Input{K.Keys.none(), 0}, False{}, 0n, 0n, mem}})
    g2 : Maybe<M.Game> <- frame("repeat", 400n, [Key{32, False{}}, Key{32, True{}}], g1)
    g3 : Maybe<M.Game> <- frame("release", 600n, [Key{32, False{}}], g2)
    g4 : Maybe<M.Game> <- frame("enter", 600n, [Key{13, True{}}], g3)
    g5 : Maybe<M.Game> <- frame("key taken, ended", 1000n, [Key{13, False{}}], handed(S.State.end(S.Sim.replay(
      List.replicate(K.Cmd, 21n, K.Cmd.demo(25, 0, 0, False{})), S.State.at(level, L.Start{F.Fixed.of_map(2192),
      F.Fixed.of_map(440), A.Angle.of_thing(90)}))), 1000n, g4))
    g6 : Maybe<M.Game> <- frame("enter", 1000n, [Key{13, True{}}], g5)
    g7 : Maybe<M.Game> <- frame("esc", 1200n, [Key{27, True{}}], g6)
    IO.print(M.Game.time(21) ++ ", " ++ M.Game.time(2099) ++ ", " ++ M.Game.time(2100) ++ ", " ++ M.Game.time(4321))

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  play(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)

#|start tic 0 ended False at -416.000000 256.000000 0.000 thinkers 9 sector 64 -128.000000 -128.000000 special 11 pressed False things 180 random 1 cards 0
#|beside tic 50 ended False at -367.958084 1282.988662 180.000 thinkers 10 sector 64 -128.000000 -60.000000 special 11 pressed False things 180 random 5 cards 0
#|Time 0:01
#|space tic 51 ended True at -367.958084 1283.156616 180.000 thinkers 10 sector 64 -128.000000 -60.000000 special 0 pressed True things 180 random 5 cards 0
#|repeat tic 51 ended True at -367.958084 1283.156616 180.000 thinkers 10 sector 64 -128.000000 -60.000000 special 0 pressed True things 180 random 5 cards 0
#|release tic 51 ended True at -367.958084 1283.156616 180.000 thinkers 10 sector 64 -128.000000 -60.000000 special 0 pressed True things 180 random 5 cards 0
#|enter tic 0 ended False at -416.000000 256.000000 0.000 thinkers 9 sector 64 -128.000000 -128.000000 special 11 pressed False things 180 random 1 cards 0
#|key taken, ended tic 21 ended True at 2191.958206 544.634552 90.000 thinkers 9 sector 64 -128.000000 -128.000000 special 11 pressed False things 179 random 5 cards 1
#|enter tic 0 ended False at -416.000000 256.000000 0.000 thinkers 9 sector 64 -128.000000 -128.000000 special 11 pressed False things 180 random 1 cards 0
#|esc quit
#|Time 0:00, Time 0:59, Time 1:00, Time 2:03
