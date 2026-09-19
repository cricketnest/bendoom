# E1M1 from the WAD named by BENDOOM_IWAD, loaded by the game's loader,
# and scripted runs through the game's step. First two walks from the
# player 1 start, the position, facing, height, floor and eye above the
# floor after each run of held keys (U up, D down, L left, R right, A
# strafe left, S strafe right, ! run): the first turns on the lift its
# run called and rides it into the pit; the second runs across that
# lift and off its east edge into the fall and the landing. Freedoom's
# first map is not id's: the shareware start is 1056, -3616 facing 90.
# The start's things, as a nushell replay of P_SpawnMapThing over the
# THINGS records, info.c and m_random.c finds them on Hurt Me Plenty with
# no monsters: how many, the random index once they and the three flashes
# have drawn, how many of each type Bendoom defines, the names of the
# first twelve (records 0, 1, 4 and 5 are for the easy skills, 3 is a
# monster and 7 for multiplayer), and six records: the first, animated
# armour, a leg hung from its ceiling, the blue key, the dead former
# sergeant and the last, each with the sector under it (tools/wad.nu's
# sector-at), its z, its facing (its record's angle), its state row,
# its tics and its definition. The blockmap's links against that
# population: 180 links for 180 things, 79 of them solid (the solid
# types' counts in ticket 02's nushell inventory), none at another
# place, type or cell than its thing's, and no thing missing from the
# cell of its centre. The player's inventory, G_PlayerReborn's.
# Then the pickups, each run printed with the tic, the player's place,
# the inventory, the things left and the records taken since the case
# began: a clip, three shells in a row and the rocket walked into, with
# room and at the cap; the shell box behind the closet door west of the
# clips, with room, one clip short of the cap and at it; the chainsaw
# on its step, strafed past on the key's script, not owned and owned;
# then a health, armour or berserk pickup of each type Freedoom's E1M1
# spawns, walked at alone from 80 short, holding the start's inventory
# or one with other health or armour: the tic before contact, 41.61
# short, and the tic of it, 35.84 short, inside the reach of 36. The
# grants are Chocolate Doom's P_TouchSpecialThing, P_GiveBody,
# P_GiveArmor, P_GivePower, P_GiveAmmo and P_GiveWeapon on Hurt Me
# Plenty: clipammo 10 4 20 1, five clips in a box, maxammo 200 50 300
# 50, a flash of 6; the chainsaw is owned, weapons 3 to 131; the health
# bonus makes 101 and counts, and at 200 is taken for nothing; the
# stimpack and medikit stay at 100 health, walked across or not, and
# heal 60 to 70 and 85; the berserk pack counts, heals 60 to 100, and
# its strength counts up from 1 on the tic after, 11 ten tics on; the
# armour bonus makes 1 point of type 1 and counts; green armour makes
# 100 of type 1 and stays for 100. Every contact tic, where the reach of
# 36 is first met, is a regression pin.
# Then the movers and the lights, as runs of one command in a demo's
# units from a place, each line with the clock, the thinkers running
# and chosen sectors' floors and ceilings: the first door used, turned
# twice, held, walked through and closed on the player; the special 23
# switch; a special 2 line crossed both ways; the lift called by its
# line and by its switch; the blue key taken, and its door, sector 71,
# opening for the blue skull alone; the exit switch; the blinks and the
# strobe from the start. The heights and tics are the hand computations
# in milestone 4's tickets 04 to 10; the blinks' lights, a nushell
# replay of T_LightFlash over Chocolate Doom's random table from index
# 254, which from index 2 gives ticket 01's; the positions are
# regression pins. The key's tic is P_TouchSpecialThing's reach, its
# radius 20 and the player's 16: tic 33 leaves the player 37.79 east of
# it, tic 34 35.58 east and 28.51 south, the tic Chocolate Doom's status
# bar first shows the card on the same script; P_GiveCard's flash of 6
# and the pickup's 6 make 12, one less a tic after. Door 71's top is 4
# under the ceilings of 0 beside it in the WAD, reached at 2 a tic on
# tic 92. Between the exit and the lights, from the start to tic 36, the
# state row and tics of a lasting chainsaw, the armour, the blue key, a
# barrel, an armour bonus, a health bonus and the twitching impaled
# body: a nushell replay of P_MobjThinker over info.c's states from the
# spawn's tics, the rows numbered in info.c's order.
# Last, on a copy of the map with three monster records rewritten, solid
# things stop the player and movers, and carried things ride them, as
# solids says; and the blue key door refuses a use, a blue card is taken
# and the door then opens, in one replay, as locked says.
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/sim.bend as S
import ../src/things.bend as H
import ../src/inventory.bend as I
import ../src/vec.bend as V

def line(tag: String, s: S.State) -> String:
  +p = S.State.player(s)
  tag ++ " " ++ F.Fixed.show(S.Player.x(p)) ++ " " ++ F.Fixed.show(S.Player.y(p)) ++ " "
    ++ A.Angle.show(S.Player.angle(p)) ++ " z " ++ F.Fixed.show(S.Player.z(p))
    ++ " floor " ++ F.Fixed.show(S.Player.floorz(p))
    ++ " eye " ++ F.Fixed.show((S.Player.viewz(p) - S.Player.floorz(p) : U32))

