# Freedoom's E1M1 from the player 1 start to the exit switch with every
# thing the map spawns: a command script in a demo's units, leg by leg,
# and after each leg the clock, the player, whether the level has ended,
# the ceilings of the two blue doors, sectors 71 and 51, the inventory,
# how many things are left and the records taken since the start. The
# route: east along the walkway south of the pit, over three armour
# bonuses, to the south door; the south room's shells and its lift; the
# switch whose pillars bar the south-east room; the door behind them,
# and the blue key, record 87, strafed past; back over the lift and
# along the walkway to the start's lift, down it into the pit;
# milestone 4's first door and through it; the blue door, shut when the
# player reaches it and opening for the key; the north room to the
# second blue door, the same; south into the tech column, record 59,
# which holds the player, and a strafe past it; milestone 4's last legs,
# through the exit room's door to the switch. Chocolate Doom plays the
# same script: after every leg its frame is ours pixel for pixel, one
# tic before the exit it still shows the level and one tic after it has
# left, at the same time, and its status bar ends with this inventory's
# health, armour, shells and card (ticket 11). The positions are
# regression pins; the doors' heights are EV_VerticalDoor's, 2 a tic
# from -128 on the tic of the use.
# Then the tally the exit leads to, with the route's own counts: 4 of
# the level's 49 items, 8 per cent; 1 of its 4 secrets, which the route
# enters on its way, 25 per cent; 45 seconds of its 1578 tics against
# E1M1's par of 30; and no kills, since no monster spawns yet. Three
# presses drive it to its end, and eleven tics on, the level is playing
# again from the map as loaded, on its first tic. What that level holds
# is tests/game.bend's line, which shows the door shut, the switch's
# special back and all 180 records alive.
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

def held(n: Nat, forward: U32, side: U32, turn: U32, use: Bool) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd.demo(forward, side, turn, use))

def idle(n: Nat) -> List<&2, K.Cmd>:
  held(n, 0, 0, 0, False{})

def run(n: Nat) -> List<&2, K.Cmd>:
  held(n, 50, 0, 0, False{})

def turn(by: U32) -> List<&2, K.Cmd>:
  held(1n, 0, 0, by, False{})

def use() -> List<&2, K.Cmd>:
  held(1n, 0, 0, 0, True{})

def run_use() -> List<&2, K.Cmd>:
  held(1n, 50, 0, 0, True{})

# The clock, the player, whether the level has ended, the blue doors'
# ceilings, the inventory, the things left and the names of those gone
# since the level's first population.
def line(tag: String, +first: List<&2, H.Thing>, +s: S.State) -> String:
  +p = S.State.player(s)
  +level = S.State.level(s)
  tag ++ " tic " ++ U32.show(S.State.clock(s)) ++ " " ++ F.Fixed.show(S.Player.x(p)) ++ " "
    ++ F.Fixed.show(S.Player.y(p)) ++ " " ++ A.Angle.show(S.Player.angle(p)) ++ " z "
    ++ F.Fixed.show(S.Player.z(p)) ++ " ended " ++ Bool.show(S.State.ended(s)) ++ " blue doors "
    ++ F.Fixed.show(L.Level.ceil(level, 71)) ++ " " ++ F.Fixed.show(L.Level.ceil(level, 51)) ++ "\n  "
    ++ I.Inventory.show(S.Player.inv(p)) ++ H.Things.tally(first, S.State.things(s))

def leg(tag: String, runs: List<&2, List<&2, K.Cmd>>, +first: List<&2, H.Thing>, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.concat(&2, K.Cmd, runs), s)
  do IO<S.State>:
    IO.print(line(tag, first, q))
    return q

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

# The pit, the two blue doors and the exit, then the tally and the
# level it starts again.
def dug(+level: L.Level, +first: List<&2, H.Thing>, r9: S.State) -> IO(Unit):
  do IO<Unit>:
    r10 : S.State <- leg("first door", [turn(4294967246), run(50n), turn(32), run(10n), turn(18), run(12n),
      idle(10n)], first, r9)
    r11 : S.State <- leg("through it", [use(), idle(62n), run(20n)], first, r10)
    r12 : S.State <- leg("blue door", [run(47n)], first, r11)
    r13 : S.State <- leg("blue door opening", [run_use(), run(20n)], first, r12)
    r14 : S.State <- leg("second blue door", [run(32n), turn(64), run(60n), idle(20n), turn(64), run(15n)], first,
      r13)
    r15 : S.State <- leg("second blue door opening", [run_use(), run(20n)], first, r14)
    r16 : S.State <- leg("held by the column", [run(24n)], first, r15)
    r17 : S.State <- leg("past the column", [held(9n, 0, 24, 0, False{}), idle(15n), run(21n)], first, r16)
    r18 : S.State <- leg("exit room", [use(), idle(36n), run(8n), idle(22n)], first, r17)
    r19 : S.State <- leg("exit switch", [turn(4294967232), run(9n), idle(20n)], first, r18)
    r20 : S.State <- leg("exit", [use()], first, r19)
    after(level, r20)

