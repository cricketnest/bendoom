# Freedoom's E1M1 from the player 1 start to the exit switch with every
# thing the map spawns, monsters among them: a command script in a
# demo's units, leg by leg, and after each leg the clock, the player,
# whether the level has ended, the ceilings of the two blue doors,
# sectors 71 and 51, the inventory, how many things are left and the
# records taken since the start. The route: east along the walkway south
# of the pit, over three armour bonuses, to the south door; past the
# zombieman behind it to the south room's shells and its lift; the
# switch whose pillars bar the south-east room; through the gap its
# monsters leave, east of the imp at 2320, -160, to the door behind them
# and the blue key, record 87, strafed past; back the same way and over
# the lift to the start's lift, down it into the pit; east along the
# pit's south side, south of the two zombiemen who stand in its north
# corner, to milestone 4's first door and through it; up the hall west
# of its two imps to the blue door, shut when the player reaches it and
# opening for the key; the north room to the second blue door, the same;
# south past the tech column, record 59; milestone 4's last legs,
# through the exit room's door and round the north of the shotgun guy
# who stands at the exit switch, which a use at 202.5 degrees reaches
# through the alcove, and the time Doom's tally shows. A standing
# monster is a wall, so the legs that pass one are the ticket's, not
# milestone 5's; vanilla plays them with its monsters awake, so no leg
# is compared with Chocolate Doom until the monsters chase (milestone
# 6's tickets 14 to 16). The positions are regression pins; the doors'
# heights are EV_VerticalDoor's, 2 a tic from -128 on the tic of the
# use.
# Then the tally the exit leads to, with the route's own counts against
# the level's totals, and E1M1's par of 30 seconds. Three presses drive
# it to its end, and eleven tics on the level is playing again from the
# map as loaded, on its first tic. What that level holds is
# tests/game.bend's line, which shows the door shut, the switch's
# special back and every record alive.
import Base
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/things.bend as H
import ../src/inventory.bend as I
import ../src/inter.bend as W

def held(n: Nat, forward: U32, side: U32, turn: U32, buttons: U32) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.demo(forward, side, turn, buttons))

def idle(n: Nat) -> List<&2, K.Cmd>:
  held(n, 0, 0, 0, 0)

def run(n: Nat) -> List<&2, K.Cmd>:
  held(n, 50, 0, 0, 0)

def turn(by: U32) -> List<&2, K.Cmd>:
  held(1n, 0, 0, by, 0)

def use() -> List<&2, K.Cmd>:
  held(1n, 0, 0, 0, 2)

def run_use() -> List<&2, K.Cmd>:
  held(1n, 50, 0, 0, 2)

# The clock, the player, whether the level has ended, the blue doors'
# ceilings, the inventory, the things left and the names of those gone
# since the start.
def line(tag: String, +start: S.State, +s: S.State) -> String:
  +p = S.State.player(s)
  +level = S.State.level(s)
  tag ++ " tic " ++ U32.show(S.State.clock(s)) ++ " " ++ F.Fixed.show(S.Player.x(p)) ++ " "
    ++ F.Fixed.show(S.Player.y(p)) ++ " " ++ A.Angle.show(S.Player.angle(p)) ++ " z "
    ++ F.Fixed.show(S.Player.z(p)) ++ " ended " ++ Bool.show(S.State.ended(s)) ++ " blue doors "
    ++ F.Fixed.show(L.Level.ceil(level, 71)) ++ " " ++ F.Fixed.show(L.Level.ceil(level, 51)) ++ "\n  "
    ++ I.Inventory.show(S.Player.inv(p)) ++ H.Things.tally(H.Things.list(S.State.things(start)),
      S.State.things(s))

def leg(tag: String, runs: List<&2, List<&2, K.Cmd>>, +start: S.State, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.concat(&2, K.Cmd, runs), s)
  do IO<S.State>:
    IO.print(line(tag, start, q))
    return q

def walk(n: Nat) -> List<&2, K.Cmd>:
  held(n, 25, 0, 0, 0)

# Strafing left, away from a monster that stands in the way.
def left(n: Nat) -> List<&2, K.Cmd>:
  held(n, 0, 4294967272, 0, 0)

def right(n: Nat) -> List<&2, K.Cmd>:
  held(n, 0, 24, 0, 0)