def step(tag: String, n: Nat, keys: K.Keys, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(K.Input.script(n, K.Input{keys, 0}), s)
  do IO<S.State>:
    IO.print(line(tag, q))
    return q

def heights(sectors: List<&2, U32>, +level: L.Level) -> String:
  match sectors:
    case []:
      ""
    case +sector <> rest:
      " sector " ++ U32.show(sector) ++ " " ++ F.Fixed.show(L.Level.floor(level, sector)) ++ " "
        ++ F.Fixed.show(L.Level.ceil(level, sector)) ++ heights(rest, level)

# A run of one command in a demo's units, then the clock, the player,
# the thinkers running, and some sectors' floors and ceilings.
def watch(tag: String, sectors: List<&2, U32>, +s: S.State) -> String:
  line(tag ++ " tic " ++ U32.show(S.State.clock(s)), s) ++ " thinkers "
    ++ Nat.show(List.length(&2, S.Thinker, S.State.thinkers(s))) ++ heights(sectors, S.State.level(s))

def run(tag: String, n: Nat, cmd: K.Cmd, sectors: List<&2, U32>, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.replicate(K.Cmd, n, cmd), s)
  do IO<S.State>:
    IO.print(watch(tag, sectors, q))
    return q

def idle() -> K.Cmd:
  K.Cmd.idle()

def use() -> K.Cmd:
  K.Cmd.demo(0, 0, 0, True{})

def forward() -> K.Cmd:
  K.Cmd.demo(25, 0, 0, False{})

def at(+level: L.Level, x: U32, y: U32, degrees: U32) -> S.State:
  S.State.at(level, L.Start{F.Fixed.of_map(x), F.Fixed.of_map(y), A.Angle.of_thing(degrees)})

# Freedoom's special 23 switch, line 753: its tag's three blocks lower
# at 1 a tic to the lowest floor around each, and it works once.
def floors(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    f0 : S.State <- run("switch walk", 30n, forward(), [76, 126, 129], at(level, 2064, 65276, 90))
    f1 : S.State <- run("use", 1n, use(), [76, 126, 129], f0)
    f2 : S.State <- run("-", 119n, idle(), [76, 126, 129], f1)
    f3 : S.State <- run("-", 1n, idle(), [76, 126, 129], f2)
    f4 : S.State <- run("-", 7n, idle(), [76, 126, 129], f3)
    f5 : S.State <- run("-", 1n, idle(), [76, 126, 129], f4)
    f6 : S.State <- run("-", 7n, idle(), [76, 126, 129], f5)
    f7 : S.State <- run("-", 1n, idle(), [76, 126, 129], f6)
    f8 : S.State <- run("use", 1n, use(), [76, 126, 129], f7)
    IO.print("-")

# Freedoom's special 2 lines along x 2032: crossing one opens sector 145
# for good, and crossing it again starts nothing.
def crossed(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    x0 : S.State <- run("trigger walk", 16n, forward(), [145], at(level, 1960, 65086, 0))
    x1 : S.State <- run("over", 1n, forward(), [145], x0)
    x2 : S.State <- run("-", 61n, idle(), [145], x1)
    x3 : S.State <- run("-", 1n, idle(), [145], x2)
    x4 : S.State <- run("back", 40n, K.Cmd.demo(4294967271, 0, 0, False{}), [145], x3)
    IO.print("-")

# Freedoom's first lift, sector 98: called by the walk-over line on its
# west edge and ridden down and up, then called by its switch from the
# pit east of it, used again while it runs, and again once it is back.
def lift(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    l0 : S.State <- run("lift run", 35n, K.Cmd.demo(50, 0, 0, False{}), [98], S.State.start(level))
    l1 : S.State <- run("-", 4n, idle(), [98], l0)
    l2 : S.State <- run("over", 1n, idle(), [98], l1)
    l3 : S.State <- run("-", 33n, idle(), [98], l2)
    l4 : S.State <- run("-", 1n, idle(), [98], l3)
    l5 : S.State <- run("-", 105n, idle(), [98], l4)
    l6 : S.State <- run("-", 1n, idle(), [98], l5)
    l7 : S.State <- run("-", 33n, idle(), [98], l6)
    l8 : S.State <- run("-", 1n, idle(), [98], l7)
    s0 : S.State <- run("lift switch walk", 10n, forward(), [98], at(level, 240, 256, 180))
    s1 : S.State <- run("use", 1n, use(), [98], s0)
    s2 : S.State <- run("-", 1n, idle(), [98], s1)
    s3 : S.State <- run("use", 1n, use(), [98], s2)
    s4 : S.State <- run("-", 171n, idle(), [98], s3)
    s5 : S.State <- run("-", 1n, idle(), [98], s4)
    s6 : S.State <- run("use", 1n, use(), [98], s5)
    IO.print("-")

# A run, then the blue key door's heights, whether the blue card of
# record id is there, how many things are, and the cards and pickup
# flash.
def keyed(tag: String, +id: U32, n: Nat, cmd: K.Cmd, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.replicate(K.Cmd, n, cmd), s)
  +inv = S.Player.inv(S.State.player(q))
  do IO<S.State>:
    IO.print(watch(tag, [71], q) ++ " key " ++ Bool.show(Maybe.is_some(&2, H.Thing, H.Things.get(S.State.things(q), id)))
      ++ " things " ++ Nat.show(List.length(&2, H.Thing, H.Things.list(S.State.things(q)))) ++ " cards "
      ++ U32.show(I.Inventory.cards(inv)) ++ " flash " ++ U32.show(I.Inventory.bonus(inv)))
    return q

# The state with the player holding an inventory.
def holding(inv: I.Inventory, s: S.State) -> S.State:
  S.State{p, level, things, sidetex, thinkers, rnd, clock, ended, usedown} = s
  S.State{S.Player.holding(p, inv), level, things, sidetex, thinkers, rnd, clock, ended, usedown}

# The blue key, record 87, taken strafing past it, the oracle's script:
# 20 idle tics, a turn to 157.5, strafing left. Then the blue key door,
# sector 71, used from the south by a player holding the blue skull
# alone.
def blue(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    k0 : S.State <- keyed("key turn", 87, 1n, K.Cmd.demo(0, 0, 4294967280, False{}),
      S.Sim.replay(List.replicate(K.Cmd, 20n, idle()), at(level, 2246, 592, 180)))
    k1 : S.State <- keyed("strafe", 87, 12n, K.Cmd.demo(0, 4294967272, 0, False{}), k0)
    k2 : S.State <- keyed("-", 87, 1n, K.Cmd.demo(0, 4294967272, 0, False{}), k1)
    k3 : S.State <- keyed("-", 87, 10n, K.Cmd.demo(0, 4294967272, 0, False{}), k2)
    b0 : S.State <- keyed("blue walk with the skull", 87, 30n, forward(),
      holding(I.Inventory.card(8, I.Inventory.start()), at(level, 832, 1400, 90)))
    b1 : S.State <- keyed("use", 87, 1n, use(), b0)
    b2 : S.State <- keyed("-", 87, 10n, idle(), b1)
    b3 : S.State <- keyed("-", 87, 51n, idle(), b2)
    IO.print("-")

# A run, then whether the level has ended and the exit line's special.
def ending(tag: String, n: Nat, cmd: K.Cmd, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.replicate(K.Cmd, n, cmd), s)
  do IO<S.State>:
    IO.print(watch(tag, [], q) ++ " ended " ++ Bool.show(S.State.ended(q)) ++ " special "
      ++ U32.show(L.Level.special(S.State.level(q), 407)))
    return q

def exits(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    x0 : S.State <- ending("exit first tic use", 1n, use(), at(level, 65184, 1296, 180))
    x1 : S.State <- ending("-", 19n, idle(), x0)
    x2 : S.State <- ending("use", 1n, use(), x1)
    x3 : S.State <- ending("walk held use", 10n, K.Cmd.demo(25, 0, 0, True{}), x2)
    IO.print("-")

def lit(sectors: List<&2, U32>, +level: L.Level) -> String:
  match sectors:
    case []:
      ""
    case +sector <> rest:
      " sector " ++ U32.show(sector) ++ " " ++ U32.show(L.Level.sector.light(level, sector)) ++ lit(rest, level)

# The lights of four sectors after each run of idle tics.
def lights(gaps: List<&2, Nat>, +s: S.State) -> IO(Unit):
  match gaps:
    case []:
      IO.print("end")
    case n <> rest:
      do IO<Unit>:
        IO.print("lights tic " ++ U32.show(S.State.clock(s)) ++ lit([32, 33, 48, 90], S.State.level(s)))
        lights(rest, S.Sim.replay(List.replicate(K.Cmd, n, idle()), s))

# The state row and tics of a thing, none for one gone.
def phase(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      ""
    case Some{H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics}}:
      " " ++ U32.show(id) ++ ":" ++ U32.show(state) ++ "/" ++ U32.show(tics)

def phases(ids: List<&2, U32>, +things: H.Things) -> String:
  match ids:
    case []:
      ""
    case +id <> rest:
      phase(H.Things.get(things, id)) ++ phases(rest, things)

# Seven things' states after each run of idle tics.
def states(gaps: List<&2, Nat>, +s: S.State) -> IO(Unit):
  match gaps:
    case []:
      IO.pure(Unit, Unit{})
    case n <> rest:
      do IO<Unit>:
        IO.print("states tic " ++ U32.show(S.State.clock(s)) ++ phases([2, 6, 87, 24, 121, 144, 172],
          S.State.things(s)))
        states(rest, S.Sim.replay(List.replicate(K.Cmd, n, idle()), s))

# A use while the door closes sends it back up; one while it waits
# starts it down.
def turned(+closing: S.State) -> IO(Unit):
  do IO<Unit>:
    r1 : S.State <- run("closing -", 10n, idle(), [10], closing)
    r2 : S.State <- run("use", 1n, use(), [10], r1)
    r3 : S.State <- run("-", 10n, idle(), [10], r2)
    r4 : S.State <- run("-", 4n, idle(), [10], r3)
    r5 : S.State <- run("use", 1n, use(), [10], r4)
    IO.print("-")

def closes(+open: S.State) -> IO(S.State):
  do IO<S.State>:
    d4 : S.State <- run("-", 1n, idle(), [10], open)
    d5 : S.State <- run("-", 150n, idle(), [10], d4)
    run("-", 1n, idle(), [10], d5)

def shuts(+closing: S.State) -> IO(Unit):
  do IO<Unit>:
    d7 : S.State <- run("-", 61n, idle(), [10], closing)
    d8 : S.State <- run("-", 1n, idle(), [10], d7)
    turned(closing)

def opens(+open: S.State) -> IO(Unit):
  do IO<Unit>:
    closing : S.State <- closes(open)
    shuts(closing)
    w1 : S.State <- run("through walk", 40n, forward(), [10], open)
    c1 : S.State <- run("doorway walk", 6n, forward(), [10], open)
    c2 : S.State <- run("-", 179n, idle(), [10], c1)
    c3 : S.State <- run("-", 1n, idle(), [10], c2)
    c4 : S.State <- run("-", 1n, idle(), [10], c3)
    c5 : S.State <- run("-", 34n, idle(), [10], c4)
    IO.print("-")

# The first door, sector 10, from the pit south of it: used, held open,
# shut; turned twice; use held down all the while; walked through.
def used(+before: S.State) -> IO(Unit):
  do IO<Unit>:
    d1 : S.State <- run("use", 1n, use(), [10], before)
    d2 : S.State <- run("-", 20n, idle(), [10], d1)
    d3 : S.State <- run("-", 41n, idle(), [10], d2)
    opens(d3)
    h1 : S.State <- run("held use", 100n, use(), [10], before)
    h2 : S.State <- run("use", 200n, use(), [10], h1)
    IO.print("-")

# A thing's type, height, floor and ceiling, state and tics, none for
# one gone.
def bounded(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      ""
    case Some{H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics}}:
      " thing " ++ U32.show(id) ++ " type " ++ U32.show(kind) ++ " z " ++ F.Fixed.show(z) ++ " floor "
        ++ F.Fixed.show(floorz) ++ " ceiling " ++ F.Fixed.show(ceilz) ++ " state " ++ U32.show(state) ++ " tics "
        ++ U32.show(tics)

# A run, then some sectors' floors and ceilings and the thing named id.
def carry(tag: String, n: Nat, cmd: K.Cmd, sectors: List<&2, U32>, +id: U32, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.replicate(K.Cmd, n, cmd), s)
  do IO<S.State>:
    IO.print(watch(tag, sectors, q) ++ bounded(H.Things.get(S.State.things(q), id)))
    return q

def patch.word(a: Array<U32>, +at: U32, +w: U32) -> Array<U32>:
  Array.set(U32, Array.set(U32, a, at, (w .&. 255 : U32)), (at + 1 : U32), (w >> 8n : U32))

# THINGS record i made a thing of a type at (x, y) in map units, on
# every skill, in the WAD's bytes, whose E1M1 THINGS lump starts at pos.
def patch.record(a: Array<U32>, +pos: U32, i: U32, x: U32, y: U32, kind: U32) -> Array<U32>:
  +at = (pos + i * 10 : U32)
  patch.word(patch.word(patch.word(patch.word(patch.word(a, at, x), (at + 2 : U32), y), (at + 4 : U32), 0),
    (at + 6 : U32), kind), (at + 8 : U32), 7)

def patch.at(a: Array<U32>, +lumps: List<&2, W.Wad.Lump>, lump: U32 & U32) -> Array<U32> & L.Level:
  (+pos, size) = lump
  L.Level.load((patch.record(patch.record(patch.record(a, pos, 3, 96, 216, 48), pos, 35, 800, 528, 2035), pos, 82,
    824, 1352, 5), lumps))

# E1M1 with records 3, 35 and 82, monsters neither game spawns, made a
# tech column on the first lift, a barrel in the first door and a second
# blue card in the hall south of the blue key door, as tools/oracle.nu's
# --things "3,48,96,216 35,2035,800,528 82,5,824,1352" has them: each
# spawns as the map's other things do, drawing its random numbers in
# record order.
def patched(p: Array<U32> & List<&2, W.Wad.Lump>) -> Array<U32> & L.Level:
  (a, +lumps) = p
  patch.at(a, lumps, L.Level.lump(L.Level.map(lumps), "THINGS"))

# The solid things, after 20 idle tics as the oracle's scripts start.
# Walking south at 25 from 1712 under the tech column at -192, 1600,
# record 59, radius 16: tic 37 leaves the player 35.78 north of it, and
# tic 38's step of 6.92, the free walk's, would bring it to 28.86, under
# the 32 of the two radii, so the player stays, tic after tic. From 432
# over the dead former human at 128, 384, record 171, which is not
# solid, the player walks the free walk the column walk began with,
# 432 less its distance, over the corpse's box by tic 30 and on. A tech
# column, radius 16, at 96, 216 on the lift, sector 98, as record 3 of
# the patched map: the lift's switch from the pit starts it down 4 a
# tic, and the column's height, floor and ceiling are the lift's floor
# and ceiling on every tic, its name, type, lasting state (row 58, S_ELEC)
# and tics kept, down to -124 and back to 12. A barrel, radius 10, height 42, at 800, 528 inside the first
# door, sector 10, as record 35, where it does not fit under the
# shut door: the door opens over it as on nothing, and when it closes,
# the barrel under its ceiling, the tic it would leave 40 of the
# barrel's 42 is undone at -86, tic 295, and the door goes back up.
# Meanwhile the barrel runs S_BAR1 (row 10) and S_BAR2 (row 11), 6 tics
# each, from the 3 its spawn drew: the next row on tic 3 and every 6
# tics after.
def solids(+level: L.Level, +placed: L.Level) -> IO(Unit):
  do IO<Unit>:
    c0 : S.State <- run("column walk", 17n, forward(), [],
      S.Sim.replay(List.replicate(K.Cmd, 20n, idle()), at(level, 65344, 1712, 270)))
    c1 : S.State <- run("-", 1n, forward(), [], c0)
    c2 : S.State <- run("-", 10n, forward(), [], c1)
    k0 : S.State <- run("corpse walk", 10n, forward(), [],
      S.Sim.replay(List.replicate(K.Cmd, 20n, idle()), at(level, 128, 432, 270)))
    k1 : S.State <- run("-", 8n, forward(), [], k0)
    l0 : S.State <- carry("column lift switch walk", 10n, forward(), [98], 3,
      at(placed, 240, 256, 180))
    l1 : S.State <- carry("use", 1n, use(), [98], 3, l0)
    l2 : S.State <- carry("-", 1n, idle(), [98], 3, l1)
    l3 : S.State <- carry("-", 32n, idle(), [98], 3, l2)
    l4 : S.State <- carry("-", 1n, idle(), [98], 3, l3)
    l5 : S.State <- carry("-", 105n, idle(), [98], 3, l4)
    l6 : S.State <- carry("-", 34n, idle(), [98], 3, l5)
    b0 : S.State <- carry("barrel door walk", 40n, forward(), [10], 35,
      at(placed, 832, 384, 90))
    b1 : S.State <- carry("use", 1n, use(), [10], 35, b0)
    b2 : S.State <- carry("-", 61n, idle(), [10], 35, b1)
    b3 : S.State <- carry("-", 192n, idle(), [10], 35, b2)
    b4 : S.State <- carry("-", 1n, idle(), [10], 35, b3)
    b5 : S.State <- carry("-", 1n, idle(), [10], 35, b4)
    b6 : S.State <- carry("-", 1n, idle(), [10], 35, b5)
    b7 : S.State <- carry("-", 4n, idle(), [10], 35, b6)
    IO.print("-")

# The blue key door, sector 71, on the patched map: from 880, 1440
# facing north, 20 idle tics and a use the door refuses, then 20 idle
# tics; a turn to 247.5 and a walk that takes record 82's card on tic
# 56, 34.43 east and 35.87 north of it, inside the reach of 36 (tic 55
# leaves 36.81 east), 49.7 away, while the bob holds the eye 36 over the
# floor so the card stays in view; 20 idle tics, a turn north, 19 tics
# forward and a use on tic 97 from 1423.47, 56.53 short of the door's
# line and inside the use range of 64. The door opens at 2 a tic from
# -128 on that tic, -116 at 102, -86 at 117, and stops at its top, 4
# under the ceilings of 0 beside it, on tic 158.
def locked(+placed: L.Level) -> IO(Unit):
  do IO<Unit>:
    k0 : S.State <- keyed("blue door refused", 82, 1n, use(),
      S.Sim.replay(List.replicate(K.Cmd, 20n, idle()), at(placed, 880, 1440, 90)))
    k1 : S.State <- keyed("-", 82, 20n, idle(), k0)
    k2 : S.State <- keyed("turn", 82, 1n, K.Cmd.demo(0, 0, 112, False{}), k1)
    k3 : S.State <- keyed("walk", 82, 13n, forward(), k2)
    k4 : S.State <- keyed("-", 82, 1n, forward(), k3)
    k5 : S.State <- keyed("-", 82, 20n, idle(), k4)
    k6 : S.State <- keyed("turn", 82, 1n, K.Cmd.demo(0, 0, 4294967184, False{}), k5)
    k7 : S.State <- keyed("walk", 82, 19n, forward(), k6)
    k8 : S.State <- keyed("use", 82, 1n, use(), k7)
    k9 : S.State <- keyed("-", 82, 5n, idle(), k8)
    k10 : S.State <- keyed("-", 82, 15n, idle(), k9)
    k11 : S.State <- keyed("-", 82, 41n, idle(), k10)
    k12 : S.State <- keyed("-", 82, 1n, idle(), k11)
    IO.print("-")

# The patched map's cases.
def patched.cases(+level: L.Level, p: Array<U32> & L.Level) -> IO(Unit):
  (a, +placed) = p
  do IO<Unit>:
    solids(level, placed)
    locked(placed)

def door(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    d0 : S.State <- run("door walk", 40n, forward(), [10], at(level, 832, 384, 90))
    used(d0)
    floors(level)
    crossed(level)
    lift(level)
    blue(level)
    exits(level)
    states([1n, 1n, 1n, 1n, 1n, 8n, 10n, 12n, 1n, 0n], S.State.start(level))
    lights([1n, 34n, 1n, 4n, 1n, 23n, 1n, 1n, 1n, 2n, 2n, 60n, 1n, 2n, 1n, 1n, 1n, 1n, 4n, 1n, 0n], S.State.start(level))

def count(things: List<&2, H.Thing>, +kind: U32) -> U32:
  match things:
    case []:
      0
    case H.Thing{id, k, x, y, z, floorz, ceilz, angle, sector, state, tics} <> rest:
      (Bool.to_u32(U32.is_eq(k, kind)) + count(rest, kind) : U32)

# How many things of each type Bendoom defines.
def kinds(defs: List<&2, H.Thing.Def>, +things: List<&2, H.Thing>) -> String:
  match defs:
    case []:
      ""
    case H.Def{+kind, state, radius, height, flags} <> rest:
      " " ++ U32.show(kind) ++ ":" ++ U32.show(count(things, kind)) ++ kinds(rest, things)

def ids(things: List<&2, H.Thing>) -> String:
  match things:
    case []:
      ""
    case H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics} <> rest:
      " " ++ U32.show(id) ++ ids(rest)

def described(d: Maybe<&2, H.Thing.Def>) -> String:
  match d:
    case None{}:
      " undefined"
    case Some{H.Def{kind, state, radius, height, flags}}:
      " radius " ++ U32.show(radius) ++ " height " ++ U32.show(height) ++ " flags " ++ U32.show(flags)

# A thing's line, empty for one gone.
def thing(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      ""
    case Some{H.Thing{id, +kind, x, y, z, floorz, ceilz, angle, sector, state, tics}}:
      "thing " ++ U32.show(id) ++ " type " ++ U32.show(kind) ++ " at " ++ F.Fixed.show(x) ++ " " ++ F.Fixed.show(y)
        ++ " z " ++ F.Fixed.show(z) ++ " angle " ++ A.Angle.show(angle) ++ " sector " ++ U32.show(sector)
        ++ " state " ++ U32.show(state) ++ " tics " ++ U32.show(tics) ++ described(H.Thing.def(kind))

def things(chosen: List<&2, U32>, +s: S.State) -> IO(Unit):
  match chosen:
    case []:
      IO.pure(Unit, Unit{})
    case id <> rest:
      do IO<Unit>:
        IO.print(thing(H.Things.get(S.State.things(s), id)))
        things(rest, s)

# What the blockmap links hold: how many links, how many of solid
# things, and how many disagree with the population.
type Links is Data:
  Links{links: U32, solid: U32, wrong: U32}

def solid.def(d: H.Thing.Def) -> Bool:
  H.Def{k, state, radius, height, +flags} = d
  Bool.not(U32.is_zero((flags .&. 2 : U32)))

def solid(+kind: U32) -> Bool:
  solid.def(H.Thing.info(kind))

# Whether a link agrees with the population: its thing alive, at the
# link's x and y, of its type, with its centre in cell c.
def agrees(m: Maybe<&2, H.Thing>, +bm: L.Level.Blockmap, +c: L.Level.Cell, link: L.Level.Link) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{H.Thing{id, +kind, +x, +y, z, floorz, ceilz, angle, sector, state, tics}}:
      L.Link{next, +lx, +ly, +lkind} = link
      Bool.and(L.Level.cell.is(L.Level.cell_of(bm, x, y), c),
        Bool.and(U32.is_eq(x, lx), Bool.and(U32.is_eq(y, ly), U32.is_eq(kind, lkind))))

def links.count(+link: L.Level.Link, m: Maybe<&2, H.Thing>, +bm: L.Level.Blockmap, +c: L.Level.Cell, t: Links) ->
  Links:
  L.Link{next, x, y, +kind} = link
  Links{n, s, w} = t
  Links{(n + 1 : U32), (s + Bool.to_u32(solid(kind)) : U32), (w + Bool.to_u32(Bool.not(agrees(m, bm, c, link))) : U32)}

def links.cell(ids: List<&2, U32>, +level: L.Level, +ts: H.Things, +c: L.Level.Cell, t: Links) -> Links:
  match ids:
    case []:
      t
    case +id <> rest:
      links.cell(rest, level, ts, c, links.count(L.Level.linked.in(L.Level.things_of(level), id), H.Things.get(ts, id),
        L.Level.blockmap_of(level), c, t))

def links.cells(cells: List<&2, L.Level.Cell>, +level: L.Level, +ts: H.Things, t: Links) -> Links:
  match cells:
    case []:
      t
    case +c <> rest:
      links.cells(rest, level, ts, links.cell(L.Level.cell.things(L.Level.geo(level), c), level, ts, c, t))

# How many of the things are not in the list of the cell their centre
# is in.
def unlinked(things: List<&2, H.Thing>, +level: L.Level) -> U32:
  match things:
    case []:
      0
    case H.Thing{+id, kind, +x, +y, z, floorz, ceilz, angle, sector, state, tics} <> rest:
      (Bool.to_u32(Bool.not(S.Sim.member(L.Level.cell.things(L.Level.geo(level),
        L.Level.cell_of(L.Level.blockmap_of(level), x, y)), id))) + unlinked(rest, level) : U32)

def solids.count(things: List<&2, H.Thing>) -> U32:
  match things:
    case []:
      0
    case H.Thing{id, +kind, x, y, z, floorz, ceilz, angle, sector, state, tics} <> rest:
      (Bool.to_u32(solid(kind)) + solids.count(rest) : U32)

def links.show(t: Links, +things: List<&2, H.Thing>, +level: L.Level) -> String:
  Links{n, s, w} = t
  "links " ++ U32.show(n) ++ " of " ++ Nat.show(List.length(&2, H.Thing, things)) ++ " things, solid "
    ++ U32.show(s) ++ " of " ++ U32.show(solids.count(things)) ++ ", wrong " ++ U32.show(w) ++ ", unlinked "
    ++ U32.show(unlinked(things, level))

# The blockmap links of a state's level against its population, cell by
# cell over the whole blockmap: as many links as things, as many of them
# solid as solid things, none that disagrees with its thing, and no
# thing missing from its centre's cell mean each thing is linked once,
# in the cell of its centre, with its x, y and type.
def links.in(bm: L.Level.Blockmap, +s: S.State) -> String:
  L.Blockmap{words, ox, oy, +cols, +rows} = bm
  +level = S.State.level(s)
  links.show(links.cells(S.Sim.cells(U32.to_nat(cols), U32.to_nat(rows), 0, 0), level, S.State.things(s),
    Links{0, 0, 0}), H.Things.list(S.State.things(s)), level)

def links(+s: S.State) -> String:
  links.in(L.Level.blockmap_of(S.State.level(s)), s)

def free(+s: S.State) -> IO(S.State):
  +p = S.State.player(s)
  +spawned = H.Things.list(S.State.things(s))
  do IO<S.State>:
    IO.print("free at start " ++ Bool.show(S.Sim.free(S.State.level(s), S.Player.x(p), S.Player.y(p))))
    IO.print(I.Inventory.show(S.Player.inv(p)))
    IO.print("things at start " ++ Nat.show(List.length(&2, H.Thing, spawned)) ++ " random "
      ++ U32.show(S.State.rnd(s)))
    IO.print("by type" ++ kinds(H.Thing.defs(), spawned))
    IO.print("first" ++ ids(List.take(&2, H.Thing, spawned, 12n)))
    IO.print(links(s))
    things([2, 6, 29, 87, 245, 291], s)
    return s

# A run, then the tic, the player's place, the inventory, how many
# things are left and the names of those taken since the case's first
# state.
def picked(tag: String, n: Nat, cmd: K.Cmd, +first: S.State, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.replicate(K.Cmd, n, cmd), s)
  do IO<S.State>:
    IO.print(line(tag ++ " tic " ++ U32.show(S.State.clock(q)), q))
    IO.print("  " ++ I.Inventory.show(S.Player.inv(S.State.player(q)))
      ++ H.Things.tally(H.Things.list(S.State.things(first)), S.State.things(q)))
    return q

# An inventory with other health, armour points and type, and ammo in
# ammotype_t order.
def stocked(health: U32, armour: U32, armourtype: U32, ammo: List<&2, U32>, inv: I.Inventory) -> I.Inventory:
  I.Inventory{h, a, t, cards, rounds, caps, backpack, weapons, powers, items, bonus} = inv
  I.Inventory{health, armour, armourtype, cards, V.Vec.of_list(ammo, 4), caps, backpack, weapons, powers, items,
    bonus}

# Walking forward from a place for some tics, then one more: the tic
# before contact and the tic of it.
def walked(tag: String, n: Nat, +s: S.State) -> IO(S.State):
  do IO<S.State>:
    a : S.State <- picked(tag, n, forward(), s, s)
    picked("-", 1n, forward(), s, a)

# Loose rounds: a clip walked into from the east, and Freedoom's row of
# three shells walked along from the west, the rocket from the east,
# with room and at the cap.
def loose(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    c : S.State <- walked("clip walk", 9n, at(level, 672, 992, 180))
    h : S.State <- walked("shells walk", 8n, at(level, 1060, 65312, 0))
    h2 : S.State <- picked("-", 17n, forward(), at(level, 1060, 65312, 0), h)
    f : S.State <- walked("shells walk at the cap", 8n,
      holding(stocked(100, 0, 0, [50, 50, 0, 0], I.Inventory.start()), at(level, 1060, 65312, 0)))
    f2 : S.State <- picked("-", 17n, forward(), at(level, 1060, 65312, 0), f)
    r : S.State <- walked("rocket walk", 8n, at(level, 700, 64536, 180))
    r2 : S.State <- walked("rocket walk at the cap", 8n,
      holding(stocked(100, 0, 0, [50, 0, 0, 50], I.Inventory.start()), at(level, 700, 64536, 180)))
    IO.print("-")

# The shell box behind the closet door west of the clips, with room,
# one clip short of the cap, and at it: an idle tic, since the player
# starts with use held, the use, the door rising, the walk.
def box(tag: String, +s: S.State) -> IO(Unit):
  +opened = S.Sim.replay(List.concat(&2, K.Cmd, [[idle(), use()], List.replicate(K.Cmd, 30n, idle())]), s)
  do IO<Unit>:
    b : S.State <- walked(tag, 19n, opened)
    IO.print("-")

# The chainsaw on its step, strafed past on the key's script: not owned,
# then owned.
def chainsaw(tag: String, inv: I.Inventory, +level: L.Level) -> IO(S.State):
  +s = holding(inv, at(level, 3158, 2176, 180))
  do IO<S.State>:
    a : S.State <- picked(tag, 12n, K.Cmd.demo(0, 4294967272, 0, False{}), s,
      S.Sim.replay(List.append(&2, K.Cmd, List.replicate(K.Cmd, 20n, idle()),
        [K.Cmd.demo(0, 0, 4294967280, False{})]), s))
    picked("-", 1n, K.Cmd.demo(0, 4294967272, 0, False{}), s, a)

# The ammo and the chainsaw, then health, armour and berserk, a pickup
# of each type Freedoom's E1M1 spawns but the key, each walked at alone:
# taken when it improves the inventory, left when it cannot.
def pickups(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    loose(level)
    box("shell box walk", at(level, 600, 712, 180))
    box("shell box walk short of the cap",
      holding(stocked(100, 0, 0, [50, 45, 0, 0], I.Inventory.start()), at(level, 600, 712, 180)))
    box("shell box walk at the cap",
      holding(stocked(100, 0, 0, [50, 50, 0, 0], I.Inventory.start()), at(level, 600, 712, 180)))
    w : S.State <- chainsaw("chainsaw strafe", I.Inventory.start(), level)
    w2 : S.State <- chainsaw("owned chainsaw strafe", S.Player.inv(S.State.player(w)), level)
    h0 : S.State <- walked("health bonus", 11n, at(level, 432, 256, 0))
    h1 : S.State <- walked("health bonus at 200", 11n,
      holding(stocked(200, 0, 0, [50, 0, 0, 0], I.Inventory.start()), at(level, 432, 256, 0)))
    s0 : S.State <- walked("stimpack at 100", 11n, at(level, 4294967264, 400, 90))
    s1 : S.State <- picked("-", 10n, forward(), at(level, 4294967264, 400, 90), s0)
    s2 : S.State <- walked("stimpack at 60", 11n,
      holding(stocked(60, 0, 0, [50, 0, 0, 0], I.Inventory.start()), at(level, 4294967264, 400, 90)))
    m0 : S.State <- walked("medikit at 100", 11n, at(level, 32, 400, 90))
    m1 : S.State <- walked("medikit at 60", 11n,
      holding(stocked(60, 0, 0, [50, 0, 0, 0], I.Inventory.start()), at(level, 32, 400, 90)))
    b0 : S.State <- walked("berserk at 100", 11n, at(level, 608, 400, 90))
    b1 : S.State <- picked("-", 10n, idle(), at(level, 608, 400, 90), b0)
    b2 : S.State <- walked("berserk at 60", 11n,
      holding(stocked(60, 0, 0, [50, 0, 0, 0], I.Inventory.start()), at(level, 608, 400, 90)))
    a0 : S.State <- walked("armour bonus", 11n, at(level, 624, 4294966576, 270))
    g0 : S.State <- walked("green armour", 11n, at(level, 1664, 1008, 90))
    g1 : S.State <- walked("green armour at 100", 11n,
      holding(stocked(100, 100, 1, [50, 0, 0, 0], I.Inventory.start()), at(level, 1664, 1008, 90)))
    IO.print("-")

def walk(p: Array<U32> & L.Level) -> IO(Unit):
  (a, +level) = p
  do IO<Unit>:
    s : S.State <- step("start", 0n, K.Keys.none(), S.State.start(level))
    p0 : S.State <- free(s)
    p1 : S.State <- step("U:1", 1n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}, p0)
    p2 : S.State <- step("U!:34", 34n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, p1)
    p3 : S.State <- step("L:20", 20n, K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}}, p2)
    p4 : S.State <- step("U!:200", 200n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, p3)
    p5 : S.State <- step("-:40", 40n, K.Keys{False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}, p4)
    p6 : S.State <- step("R:10", 10n, K.Keys{False{}, False{}, False{}, True{}, False{}, False{}, False{}, False{}}, p5)
    p7 : S.State <- step("U!:70", 70n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, p6)
    p8 : S.State <- step("L:30", 30n, K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}}, p7)
    p9 : S.State <- step("U:100", 100n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}, p8)
    p10 : S.State <- step("S:60", 60n, K.Keys{False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}}, p9)
    p11 : S.State <- step("D!:100", 100n, K.Keys{False{}, True{}, False{}, False{}, False{}, False{}, True{}, False{}}, p10)
    p12 : S.State <- step("R:40", 40n, K.Keys{False{}, False{}, False{}, True{}, False{}, False{}, False{}, False{}}, p11)
    p13 : S.State <- step("U!:120", 120n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, p12)
    p14 : S.State <- step("A!:40", 40n, K.Keys{False{}, False{}, False{}, False{}, True{}, False{}, True{}, False{}}, p13)
    q1 : S.State <- step("ledge U!:47", 47n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, S.State.start(level))
    q2 : S.State <- step("U!:1", 1n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, q1)
    q3 : S.State <- step("U!:1", 1n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, q2)
    q4 : S.State <- step("U!:15", 15n, K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, q3)
    q5 : S.State <- step("-:1", 1n, K.Keys.none(), q4)
    q6 : S.State <- step("-:40", 40n, K.Keys.none(), q5)
    pickups(level)
    door(level)
    patched.cases(level, patched(W.Wad.dir(a)))

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    walk(L.Level.load(W.Wad.dir(bytes)))

#|start -416.000000 256.000000 0.000 z 0.000000 floor 0.000000 eye 41.000000
#|free at start True
#|inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0
#|things at start 180 random 1
#|by type 5:1 8:0 10:3 12:3 15:4 17:0 18:5 19:1 20:1 21:2 24:2 26:1 35:0 43:12 47:18 48:4 54:15 60:2 2001:0 2002:0 2003:0 2004:0 2005:1 2007:2 2008:14 2010:1 2011:2 2012:4 2013:0 2014:30 2015:18 2018:1 2019:0 2023:1 2028:7 2035:22 2046:0 2047:1 2048:1 2049:1
#|first 2 6 8 9 10 11 12 13 14 15 16 17
#|links 180 of 180 things, solid 79 of 79, wrong 0, unlinked 0
#|thing 2 type 2005 at 3104.000000 2160.000000 z 194.000000 angle 315.000 sector 139 state 45 tics 4294967295 radius 20 height 16 flags 1
#|thing 6 type 2018 at 1664.000000 1088.000000 z -144.000000 angle 270.000 sector 130 state 6 tics 5 radius 20 height 16 flags 1
#|thing 29 type 60 at 1184.000000 288.000000 z 60.000000 angle 90.000 sector 153 state 53 tics 4294967295 radius 20 height 68 flags 768
#|thing 87 type 5 at 2192.000000 576.000000 z 136.000000 angle 270.000 sector 35 state 24 tics 3 radius 20 height 16 flags 33554433
#|thing 245 type 19 at 1248.000000 224.000000 z 16.000000 angle 90.000 sector 170 state 3 tics 4294967295 radius 20 height 16 flags 0
#|thing 291 type 2023 at 608.000000 480.000000 z 0.000000 angle 270.000 sector 150 state 34 tics 4294967295 radius 20 height 16 flags 8388609
#|U:1 -415.218765 256.000289 0.000 z 0.000000 floor 0.000000 eye 41.000015
#|U!:34 3.282882 256.157440 0.000 z 0.000000 floor 0.000000 eye 33.430175
#|L:20 137.245544 256.206893 61.523 z -48.000000 floor -48.000000 eye 44.403701
#|U!:200 879.976928 495.961242 61.523 z -128.000000 floor -128.000000 eye 40.722702
#|-:40 879.976928 495.961242 61.523 z -128.000000 floor -128.000000 eye 41.000000
#|R:10 879.976928 495.961242 35.156 z -128.000000 floor -128.000000 eye 41.000000
#|U!:70 879.976928 495.976135 35.156 z -128.000000 floor -128.000000 eye 40.730163
#|L:30 879.976928 495.976135 131.835 z -128.000000 floor -128.000000 eye 41.000000
#|U:100 784.014022 495.985275 131.835 z -128.000000 floor -128.000000 eye 41.065185
#|S:60 879.981826 495.988571 131.835 z -128.000000 floor -128.000000 eye 41.059051
#|D!:100 811.054748 331.127044 131.835 z -128.000000 floor -128.000000 eye 41.392868
#|R:40 803.277694 323.355331 0.000 z -128.000000 floor -128.000000 eye 41.000000
#|U!:120 879.949401 430.466888 0.000 z -128.000000 floor -128.000000 eye 41.234771
#|A!:40 879.826950 495.961883 0.000 z -128.000000 floor -128.000000 eye 41.147918
#|ledge U!:47 207.783569 256.234542 0.000 z -24.000000 floor -24.000000 eye 52.658081
#|U!:1 224.302001 256.240737 0.000 z -24.000000 floor -128.000000 eye 151.570556
#|U!:1 240.820434 256.246932 0.000 z -26.000000 floor -128.000000 eye 145.000000
#|U!:15 492.898864 256.341476 0.000 z -128.000000 floor -128.000000 eye 42.834960
#|-:1 509.055541 256.347518 0.000 z -128.000000 floor -128.000000 eye 43.033325
#|-:40 662.189941 256.402572 0.000 z -128.000000 floor -128.000000 eye 41.011581
#|clip walk tic 9 644.340896 991.988937 180.000 z -128.000000 floor -128.000000 eye 42.770172
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 10 639.121368 991.986862 180.000 z -128.000000 floor -128.000000 eye 42.064453
#|  inventory health 100 armour 0 type 0 cards 0 ammo 60 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 179 taken 140
#|shells walk tic 8 1082.761047 -223.991744 0.000 z 0.000000 floor 0.000000 eye 43.090270
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 9 1087.658264 -223.989990 0.000 z 0.000000 floor 0.000000 eye 42.770034
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 4 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 179 taken 276
#|- tic 26 1202.337890 -223.948562 0.000 z 0.000000 floor 0.000000 eye 48.388656
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 12 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 177 taken 207 208 276
#|shells walk at the cap tic 8 1082.761047 -223.991744 0.000 z 0.000000 floor 0.000000 eye 43.090270
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 9 1087.658264 -223.989990 0.000 z 0.000000 floor 0.000000 eye 42.770034
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 26 1202.337890 -223.948562 0.000 z 0.000000 floor 0.000000 eye 48.388656
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|rocket walk tic 8 677.238296 -1000.009109 180.000 z 0.000000 floor 0.000000 eye 43.090423
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 9 672.340896 -1000.011062 180.000 z 0.000000 floor 0.000000 eye 42.770172
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 1 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 179 taken 279
#|rocket walk at the cap tic 8 677.238296 -1000.009109 180.000 z 0.000000 floor 0.000000 eye 43.090423
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 9 672.340896 -1000.011062 180.000 z 0.000000 floor 0.000000 eye 42.770172
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 50 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|-
#|shell box walk tic 51 509.810287 711.963989 180.000 z -128.000000 floor -128.000000 eye 41.140472
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 52 502.640411 711.961120 180.000 z -128.000000 floor -128.000000 eye 39.155944
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 20 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 179 taken 137
#|-
#|shell box walk short of the cap tic 51 509.810287 711.963989 180.000 z -128.000000 floor -128.000000 eye 41.140472
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 45 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 52 502.640411 711.961120 180.000 z -128.000000 floor -128.000000 eye 39.155944
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 179 taken 137
#|-
#|shell box walk at the cap tic 51 509.810287 711.963989 180.000 z -128.000000 floor -128.000000 eye 41.140472
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 52 502.640411 711.961120 180.000 z -128.000000 floor -128.000000 eye 39.155944
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|-
#|chainsaw strafe tic 33 3141.789398 2136.822265 157.500 z 194.000000 floor 194.000000 eye 30.035858
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 34 3139.581390 2131.485961 157.500 z 194.000000 floor 194.000000 eye 30.413955
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 131 powers 0 0 0 0 0 0 items 0 flash 6 things 179 taken 2
#|owned chainsaw strafe tic 33 3141.789398 2136.822265 157.500 z 194.000000 floor 194.000000 eye 30.035858
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 131 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 34 3139.581390 2131.485961 157.500 z 194.000000 floor 194.000000 eye 30.413955
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 131 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|health bonus tic 11 470.388839 256.013870 0.000 z -128.000000 floor -128.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 12 476.164627 256.015945 0.000 z -128.000000 floor -128.000000 eye 39.730026
#|  inventory health 101 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 things 179 taken 268
#|health bonus at 200 tic 11 470.388839 256.013870 0.000 z -128.000000 floor -128.000000 eye 41.015975
#|  inventory health 200 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 12 476.164627 256.015945 0.000 z -128.000000 floor -128.000000 eye 39.730026
#|  inventory health 200 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 things 179 taken 268
#|stimpack at 100 tic 11 -32.015335 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 12 -32.017639 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 22 -32.040420 495.976776 90.000 z 0.000000 floor 0.000000 eye 41.022888
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|stimpack at 60 tic 11 -32.015335 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 60 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 12 -32.017639 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 70 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 179 taken 215
#|medikit at 100 tic 11 31.984664 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 12 31.982360 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|medikit at 60 tic 11 31.984664 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 60 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 12 31.982360 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 85 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 179 taken 259
#|berserk at 100 tic 11 607.984664 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 12 607.982360 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 1 0 0 0 0 items 1 flash 6 things 179 taken 291
#|- tic 22 607.968032 479.134338 90.000 z 0.000000 floor 0.000000 eye 41.174743
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 11 0 0 0 0 items 1 flash 0 things 179 taken 291
#|berserk at 60 tic 11 607.984664 438.388839 90.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 60 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 12 607.982360 444.164627 90.000 z 0.000000 floor 0.000000 eye 39.730026
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 1 0 0 0 0 items 1 flash 6 things 179 taken 291
#|armour bonus tic 11 624.013870 -758.390090 270.000 z 0.000000 floor 0.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 12 624.015945 -764.166107 270.000 z 0.000000 floor 0.000000 eye 39.729934
#|  inventory health 100 armour 1 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 1 flash 6 things 179 taken 204
#|green armour tic 11 1663.984664 1046.388839 90.000 z -144.000000 floor -144.000000 eye 41.015975
#|  inventory health 100 armour 0 type 0 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 12 1663.982360 1052.164627 90.000 z -144.000000 floor -144.000000 eye 39.730026
#|  inventory health 100 armour 100 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 6 things 179 taken 6
#|green armour at 100 tic 11 1663.984664 1046.388839 90.000 z -144.000000 floor -144.000000 eye 41.015975
#|  inventory health 100 armour 100 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|- tic 12 1663.982360 1052.164627 90.000 z -144.000000 floor -144.000000 eye 39.730026
#|  inventory health 100 armour 100 type 1 cards 0 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 powers 0 0 0 0 0 0 items 0 flash 0 things 180 taken
#|-
#|door walk tic 40 831.926605 495.977203 90.000 z -128.000000 floor -128.000000 eye 40.975143 thinkers 9 sector 10 -128.000000 -128.000000
#|use tic 41 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -126.000000
#|- tic 61 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -86.000000
#|- tic 102 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 103 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 253 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 254 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -6.000000
#|- tic 315 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -128.000000
#|- tic 316 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 10 -128.000000 -128.000000
#|closing - tic 264 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -26.000000
#|use tic 265 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -24.000000
#|- tic 275 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 279 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|use tic 280 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -6.000000
#|-
#|through walk tic 142 831.822738 750.318176 90.000 z -128.000000 floor -128.000000 eye 42.976440 thinkers 10 sector 10 -128.000000 -4.000000
#|doorway walk tic 108 831.918884 510.046890 90.000 z -128.000000 floor -128.000000 eye 42.444900 thinkers 10 sector 10 -128.000000 -4.000000
#|- tic 287 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -72.000000
#|- tic 288 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -72.000000
#|- tic 289 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -70.000000
#|- tic 323 831.901535 545.398254 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|-
#|held use tic 140 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000
#|use tic 340 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 10 -128.000000 -128.000000
#|-
#|switch walk tic 30 2063.945510 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.024505 thinkers 9 sector 76 272.000000 272.000000 sector 126 264.000000 264.000000 sector 129 264.000000 264.000000
#|use tic 31 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 12 sector 76 271.000000 272.000000 sector 126 263.000000 264.000000 sector 129 263.000000 264.000000
#|- tic 150 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 12 sector 76 152.000000 272.000000 sector 126 144.000000 264.000000 sector 129 144.000000 264.000000
#|- tic 151 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 11 sector 76 151.000000 272.000000 sector 126 144.000000 264.000000 sector 129 143.000000 264.000000
#|- tic 158 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 11 sector 76 144.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|- tic 159 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 10 sector 76 143.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|- tic 166 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 10 sector 76 136.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|- tic 167 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 9 sector 76 136.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|use tic 168 2063.943267 -240.021331 90.000 z 136.000000 floor 136.000000 eye 41.000000 thinkers 9 sector 76 136.000000 272.000000 sector 126 144.000000 264.000000 sector 129 136.000000 264.000000
#|-
#|trigger walk tic 16 2029.450805 -449.974945 0.000 z 128.000000 floor 128.000000 eye 35.541717 thinkers 9 sector 145 136.000000 136.000000
#|over tic 17 2036.220657 -449.972503 0.000 z 128.000000 floor 128.000000 eye 35.539337 thinkers 10 sector 145 136.000000 138.000000
#|- tic 78 2101.079208 -449.951568 0.000 z 128.000000 floor 128.000000 eye 41.000000 thinkers 10 sector 145 136.000000 260.000000
#|- tic 79 2101.079208 -449.951568 0.000 z 128.000000 floor 128.000000 eye 41.000000 thinkers 9 sector 145 136.000000 260.000000
#|back tic 119 1846.728271 -450.053344 0.000 z 136.000000 floor 136.000000 eye 28.955810 thinkers 9 sector 145 136.000000 260.000000
#|-
#|lift run tic 35 11.349639 256.160812 0.000 z 0.000000 floor 0.000000 eye 33.430175 thinkers 9 sector 98 12.000000 128.000000
#|- tic 39 62.115066 256.179794 0.000 z 12.000000 floor 12.000000 eye 25.687744 thinkers 9 sector 98 12.000000 128.000000
#|over tic 40 71.977874 256.183471 0.000 z 8.000000 floor 8.000000 eye 33.644653 thinkers 10 sector 98 8.000000 128.000000
#|- tic 73 163.614135 256.215759 0.000 z -124.000000 floor -124.000000 eye 44.989715 thinkers 10 sector 98 -124.000000 128.000000
#|- tic 74 163.961135 256.215820 0.000 z -124.000000 floor -124.000000 eye 40.988113 thinkers 10 sector 98 -124.000000 128.000000
#|- tic 179 166.744613 256.215911 0.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 -124.000000 128.000000
#|- tic 180 166.744613 256.215911 0.000 z -120.000000 floor -120.000000 eye 37.000000 thinkers 10 sector 98 -120.000000 128.000000
#|- tic 213 166.744613 256.215911 0.000 z 12.000000 floor 12.000000 eye 37.000000 thinkers 10 sector 98 12.000000 128.000000
#|- tic 214 166.744613 256.215911 0.000 z 12.000000 floor 12.000000 eye 41.000000 thinkers 9 sector 98 12.000000 128.000000
#|lift switch walk tic 10 208.160308 255.986923 180.000 z -124.000000 floor -124.000000 eye 40.314453 thinkers 9 sector 98 12.000000 128.000000
#|use tic 11 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 40.500000 thinkers 10 sector 98 8.000000 128.000000
#|- tic 12 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 4.000000 128.000000
#|use tic 13 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 0.000000 128.000000
#|- tic 184 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 12.000000 128.000000
#|- tic 185 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 9 sector 98 12.000000 128.000000
#|use tic 186 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 8.000000 128.000000
#|-
#|key turn tic 21 2246.000000 592.000000 157.500 z 136.000000 floor 136.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000 key True things 180 cards 0 flash 0
#|strafe tic 33 2229.789398 552.822265 157.500 z 136.000000 floor 136.000000 eye 38.785858 thinkers 9 sector 71 -128.000000 -128.000000 key True things 180 cards 0 flash 0
#|- tic 34 2227.581390 547.485961 157.500 z 136.000000 floor 136.000000 eye 37.663955 thinkers 9 sector 71 -128.000000 -128.000000 key False things 179 cards 1 flash 12
#|- tic 44 2202.145187 486.011810 157.500 z 136.000000 floor 136.000000 eye 46.122497 thinkers 9 sector 71 -128.000000 -128.000000 key False things 179 cards 1 flash 2
#|blue walk with the skull tic 30 831.941818 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.024505 thinkers 9 sector 71 -128.000000 -128.000000 key True things 180 cards 8 flash 0
#|use tic 31 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -126.000000 key True things 180 cards 8 flash 0
#|- tic 41 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -106.000000 key True things 180 cards 8 flash 0
#|- tic 92 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -4.000000 key True things 180 cards 8 flash 0
#|-
#|exit first tic use tic 1 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended False special 11
#|- tic 20 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended False special 11
#|use tic 21 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended True special 0
#|walk held use tic 21 -352.000000 1296.000000 180.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 ended True special 0
#|-
#|states tic 0 2:45/4294967295 6:6/5 87:24/3 24:10/4 121:18/6 144:12/1 172:51/6
#|states tic 1 2:45/4294967295 6:6/4 87:24/2 24:10/3 121:18/5 144:13/6 172:51/5
#|states tic 2 2:45/4294967295 6:6/3 87:24/1 24:10/2 121:18/4 144:13/5 172:51/4
#|states tic 3 2:45/4294967295 6:6/2 87:25/10 24:10/1 121:18/3 144:13/4 172:51/3
#|states tic 4 2:45/4294967295 6:6/1 87:25/9 24:11/6 121:18/2 144:13/3 172:51/2
#|states tic 5 2:45/4294967295 6:7/7 87:25/8 24:11/5 121:18/1 144:13/2 172:51/1
#|states tic 13 2:45/4294967295 6:6/5 87:24/10 24:10/3 121:20/5 144:15/6 172:52/1
#|states tic 23 2:45/4294967295 6:7/2 87:25/10 24:10/5 121:21/1 144:16/2 172:52/5
#|states tic 35 2:45/4294967295 6:7/3 87:24/8 24:10/5 121:23/1 144:12/2 172:52/7
#|states tic 36 2:45/4294967295 6:7/2 87:24/7 24:10/4 121:18/6 144:12/1 172:52/6
#|lights tic 0 sector 32 176 sector 33 176 sector 48 140 sector 90 192
#|lights tic 1 sector 32 176 sector 33 140 sector 48 120 sector 90 160
#|lights tic 35 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 36 sector 32 176 sector 33 176 sector 48 140 sector 90 192
#|lights tic 40 sector 32 176 sector 33 176 sector 48 140 sector 90 192
#|lights tic 41 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 64 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 65 sector 32 144 sector 33 176 sector 48 140 sector 90 160
#|lights tic 66 sector 32 144 sector 33 176 sector 48 140 sector 90 160
#|lights tic 67 sector 32 144 sector 33 176 sector 48 140 sector 90 160
#|lights tic 69 sector 32 144 sector 33 176 sector 48 140 sector 90 160
#|lights tic 71 sector 32 176 sector 33 176 sector 48 120 sector 90 160
#|lights tic 131 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 132 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 134 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 135 sector 32 176 sector 33 176 sector 48 140 sector 90 160
#|lights tic 136 sector 32 144 sector 33 176 sector 48 140 sector 90 160
#|lights tic 137 sector 32 144 sector 33 176 sector 48 140 sector 90 160
#|lights tic 138 sector 32 144 sector 33 140 sector 48 140 sector 90 160
#|lights tic 142 sector 32 176 sector 33 140 sector 48 120 sector 90 160
#|lights tic 143 sector 32 176 sector 33 140 sector 48 120 sector 90 160
#|end
#|column walk tic 37 -191.972503 1635.776504 270.000 z -128.000000 floor -128.000000 eye 35.523132 thinkers 9
#|- tic 38 -191.970001 1635.776504 270.000 z -128.000000 floor -128.000000 eye 36.104217 thinkers 9
#|- tic 48 -191.942932 1635.776504 270.000 z -128.000000 floor -128.000000 eye 47.252609 thinkers 9
#|corpse walk tic 30 128.011886 399.121368 270.000 z 0.000000 floor 0.000000 eye 42.094177 thinkers 9
#|- tic 38 128.029998 348.859802 270.000 z 0.000000 floor 0.000000 eye 36.104217 thinkers 9
#|column lift switch walk tic 10 208.160308 255.986923 180.000 z -124.000000 floor -124.000000 eye 40.314453 thinkers 9 sector 98 12.000000 128.000000 thing 3 type 48 z 12.000000 floor 12.000000 ceiling 128.000000 state 58 tics 4294967295
#|use tic 11 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 40.500000 thinkers 10 sector 98 8.000000 128.000000 thing 3 type 48 z 8.000000 floor 8.000000 ceiling 128.000000 state 58 tics 4294967295
#|- tic 12 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 4.000000 128.000000 thing 3 type 48 z 4.000000 floor 4.000000 ceiling 128.000000 state 58 tics 4294967295
#|- tic 44 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 -124.000000 128.000000 thing 3 type 48 z -124.000000 floor -124.000000 ceiling 128.000000 state 58 tics 4294967295
#|- tic 45 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 -124.000000 128.000000 thing 3 type 48 z -124.000000 floor -124.000000 ceiling 128.000000 state 58 tics 4294967295
#|- tic 150 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 -124.000000 128.000000 thing 3 type 48 z -124.000000 floor -124.000000 ceiling 128.000000 state 58 tics 4294967295
#|- tic 184 208.160308 255.986602 180.000 z -124.000000 floor -124.000000 eye 41.000000 thinkers 10 sector 98 12.000000 128.000000 thing 3 type 48 z 12.000000 floor 12.000000 ceiling 128.000000 state 58 tics 4294967295
#|barrel door walk tic 40 831.926605 495.977203 90.000 z -128.000000 floor -128.000000 eye 40.975143 thinkers 9 sector 10 -128.000000 -128.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -128.000000 state 11 tics 5
#|use tic 41 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -126.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -126.000000 state 11 tics 4
#|- tic 102 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -4.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -4.000000 state 11 tics 3
#|- tic 294 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -86.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -86.000000 state 11 tics 3
#|- tic 295 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -86.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -86.000000 state 11 tics 2
#|- tic 296 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -84.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -84.000000 state 11 tics 1
#|- tic 297 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -82.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -82.000000 state 10 tics 6
#|- tic 301 831.924514 495.977203 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 10 -128.000000 -74.000000 thing 35 type 2035 z -128.000000 floor -128.000000 ceiling -74.000000 state 10 tics 2
#|-
#|blue door refused tic 21 880.000000 1440.000000 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000 key True things 183 cards 0 flash 0
#|- tic 41 880.000000 1440.000000 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000 key True things 183 cards 0 flash 0
#|turn tic 42 880.000000 1440.000000 247.500 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000 key True things 183 cards 0 flash 0
#|walk tic 55 860.814102 1393.630569 247.500 z -128.000000 floor -128.000000 eye 36.733230 thinkers 9 sector 71 -128.000000 -128.000000 key True things 183 cards 0 flash 0
#|- tic 56 858.431030 1387.871063 247.500 z -128.000000 floor -128.000000 eye 36.145187 thinkers 9 sector 71 -128.000000 -128.000000 key False things 182 cards 1 flash 12
#|- tic 76 838.610397 1339.968490 247.500 z -128.000000 floor -128.000000 eye 40.905364 thinkers 9 sector 71 -128.000000 -128.000000 key False things 182 cards 1 flash 0
#|turn tic 77 838.308792 1339.239654 90.000 z -128.000000 floor -128.000000 eye 40.925247 thinkers 9 sector 71 -128.000000 -128.000000 key False things 182 cards 1 flash 0
#|walk tic 96 835.806503 1423.465972 90.000 z -128.000000 floor -128.000000 eye 34.990249 thinkers 9 sector 71 -128.000000 -128.000000 key False things 182 cards 1 flash 0
#|use tic 97 835.761825 1429.752563 90.000 z -128.000000 floor -128.000000 eye 36.239089 thinkers 10 sector 71 -128.000000 -126.000000 key False things 182 cards 1 flash 0
#|- tic 102 835.593826 1453.375137 90.000 z -128.000000 floor -128.000000 eye 41.488937 thinkers 10 sector 71 -128.000000 -116.000000 key False things 182 cards 1 flash 0
#|- tic 117 835.508346 1463.921813 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -86.000000 key False things 182 cards 1 flash 0
#|- tic 158 835.508346 1463.921813 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -4.000000 key False things 182 cards 1 flash 0
#|- tic 159 835.508346 1463.921813 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -4.000000 key False things 182 cards 1 flash 0
#|-
