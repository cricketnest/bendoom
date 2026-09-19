# Freedoom's E1M1 from the player 1 start to the exit switch with every
# thing the map spawns: a command script in a demo's units, leg by leg,
# and after each leg the clock, the player, the inventory, how many
# things are left and the records taken since the start. The route:
# east along the walkway south of the pit, over three armour bonuses, to
# the south door; the south room's shells and its lift; the switch whose
# pillars bar the south-east room; the door behind them, and the blue
# key, record 87, strafed past; back over the lift and along the walkway
# to the start's lift, down it into the pit; milestone 4's first door
# and through it; the blue door, sector 71, opening for the key; the
# north room to the second blue door, sector 51; south into the tech
# column, record 59, which holds the player, and a strafe past it;
# milestone 4's last legs, through the exit room's door to the switch.
# Chocolate Doom plays the same script: after every leg its frame is
# ours pixel for pixel, one tic before the exit it still shows the level
# and one tic after it has left, at the same time, and its status bar
# ends with this inventory's health, armour, shells and card (ticket
# 11). The positions are regression pins.
# Then Enter restarts the ended level through the game's frame: every
# thing back as it spawned, the start's inventory, and the first leg
# taking the same records again.
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

# The things alive in both populations are the same things: same type,
# place, heights, facing, sector, state and tics.
def same.thing(m: Maybe<&2, H.Thing>, t: H.Thing) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics}}:
      H.Thing{id2, kind2, x2, y2, z2, floorz2, ceilz2, angle2, sector2, state2, tics2} = t
      List.all(~&2, ~Bool, ~(b => b), [U32.is_eq(id, id2), U32.is_eq(kind, kind2), U32.is_eq(x, x2),
        U32.is_eq(y, y2), U32.is_eq(z, z2), U32.is_eq(floorz, floorz2), U32.is_eq(ceilz, ceilz2),
        U32.is_eq(angle, angle2), U32.is_eq(sector, sector2), U32.is_eq(state, state2), U32.is_eq(tics, tics2)])

def same(things: List<&2, H.Thing>, +in: H.Things) -> Bool:
  match things:
    case []:
      True{}
    case H.Thing{+id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics} <> rest:
      Bool.and(same.thing(H.Things.get(in, id), H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state,
        tics}), same(rest, in))

# The clock, the player, whether the level has ended, the inventory,
# the things left and the names of those gone since the start.
def line(tag: String, +start: S.State, +s: S.State) -> String:
  +p = S.State.player(s)
  +things = S.State.things(s)
  tag ++ " tic " ++ U32.show(S.State.clock(s)) ++ " " ++ F.Fixed.show(S.Player.x(p)) ++ " "
    ++ F.Fixed.show(S.Player.y(p)) ++ " " ++ A.Angle.show(S.Player.angle(p)) ++ " z "
    ++ F.Fixed.show(S.Player.z(p)) ++ " ended " ++ Bool.show(S.State.ended(s)) ++ "\n  "
    ++ I.Inventory.show(S.Player.inv(p)) ++ " things " ++ Nat.show(List.length(&2, H.Thing, H.Things.list(things)))
    ++ " taken" ++ H.Things.gone(H.Things.list(S.State.things(start)), things)

def leg(tag: String, runs: List<&2, List<&2, K.Cmd>>, +start: S.State, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.concat(&2, K.Cmd, runs), s)
  do IO<S.State>:
    IO.print(line(tag, start, q))
    return q

# The last leg, then the time Doom's tally shows.
def finish(tag: String, runs: List<&2, List<&2, K.Cmd>>, +start: S.State, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.concat(&2, K.Cmd, runs), s)
  do IO<S.State>:
    IO.print(line(tag, start, q))
    IO.print(M.Game.time(S.State.clock(q)))
    return q

def south_door() -> List<&2, List<&2, K.Cmd>>:
  [run(20n), turn(4294967264), run(12n), turn(32), run(55n), turn(4294967232), run(25n)]

# The state the game holds after a frame, and whether it matches the
# start's things.
def restarted(+start: S.State, m: Maybe<M.Game>) -> IO(S.State):
  match m:
    case None{}:
      do IO<S.State>:
        IO.print("quit")
        return start
    case Some{M.Game{level, gfx, tables, +state, input, again, last, owed, mem}}:
      do IO<S.State>:
        IO.print(line("restarted", start, state))
        IO.print("  as spawned " ++ Bool.show(same(H.Things.list(S.State.things(start)), S.State.things(state))))
        return state