def south_door() -> List<&2, List<&2, K.Cmd>>:
  [run(20n), turn(4294967264), run(12n), turn(32), run(55n), turn(4294967232), run(25n)]

# The tally after a run of commands, whose use button is the press
# WI_checkForAccelerate reads.
def tallied(tag: String, +level: L.Level, runs: List<&2, List<&2, K.Cmd>>, play: W.Play) -> IO(W.Play):
  +next = W.Play.replay(List.concat(&2, K.Cmd, runs), level, play)
  do IO<W.Play>:
    IO.print(tag ++ " " ++ W.Play.show(next))
    return next

# The exit's tally driven to its end: a press while the counts climb
# shows them all at once, the next leaves for the screen that names
# E1M2, the third cuts its four seconds to WI_initNoState's ten tics,
# and the tic after those starts E1M1 again from the map as loaded and
# runs its first tic.
def shown(+level: L.Level, play: W.Play) -> IO(W.Play):
  do IO<W.Play>:
    p1 : W.Play <- tallied("tally", level, [idle(40n), use()], play)
    p2 : W.Play <- tallied("entering", level, [idle(1n), use()], p1)
    p3 : W.Play <- tallied("cut short", level, [idle(1n), use()], p2)
    tallied("the level again", level, [idle(11n)], p3)

def after(+level: L.Level, +took: S.State) -> IO(Unit):
  IO.bind(W.Play, Unit, shown(level, W.Play.ended(S.State.ended(took), took)), p => IO.pure(Unit, Unit{}))

def route(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (gfx, +level) = gl
  +start = S.State.start(level)
  do IO<Unit>:
    r1 : S.State <- leg("south door", south_door(), start, start)
    r2 : S.State <- leg("shells", [use(), left(8n), run(26n), turn(64), run(30n), idle(5n), turn(4294967232),
      run(14n), idle(12n), turn(64)], start, r1)
    r3 : S.State <- leg("up the lift", [use(), idle(28n), walk(8n), idle(100n), run(54n),
      idle(14n), turn(64)], start, r2)
    r4 : S.State <- leg("switch", [run(28n), use()], start, r3)
    r5 : S.State <- leg("key door", [held(10n, 4294967246, 0, 0, 0), idle(10n), turn(4294967232), run(12n),
      idle(20n), turn(64), right(14n), idle(25n), run(30n), left(16n), idle(15n), run(30n)], start, r4)
    r6 : S.State <- leg("key in view", [held(1n, 50, 0, 1, 2), run(58n), idle(10n), turn(47),
      left(13n)], start, r5)
    r7 : S.State <- leg("key taken", [left(1n)], start, r6)
    r8 : S.State <- leg("back to the south door", [turn(80), run(44n), left(10n), idle(25n), run(16n), idle(20n),
      turn(4294967232), run(71n), idle(30n), run(12n), idle(20n), turn(4294967232), right(20n), idle(10n), run(30n),
      left(20n), idle(15n)], start, r7)
    r9 : S.State <- leg("down the start's lift", [run_use(), run(44n), turn(64), run(51n), idle(20n),
      turn(4294967232), run(9n), idle(26n)], start, r8)
    r10 : S.State <- leg("across the pit", [turn(4294967232), run(65n), idle(20n), turn(64), run(30n)], start, r9)
    r11 : S.State <- leg("through the first door", [use(), idle(62n), run(20n)], start, r10)
    r12 : S.State <- leg("up the hall", [left(16n), idle(10n), run(47n)], start, r11)
    r13 : S.State <- leg("blue door opening", [right(10n), idle(10n), run_use(), run(20n)], start, r12)
    r14 : S.State <- leg("second blue door", [run(32n), turn(64), run(58n), idle(20n), turn(64), run(15n)], start,
      r13)
    r15 : S.State <- leg("second blue door opening", [run_use(), run(20n)], start, r14)
    r16 : S.State <- leg("past the column", [run(24n)], start, r15)
    r17 : S.State <- leg("down to the exit room", [right(9n), idle(15n), run(21n)], start, r16)
    r18 : S.State <- leg("exit room", [use(), idle(36n), run(8n), idle(22n)], start, r17)
    r19 : S.State <- leg("north of the shotgun guy", [turn(128), walk(6n), idle(8n), turn(64), walk(25n), idle(8n),
      turn(16)], start, r18)
    r20 : S.State <- leg("exit", [use()], start, r19)
    after(level, r20)

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  route(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)
