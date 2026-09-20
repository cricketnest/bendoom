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
# Then Enter restarts the ended level through the game's frame: every
# record the route took alive again in its spawn state with its spawn
# tics (a nushell replay of P_SpawnMapThing's random draws over
# Chocolate Doom's rndtable; the rows are the types' spawn rows), the
# start's inventory, and the first leg taking the same records again.
import Base
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

# A record the route took, as the restart left it: its state row and
# tics, or missing.
def restored.one(m: Maybe<&2, H.Thing>, +id: U32) -> String:
  match m:
    case None{}:
      " " ++ U32.show(id) ++ ":missing"
    case Some{H.Thing{i, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz}}:
      " " ++ U32.show(id) ++ ":" ++ U32.show(state) ++ "/" ++ U32.show(tics)

def restored.pick(taken: Maybe<&2, H.Thing>, again: Maybe<&2, H.Thing>, +id: U32, rest: String) -> String:
  match taken:
    case None{}:
      restored.one(again, id) ++ rest
    case Some{_}:
      rest

# The records of the start gone at the end, each as the restart left it.
def restored(first: List<&2, H.Thing>, +ended: H.Things, +again: H.Things) -> String:
  match first:
    case []:
      ""
    case H.Thing{+id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics, momz} <> rest:
      restored.pick(H.Things.get(ended, id), H.Things.get(again, id), id, restored(rest, ended, again))

# The state the game holds after a frame, and the records the route
# took as it left them.
def restarted(+start: S.State, +ended: H.Things, p: Bool & M.Game) -> IO(S.State):
  (quit, g) = p
  M.Game{level, gfx, tables, +state, input, again, last, owed, mem, demo, music} = g
  do IO<S.State>:
    IO.print(line("restarted", start, state))
    IO.print("  restored" ++ restored(H.Things.list(S.State.things(start)), ended, S.State.things(state)))
    return state

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
    +r20 : S.State <- leg("exit", [use()], start, r19)
    IO.print(M.Game.time(S.State.clock(r20)))
    again : Bool & M.Game <- M.Game.frame(0n, [Key{13, True{}}], M.Game{level, gfx, P.Project.tables(level),
      r20, K.Input{K.Keys.none(), 0}, False{}, 0n, 0n, mem, None{}, None{}})
    s0 : S.State <- restarted(start, S.State.things(r20), again)
    s1 : S.State <- leg("south door again", south_door(), start, s0)
    return Unit{}

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  route(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)
#|south door tic 115 962.669601 -127.949111 270.000 z 0.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 12 things 206 taken 173 174 175
#|shells tic 214 1247.599700 -444.203857 0.000 z 0.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 202 taken 173 174 175 207 208 275 276
#|up the lift tic 420 2023.386245 -477.488250 90.000 z 128.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 202 taken 173 174 175 207 208 275 276
#|switch tic 449 2068.889968 -240.045425 90.000 z 136.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 202 taken 173 174 175 207 208 275 276
#|key door tic 633 2255.727050 207.953338 90.000 z 144.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 202 taken 173 174 175 207 208 275 276
#|key in view tic 716 2214.982116 547.119750 157.500 z 136.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 6 things 201 taken 87 173 174 175 207 208 275 276
#|key taken tic 717 2212.662307 541.590713 157.500 z 136.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 5 things 201 taken 87 173 174 175 207 208 275 276
#|back to the south door tic 1063 1002.826705 -208.103546 90.000 z 0.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 201 taken 87 173 174 175 207 208 275 276
#|down the start's lift tic 1216 142.952011 249.610488 90.000 z -80.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 201 taken 87 173 174 175 207 208 275 276
#|across the pit tic 1333 879.763671 495.953460 90.000 z -128.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 104 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 7 flash 0 things 197 taken 87 173 174 175 207 208 264 266 267 268 275 276
#|through the first door tic 1416 879.682632 690.665908 90.000 z -128.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 104 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 7 flash 0 things 197 taken 87 173 174 175 207 208 264 266 267 268 275 276
#|up the hall tic 1489 751.602676 1452.906021 90.000 z -128.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 104 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 7 flash 0 things 197 taken 87 173 174 175 207 208 264 266 267 268 275 276
#|blue door opening tic 1530 817.178512 1463.954269 90.000 z -128.000000 ended False blue doors -86.000000 -128.000000
#|  inventory health 104 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 7 flash 0 things 197 taken 87 173 174 175 207 208 264 266 267 268 275 276
#|second blue door tic 1657 -155.902389 1776.364929 270.000 z -128.000000 ended False blue doors -4.000000 -128.000000
#|  inventory health 104 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 7 flash 0 things 197 taken 87 173 174 175 207 208 264 266 267 268 275 276
#|second blue door opening tic 1678 -157.202484 1768.048950 270.000 z -128.000000 ended False blue doors -4.000000 -86.000000
#|  inventory health 104 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 7 flash 0 things 197 taken 87 173 174 175 207 208 264 266 267 268 275 276
#|past the column tic 1702 -157.103637 1615.604217 270.000 z -128.000000 ended False blue doors -4.000000 -38.000000
#|  inventory health 104 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 7 flash 0 things 197 taken 87 173 174 175 207 208 264 266 267 268 275 276
#|down to the exit room tic 1747 -221.368881 1416.049224 270.000 z -128.000000 ended False blue doors -54.000000 -4.000000
#|  inventory health 104 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 7 flash 0 things 197 taken 87 173 174 175 207 208 264 266 267 268 275 276
#|exit room tic 1814 -221.344802 1292.784881 270.000 z -128.000000 ended False blue doors -128.000000 -4.000000
#|  inventory health 104 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 7 flash 0 things 197 taken 87 173 174 175 207 208 264 266 267 268 275 276
#|north of the shotgun guy tic 1864 -356.707733 1321.859512 202.500 z -128.000000 ended False blue doors -128.000000 -4.000000
#|  inventory health 104 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 7 flash 0 things 197 taken 87 173 174 175 207 208 264 266 267 268 275 276
#|exit tic 1865 -357.216613 1321.414047 202.500 z -128.000000 ended True blue doors -128.000000 -4.000000
#|  inventory health 104 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 7 flash 0 things 197 taken 87 173 174 175 207 208 264 266 267 268 275 276
#|Time 0:53
#|restarted tic 0 -416.000000 256.000000 0.000 z 0.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 209 taken
#|  restored 87:24/1 173:18/5 174:18/4 175:18/1 207:41/4294967295 208:41/4294967295 264:12/6 266:12/3 267:12/1 268:12/3 275:41/4294967295 276:41/4294967295
#|south door again tic 115 962.669601 -127.949111 270.000 z 0.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 12 things 206 taken 173 174 175
