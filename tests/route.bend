# A non-firing walk through Freedoom E1M1 with all monsters active.
# It reaches the south rooms but is blocked before the blue key.
# Each leg prints the player, doors, inventory and remaining things.
# The final tic 717 frame matches Chocolate Doom at zero differing
# pixels. Ticket 25 replaces this partial walk with surviving combat
# routes through both maps and the exit.
import Base
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/things.bend as H
import ../src/inventory.bend as I

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

def route(gl: G.Gfx & L.Level) -> IO(Unit):
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
    r6 : S.State <- leg("key approach", [held(1n, 50, 0, 1, 2), run(58n), idle(10n), turn(47),
      left(13n)], start, r5)
    +r7 : S.State <- leg("approach blocked", [left(1n)], start, r6)
    return Unit{}

def start(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  route(gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    start(world)

#|south door tic 115 962.669601 -127.949111 270.000 z 0.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 12 things 206 taken 173 174 175
#|shells tic 214 1247.599700 -444.203857 0.000 z 0.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 100 armour 3 type 1 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 202 taken 173 174 175 207 208 275 276
#|up the lift tic 420 2037.208175 -461.687759 90.000 z 128.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 85 armour 0 type 0 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 202 taken 173 174 175 207 208 275 276
#|switch tic 449 2083.213745 -272.046646 90.000 z 136.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 85 armour 0 type 0 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 205 taken 173 174 175 207 208 275 276
#|key door tic 633 2222.810943 -48.032348 90.000 z 144.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 41 armour 0 type 0 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 200 taken 141 173 174 175 197 199 207 208 275 276
#|key approach tic 716 2184.314605 -85.488708 157.500 z 136.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 32 armour 0 type 0 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 201 taken 141 173 174 175 197 199 207 208 275 276
#|approach blocked tic 717 2182.186035 -90.502609 157.500 z 136.000000 ended False blue doors -128.000000 -128.000000
#|  inventory health 32 armour 0 type 0 cards 0 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 3 flash 0 things 201 taken 141 173 174 175 197 199 207 208 275 276
