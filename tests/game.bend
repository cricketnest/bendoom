# The game's frame, from the WAD named by BENDOOM_IWAD: a clock reading
# and the frame's key events in, the play and what it prints out. No
# window opens. A level's line is the clock, whether the level has
# ended, the player, the thinkers running that are no mobj's, the floor
# and ceiling of sector 64 (the exit room's door), line 407's special
# (the exit switch, 11 as loaded), whether its side shows the switch's
# partner, how many things there are and the random index. The tally's
# line is its screen and counts.
# First the state the game starts with. Then a game handed the state a
# script leaves beside Freedoom's exit switch with the room's door open
# behind the player, 41 tics in. Every frame 200 ms on runs 7 tics. The
# first, with Space pressed, ends the level on its first tic and shows
# the tally for the six after it; Space held through the exit does not
# skip the tally's first pause, since WI_checkForAccelerate finds the
# player's usedown flag already set, and neither does a held Space
# repeating, as X sends it, a release and a press in one frame. A press
# of Enter once Space is released shows every count at once, the next
# press leaves for the screen that names E1M2, and the third cuts its
# four seconds to WI_initNoState's ten tics; four tics later they are
# up, and the tic after that starts E1M1 again from the map as loaded,
# the door shut, the switch's special back, and the things and the
# random index as they spawned. Esc quits.
# Before the game, what a tic of use beside the switch is heard to
# start, and M_Random's index after it. P_ChangeSwitchTexture clears the
# line's special before it looks for the exit's 11, so the click is
# sfx_swtchn, and it comes from nobody, since no button runs. The index
# is 64 after the wipe, one more for the route's door, one for the
# click.
# The door's height is milestone 4's hand computation (4 under sector
# 68's ceiling of -56); the positions are regression pins.
import Base
import ../src/vec.bend as V
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/things.bend as H
import ../src/inter.bend as W
import ../src/project.bend as P
import ../src/game.bend as M
import ../src/sound.bend as Sn

def pressed(+level: L.Level, sidetex: V.Vec) -> Bool:
  U32.is_eq(V.Vec.get(sidetex, (615 * 3 + 2 : U32)),
    L.Level.switch(level, V.Vec.get(L.Level.sidetex(level), (615 * 3 + 2 : U32))))

# How many thinkers are not mobjs': the lights, movers and buttons.
def specials(ts: List<&2, S.Thinker>) -> U32:
  match ts:
    case []:
      0
    case S.Mobj{id} <> rest:
      specials(rest)
    case _ <> rest:
      (1 + specials(rest) : U32)

def line(tag: String, +s: S.State) -> String:
  +p = S.State.player(s)
  +level = S.State.level(s)
  tag ++ " tic " ++ U32.show(S.State.clock(s)) ++ " ended " ++ Bool.show(S.State.ended(s)) ++ " at "
    ++ F.Fixed.show(S.Player.x(p)) ++ " " ++ F.Fixed.show(S.Player.y(p)) ++ " " ++ A.Angle.show(S.Player.angle(p))
    ++ " thinkers " ++ U32.show(specials(S.State.thinkers(s))) ++ " sector 64 "
    ++ F.Fixed.show(L.Level.floor(level, 64)) ++ " " ++ F.Fixed.show(L.Level.ceil(level, 64)) ++ " special "
    ++ U32.show(L.Level.special(level, 407)) ++ " pressed " ++ Bool.show(pressed(level, S.State.sidetex(s)))
    ++ " things " ++ Nat.show(List.length(&2, H.Thing, H.Things.list(S.State.things(s)))) ++ " random "
    ++ U32.show(S.State.rnd(s))

# A level's line, or the tally's, whichever the play is showing.
def played(tag: String, play: W.Play) -> String:
  match play:
    case W.Playing{+state}:
      line(tag, state)
    case W.Showing{+wi}:
      tag ++ " tally " ++ W.Inter.show(wi)

def heard(es: List<&2, Sn.Sound.Event>) -> String:
  match es:
    case []:
      ""
    case e <> rest:
      " " ++ Sn.Sound.Event.show(e) ++ heard(rest)