def route(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (gfx, +level) = gl
  +start = S.State.start(level)
  do IO<Unit>:
    r1 : S.State <- leg("south door", south_door(), start, start)
    r2 : S.State <- leg("shells", [use(), run(34n), idle(12n), turn(64), run(20n), idle(5n), turn(4294967232),
      run(16n), idle(12n), turn(64)], start, r1)
    r3 : S.State <- leg("up the lift", [use(), idle(28n), held(8n, 25, 0, 0, False{}), idle(100n), run(54n),
      idle(14n), turn(64)], start, r2)
    r4 : S.State <- leg("switch", [run(28n), use()], start, r3)
    r5 : S.State <- leg("key door", [held(10n, 4294967246, 0, 0, False{}), idle(10n), turn(4294967232), run(12n),
      idle(20n), turn(64), run(83n)], start, r4)
    r6 : S.State <- leg("key in view", [held(1n, 50, 0, 1, True{}), run(58n), idle(10n), turn(47),
      held(13n, 0, 4294967272, 0, False{})], start, r5)
    r7 : S.State <- leg("key taken", [held(1n, 0, 4294967272, 0, False{})], start, r6)
    r8 : S.State <- leg("back to the south door", [turn(80), run(60n), turn(4294967232), run(71n), idle(30n),
      turn(4294967232), run(34n)], start, r7)
    r9 : S.State <- leg("down the start's lift", [run_use(), run(44n), turn(64), run(51n), idle(20n),
      turn(4294967232), run(9n), idle(26n)], start, r8)
    r10 : S.State <- leg("first door", [turn(4294967246), run(50n), turn(32), run(10n), turn(18), run(12n),
      idle(10n)], start, r9)
    r11 : S.State <- leg("through it", [use(), idle(62n), run(20n)], start, r10)
    r12 : S.State <- leg("blue door opening", [run(47n), run_use(), run(20n)], start, r11)
    r13 : S.State <- leg("second blue door opening", [run(32n), turn(64), run(60n), idle(20n), turn(64), run(15n),
      run_use(), run(20n)], start, r12)
    r14 : S.State <- leg("held by the column", [run(24n)], start, r13)
    r15 : S.State <- leg("past the column", [held(9n, 0, 24, 0, False{}), idle(15n), run(21n)], start, r14)
    r16 : S.State <- leg("exit room", [use(), idle(36n), run(8n), idle(22n)], start, r15)
    r17 : S.State <- leg("exit switch", [turn(4294967232), run(9n), idle(20n)], start, r16)
    r18 : S.State <- finish("exit", [use()], start, r17)
    again : Maybe<M.Game> <- M.Game.frame(0n, [Key{13, True{}}], M.Game{level, gfx, P.Project.tables(level),
      r18, K.Input{K.Keys.none(), 0}, False{}, 0n, 0n, mem})
    s0 : S.State <- restarted(start, again)
    s1 : S.State <- leg("south door again", south_door(), start, s0)
    return Unit{}

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  route(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)
#|south door tic 115 962.669601 -127.949111 270.000 z 0.000000 ended False
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 12 things 177 taken 173 174 175
#|shells tic 218 1247.894851 -438.355468 0.000 z 0.000000 ended False
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 173 taken 173 174 175 207 208 275 276
#|up the lift tic 424 2023.387252 -470.199172 90.000 z 128.000000 ended False
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 173 taken 173 174 175 207 208 275 276
#|switch tic 453 2069.702270 -240.045883 90.000 z 136.000000 ended False
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 173 taken 173 174 175 207 208 275 276
#|key door tic 590 2270.106246 207.540100 90.000 z 144.000000 ended False
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 173 taken 173 174 175 207 208 275 276
#|key in view tic 673 2229.776046 547.120574 157.500 z 136.000000 ended False
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 173 taken 173 174 175 207 208 275 276
#|key taken tic 674 2227.456253 541.591537 157.500 z 136.000000 ended False
#|  inventory health 100 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 12 things 172 taken 87 173 174 175 207 208 275 276
#|back to the south door tic 872 962.605484 -196.101318 90.000 z 0.000000 ended False
#|  inventory health 100 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 172 taken 87 173 174 175 207 208 275 276
#|down the start's lift tic 1025 111.630645 249.612152 90.000 z -80.000000 ended False
#|  inventory health 100 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 172 taken 87 173 174 175 207 208 275 276
#|first door tic 1110 831.989151 490.927688 90.000 z -128.000000 ended False
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|through it tic 1193 840.974288 690.629104 90.000 z -128.000000 ended False
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|blue door opening tic 1261 840.575164 1463.953430 90.000 z -128.000000 ended False
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|second blue door opening tic 1411 -167.239501 1768.048858 270.000 z -128.000000 ended False
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|held by the column tic 1435 -167.141571 1642.360794 270.000 z -128.000000 ended False
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|past the column tic 1480 -237.692794 1416.462036 270.000 z -128.000000 ended False
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|exit room tic 1547 -237.918212 1293.197692 270.000 z -128.000000 ended False
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|exit switch tic 1577 -367.940170 1283.856979 180.000 z -128.000000 ended False
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|exit tic 1578 -367.940170 1283.856979 180.000 z -128.000000 ended True
#|  inventory health 101 armour 3 type 1 cards 1 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 4 flash 0 things 171 taken 87 173 174 175 207 208 264 275 276
#|Time 0:45
#|restarted tic 0 -416.000000 256.000000 0.000 z 0.000000 ended False
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|  as spawned True
#|south door again tic 115 962.669601 -127.949111 270.000 z 0.000000 ended False
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 12 things 177 taken 173 174 175