def route(gl: G.Gfx & L.Level) -> IO(Unit):
  (gfx, +level) = gl
  +start = S.State.start(level)
  +first = H.Things.list(S.State.things(start))
  do IO<Unit>:
    r1 : S.State <- leg("south door", south_door(), first, start)
    r2 : S.State <- leg("shells", [use(), run(34n), idle(12n), turn(64), run(20n), idle(5n), turn(4294967232),
      run(16n), idle(12n), turn(64)], first, r1)
    r3 : S.State <- leg("up the lift", [use(), idle(28n), held(8n, 25, 0, 0, False{}), idle(100n), run(54n),
      idle(14n), turn(64)], first, r2)
    r4 : S.State <- leg("switch", [run(28n), use()], first, r3)
    r5 : S.State <- leg("key door", [held(10n, 4294967246, 0, 0, False{}), idle(10n), turn(4294967232), run(12n),
      idle(20n), turn(64), run(83n)], first, r4)
    r6 : S.State <- leg("key in view", [held(1n, 50, 0, 1, True{}), run(58n), idle(10n), turn(47),
      held(13n, 0, 4294967272, 0, False{})], first, r5)
    r7 : S.State <- leg("key taken", [held(1n, 0, 4294967272, 0, False{})], first, r6)
    r8 : S.State <- leg("back to the south door", [turn(80), run(60n), turn(4294967232), run(71n), idle(30n),
      turn(4294967232), run(34n)], first, r7)
    r9 : S.State <- leg("down the start's lift", [run_use(), run(44n), turn(64), run(51n), idle(20n),
      turn(4294967232), run(9n), idle(26n)], first, r8)
    dug(level, first, r9)

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  route(gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)
#|south door tic 115 962.669601 -127.949111 270.000 z 0.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 12 kills 0 secrets 0 things 177 taken 173 174 175
#|shells tic 218 1247.894851 -438.355468 0.000 z 0.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 kills 0 secrets 0 things 173 taken 173 174 175 207 208 275 276
#|up the lift tic 424 2023.387252 -470.199172 90.000 z 128.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 kills 0 secrets 0 things 173 taken 173 174 175 207 208 275 276
#|switch tic 453 2069.702270 -240.045883 90.000 z 136.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 kills 0 secrets 0 things 173 taken 173 174 175 207 208 275 276
#|key door tic 590 2270.106246 207.540100 90.000 z 144.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 kills 0 secrets 0 things 173 taken 173 174 175 207 208 275 276
#|key in view tic 673 2229.776046 547.120574 157.500 z 136.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 kills 0 secrets 0 things 173 taken 173 174 175 207 208 275 276
#|key taken tic 674 2227.456253 541.591537 157.500 z 136.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 12 kills 0 secrets 0 things 172 taken 87 173 174 175 207 208 275 276
#|back to the south door tic 872 962.605484 -196.101318 90.000 z 0.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 kills 0 secrets 0 things 172 taken 87 173 174 175 207 208 275 276
#|down the start's lift tic 1025 111.630645 249.612152 90.000 z -80.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 kills 0 secrets 0 things 172 taken 87 173 174 175 207 208 275 276
#|first door tic 1110 831.989151 490.927688 90.000 z -128.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 kills 0 secrets 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|through it tic 1193 840.974288 690.629104 90.000 z -128.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 kills 0 secrets 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|blue door tic 1240 840.674407 1451.668579 90.000 z -128.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 kills 0 secrets 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|blue door opening tic 1261 840.575164 1463.953430 90.000 z -128.000000 ended False blue doors -86.000000 -128.000000
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 kills 0 secrets 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|second blue door tic 1390 -165.933990 1776.355072 270.000 z -128.000000 ended False blue doors -4.000000 -128.000000
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 kills 0 secrets 1 things 171 taken 87 173 174 175 207 208 264 275 276
#|second blue door opening tic 1411 -167.239501 1768.048858 270.000 z -128.000000 ended False blue doors -4.000000 -86.000000
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 kills 0 secrets 1 things 171 taken 87 173 174 175 207 208 264 275 276
#|held by the column tic 1435 -167.141571 1642.360794 270.000 z -128.000000 ended False blue doors -4.000000 -38.000000
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 kills 0 secrets 1 things 171 taken 87 173 174 175 207 208 264 275 276
#|past the column tic 1480 -237.692794 1416.462036 270.000 z -128.000000 ended False blue doors -58.000000 -4.000000
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 kills 0 secrets 1 things 171 taken 87 173 174 175 207 208 264 275 276
#|exit room tic 1547 -237.918212 1293.197692 270.000 z -128.000000 ended False blue doors -128.000000 -4.000000
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 kills 0 secrets 1 things 171 taken 87 173 174 175 207 208 264 275 276
#|exit switch tic 1577 -367.940170 1283.856979 180.000 z -128.000000 ended False blue doors -128.000000 -4.000000
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 kills 0 secrets 1 things 171 taken 87 173 174 175 207 208 264 275 276
#|exit tic 1578 -367.940170 1283.856979 180.000 z -128.000000 ended True blue doors -128.000000 -4.000000
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 kills 0 secrets 1 things 171 taken 87 173 174 175 207 208 264 275 276
#|tally tally count 10 cnt 31 bcnt 41 shown 0 8 25 45 30 anims 0 0 2 2 2 2 2 0 0 0 random 149
#|entering tally next cnt 140 bcnt 43 shown 0 8 25 45 30 anims - - - - - - - - - - random 159
#|cut short tally done cnt 10 bcnt 45 shown 0 8 25 45 30 anims - - - - - - - - - - random 159
#|the level again level tic 1