def clicked(+s: S.State) -> String:
  "use heard" ++ heard(S.State.sounds(s)) ++ " drew to " ++ U32.show(S.State.mrnd(s))

def told(tag: String, +play: W.Play, g: M.Game) -> IO(Maybe<M.Game>):
  do IO<Maybe<M.Game>>:
    IO.print(played(tag, play))
    return Some{g}

def reported(quit: Bool, tag: String, g: M.Game) -> IO(Maybe<M.Game>):
  match quit:
    case True{}:
      do IO<Maybe<M.Game>>:
        IO.print(tag ++ " quit")
        return None{}
    case False{}:
      M.Game{level, gfx, tables, +play, input, again, last, owed, mem, demo, music} = g
      told(tag, play, M.Game{level, gfx, tables, play, input, again, last, owed, mem, demo, music})

def report(tag: String, p: Bool & M.Game) -> IO(Maybe<M.Game>):
  (quit, g) = p
  reported(quit, tag, g)

# A frame of the game, then its play's line; a game that has quit stays
# quit.
def frame(tag: String, now: Nat, events: List<Event>, m: Maybe<M.Game>) -> IO(Maybe<M.Game>):
  match m:
    case None{}:
      IO.pure(Maybe<M.Game>, None{})
    case Some{g}:
      IO.bind(Bool & M.Game, Maybe<M.Game>, M.Game.frame(now, events, g), after => report(tag, after))

# The exit room's door used from inside, then the walk west to the
# switch, which passes north of the shotgun guy of record 289 and turns
# to 202.5 degrees, where the use reaches through the alcove past him.
def route() -> List<&2, K.Cmd>:
  List.concat(&2, K.Cmd, [List.replicate(K.Cmd, 5n, K.Cmd.idle()), [K.Cmd.demo(0, 0, 0, 2)],
    [K.Cmd.demo(0, 0, 64, 0)], List.replicate(K.Cmd, 25n, K.Cmd.demo(25, 0, 0, 0)),
    List.replicate(K.Cmd, 8n, K.Cmd.idle()), [K.Cmd.demo(0, 0, 16, 0)]])

def play(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (gfx, +level) = gl
  +beside = S.Sim.replay(route(), S.State.at(level, L.Start{F.Fixed.neg(F.Fixed.of_map(224)), F.Fixed.of_map(1340),
    A.Angle.of_thing(90)}))
  do IO<Unit>:
    IO.print(line("start", S.State.start(level)))
    IO.print(line("beside", beside))
    IO.print(clicked(S.Sim.tic(K.Cmd.demo(0, 0, 0, 2), beside)))
    g1 : Maybe<M.Game> <- frame("space", 200n, [Key{32, True{}}], Some{M.Game{level, gfx,
      P.Project.tables(level), W.Playing{beside}, K.Input{K.Keys.none(), 0}, False{}, 0n, 0n, mem, None{},
      None{}}})
    g2 : Maybe<M.Game> <- frame("repeat", 400n, [Key{32, False{}}, Key{32, True{}}], g1)
    g3 : Maybe<M.Game> <- frame("release", 600n, [Key{32, False{}}], g2)
    g4 : Maybe<M.Game> <- frame("enter", 800n, [Key{13, True{}}], g3)
    g5 : Maybe<M.Game> <- frame("held", 1000n, [], g4)
    g6 : Maybe<M.Game> <- frame("let go", 1200n, [Key{13, False{}}], g5)
    g7 : Maybe<M.Game> <- frame("space again", 1400n, [Key{32, True{}}], g6)
    g8 : Maybe<M.Game> <- frame("let go again", 1600n, [Key{32, False{}}], g7)
    g9 : Maybe<M.Game> <- frame("last press", 1800n, [Key{32, True{}}], g8)
    ga : Maybe<M.Game> <- frame("the level again", 2000n, [Key{32, False{}}], g9)
    gb : Maybe<M.Game> <- frame("esc", 2200n, [Key{27, True{}}], ga)
    return Unit{}

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  play(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)
