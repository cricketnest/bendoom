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
# sector-at), its z, its state row, its tics and its definition. The
# player's inventory, G_PlayerReborn's.
# Then the movers and the lights, as runs of one command in a demo's
# units from a place, each line with the clock, the thinkers running
# and chosen sectors' floors and ceilings: the first door used, turned
# twice, held, walked through and closed on the player; the special 23
# switch; a special 2 line crossed both ways; the lift called by its
# line and by its switch; the blue key taken, and its door, sector 71,
# refusing the start's inventory and opening for the one the key left
# and for the blue skull alone; the exit switch; the blinks and the
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
# tic 92.
# The pickups, each run printed with the tic, the records taken since it
# began, the things left, the ammo and caps in ammotype_t order, the
# backpack, the weapons owned and the pickup flash: a clip, three shells
# in a row and the rocket walked into, with room and at the cap; the
# shell box behind the closet door west of the clips, with room, one
# clip short of the cap and at it; the backpack (record 288) and the
# shotgun (record 256), which Freedoom places for the easier skills
# alone, spawned after the level's things: the backpack first, again
# with the first's inventory and again at every doubled cap; the shotgun
# not owned, owned with room, owned at the cap and not owned at the cap;
# the chainsaw on its step, strafed past on the key's script, not owned
# and owned. The amounts are p_inter.c's on Hurt Me Plenty: clipammo
# 10 4 20 1, five clips in a box, two with a weapon found, maxammo 200
# 50 300 50 doubled by the first backpack, a flash of 6. The contact
# tics, where the reach of 36 is first met, are regression pins.
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

def present(things: List<&2, H.Thing>, +id: U32) -> Bool:
  match things:
    case []:
      False{}
    case H.Thing{i, kind, x, y, z, sector, state, tics} <> rest:
      Bool.or(U32.is_eq(i, id), present(rest, id))

# A run, then the blue key door's heights, whether the blue key (record
# 87) is there, how many things are, and the cards and pickup flash.
def keyed(tag: String, n: Nat, cmd: K.Cmd, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.replicate(K.Cmd, n, cmd), s)
  +inv = S.Player.inv(S.State.player(q))
  do IO<S.State>:
    IO.print(watch(tag, [71], q) ++ " key " ++ Bool.show(present(S.State.things(q), 87)) ++ " things "
      ++ Nat.show(List.length(&2, H.Thing, S.State.things(q))) ++ " cards " ++ U32.show(I.Inventory.cards(inv))
      ++ " flash " ++ U32.show(I.Inventory.bonus(inv)))
    return q

# The state with the player holding an inventory.
def holding(inv: I.Inventory, s: S.State) -> S.State:
  S.State{p, level, things, sidetex, thinkers, rnd, clock, ended, usedown} = s
  S.State{S.Player.holding(p, inv), level, things, sidetex, thinkers, rnd, clock, ended, usedown}

# The blue key door, sector 71, used from the south by a player holding
# an inventory.
def door71(tag: String, inv: I.Inventory, +level: L.Level) -> IO(Unit):
  do IO<Unit>:
    b0 : S.State <- keyed(tag, 30n, forward(), holding(inv, at(level, 832, 1400, 90)))
    b1 : S.State <- keyed("use", 1n, use(), b0)
    b2 : S.State <- keyed("-", 10n, idle(), b1)
    b3 : S.State <- keyed("-", 51n, idle(), b2)
    IO.print("-")

# The blue key, taken strafing past it, the oracle's script: 20 idle
# tics, a turn to 157.5, strafing left. Then the door refusing the
# start's inventory and opening for the inventory the key left, or for
# the blue skull alone.
def blue(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    k0 : S.State <- keyed("key turn", 1n, K.Cmd.demo(0, 0, 4294967280, False{}),
      S.Sim.replay(List.replicate(K.Cmd, 20n, idle()), at(level, 2246, 592, 180)))
    k1 : S.State <- keyed("strafe", 12n, K.Cmd.demo(0, 4294967272, 0, False{}), k0)
    k2 : S.State <- keyed("-", 1n, K.Cmd.demo(0, 4294967272, 0, False{}), k1)
    k3 : S.State <- keyed("-", 10n, K.Cmd.demo(0, 4294967272, 0, False{}), k2)
    door71("blue walk", S.Player.inv(S.State.player(S.State.start(level))), level)
    door71("blue walk with the key", S.Player.inv(S.State.player(k3)), level)
    door71("blue walk with the skull", I.Inventory.card(8, I.Inventory.start()), level)

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

def door(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    d0 : S.State <- run("door walk", 40n, forward(), [10], at(level, 832, 384, 90))
    used(d0)
    floors(level)
    crossed(level)
    lift(level)
    blue(level)
    exits(level)
    lights([1n, 34n, 1n, 4n, 1n, 23n, 1n, 1n, 1n, 2n, 2n, 60n, 1n, 2n, 1n, 1n, 1n, 1n, 4n, 1n, 0n], S.State.start(level))

def count(things: List<&2, H.Thing>, +kind: U32) -> U32:
  match things:
    case []:
      0
    case H.Thing{id, k, x, y, z, sector, state, tics} <> rest:
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
    case H.Thing{id, kind, x, y, z, sector, state, tics} <> rest:
      " " ++ U32.show(id) ++ ids(rest)

def described(d: Maybe<&2, H.Thing.Def>) -> String:
  match d:
    case None{}:
      " undefined"
    case Some{H.Def{kind, state, radius, height, flags}}:
      " radius " ++ U32.show(radius) ++ " height " ++ U32.show(height) ++ " flags " ++ U32.show(flags)

def shown(hit: Bool, t: H.Thing, rest: String) -> String:
  match hit:
    case False{}:
      rest
    case True{}:
      H.Thing{id, +kind, x, y, z, sector, state, tics} = t
      "thing " ++ U32.show(id) ++ " type " ++ U32.show(kind) ++ " at " ++ F.Fixed.show(x) ++ " " ++ F.Fixed.show(y)
        ++ " z " ++ F.Fixed.show(z) ++ " sector " ++ U32.show(sector) ++ " state " ++ U32.show(state) ++ " tics "
        ++ U32.show(tics) ++ described(H.Thing.def(kind))

# The line of the thing named id, empty when none has that name.
def thing(things: List<&2, H.Thing>, +id: U32) -> String:
  match things:
    case []:
      ""
    case H.Thing{+i, kind, x, y, z, sector, state, tics} <> rest:
      shown(U32.is_eq(i, id), H.Thing{i, kind, x, y, z, sector, state, tics}, thing(rest, id))

def things(chosen: List<&2, U32>, +s: S.State) -> IO(Unit):
  match chosen:
    case []:
      IO.pure(Unit, Unit{})
    case id <> rest:
      do IO<Unit>:
        IO.print(thing(S.State.things(s), id))
        things(rest, s)

def words(+v: V.Vec, n: Nat, +i: U32) -> String:
  match n:
    case 0n:
      ""
    case 1n+m:
      " " ++ U32.show(V.Vec.get(v, i)) ++ words(v, m, (i + 1 : U32))

def inventory(inv: I.Inventory) -> String:
  I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  "inventory health " ++ U32.show(health) ++ " armour " ++ U32.show(armour) ++ " type " ++ U32.show(armourtype)
    ++ " cards " ++ U32.show(cards) ++ " ammo" ++ words(ammo, 4n, 0) ++ " caps" ++ words(caps, 4n, 0)
    ++ " backpack " ++ Bool.show(backpack) ++ " weapons " ++ U32.show(weapons) ++ " powers" ++ words(powers, 6n, 0)
    ++ " items " ++ U32.show(items) ++ " flash " ++ U32.show(bonus)

def free(+s: S.State) -> IO(S.State):
  +p = S.State.player(s)
  +spawned = S.State.things(s)
  do IO<S.State>:
    IO.print("free at start " ++ Bool.show(S.Sim.free(S.State.level(s), S.Player.x(p), S.Player.y(p))))
    IO.print(inventory(S.Player.inv(p)))
    IO.print("things at start " ++ Nat.show(List.length(&2, H.Thing, spawned)) ++ " random "
      ++ U32.show(S.State.rnd(s)))
    IO.print("by type" ++ kinds(H.Thing.defs(), spawned))
    IO.print("first" ++ ids(List.take(&2, H.Thing, spawned, 12n)))
    things([2, 6, 29, 87, 245, 291], s)
    return s


def missing(hit: Bool, +id: U32, rest: String) -> String:
  match hit:
    case True{}:
      rest
    case False{}:
      " " ++ U32.show(id) ++ rest

# The names of the things of before no longer in after.
def gone(before: List<&2, H.Thing>, +after: List<&2, H.Thing>) -> String:
  match before:
    case []:
      ""
    case H.Thing{+i, kind, x, y, z, sector, state, tics} <> rest:
      missing(present(after, i), i, gone(rest, after))

def ammo(inv: I.Inventory) -> String:
  I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  " ammo" ++ words(ammo, 4n, 0) ++ " caps" ++ words(caps, 4n, 0) ++ " backpack " ++ Bool.show(backpack)
    ++ " weapons " ++ U32.show(weapons) ++ " flash " ++ U32.show(bonus)

# A run, then the names of the things taken since the case's first state,
# how many things are left, and the ammo, caps, backpack and weapons.
def picked(tag: String, n: Nat, cmd: K.Cmd, +first: S.State, s: S.State) -> IO(S.State):
  +q = S.Sim.replay(List.replicate(K.Cmd, n, cmd), s)
  do IO<S.State>:
    IO.print(tag ++ " tic " ++ U32.show(S.State.clock(q)) ++ " taken" ++ gone(S.State.things(first), S.State.things(q))
      ++ " things " ++ Nat.show(List.length(&2, H.Thing, S.State.things(q))) ++ ammo(S.Player.inv(S.State.player(q))))
    return q

# An inventory as G_PlayerReborn's but for the ammo in ammotype_t order
# and the weapons owned.
def stocked(bullets: U32, shells: U32, cells: U32, rockets: U32, weapons: U32) -> I.Inventory:
  I.Inventory{100, 0, 0, 0, V.Vec.of_list([bullets, shells, cells, rockets], 4), V.Vec.of_list([200, 50, 300, 50], 4),
    False{}, weapons, V.Vec.of_list([0, 0, 0, 0, 0, 0], 6), 0, 0}

def spawn.things(s: H.Thing.Spawn) -> List<&2, H.Thing>:
  H.Spawn{things, rnd} = s
  things

def spawned(r: L.Level.Thing, +level: L.Level, id: U32) -> List<&2, H.Thing>:
  L.Thing{+x, +y, angle, +kind, options} = r
  spawn.things(H.Thing.spawn.mobj(H.Thing.info(kind), level, id, x, y, H.Spawn{[], 0}))

# The state with a record the easier skills alone spawn put after its
# things, as P_SpawnMobj places it.
def adding(+level: L.Level, +id: U32, s: S.State) -> S.State:
  S.State{p, lv, things, sidetex, thinkers, rnd, clock, ended, usedown} = s
  S.State{p, lv, List.append(&2, H.Thing, things, spawned(L.Level.thing(level, id), level, id)), sidetex, thinkers,
    rnd, clock, ended, usedown}

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
    f : S.State <- walked("shells walk at the cap", 8n, holding(stocked(50, 50, 0, 0, 3), at(level, 1060, 65312, 0)))
    f2 : S.State <- picked("-", 17n, forward(), at(level, 1060, 65312, 0), f)
    r : S.State <- walked("rocket walk", 8n, at(level, 700, 64536, 180))
    r2 : S.State <- walked("rocket walk at the cap", 8n, holding(stocked(50, 0, 0, 50, 3), at(level, 700, 64536, 180)))
    IO.print("-")

# The shell box behind the closet door west of the clips, with room,
# one clip short of the cap, and at it: an idle tic, since the player
# starts with use held, the use, the door rising, the walk.
def box(tag: String, +s: S.State) -> IO(Unit):
  +opened = S.Sim.replay(List.concat(&2, K.Cmd, [[idle(), use()], List.replicate(K.Cmd, 30n, idle())]), s)
  do IO<Unit>:
    b : S.State <- walked(tag, 19n, opened)
    IO.print("-")

# The backpack, record 288, walked into from the east along the south
# wall, out of the rocket's reach: the first, and later ones with the
# first's inventory and with every doubled cap full.
def backpack(tag: String, inv: I.Inventory, +level: L.Level) -> IO(S.State):
  walked(tag, 11n, adding(level, 288, holding(inv, at(level, 720, 64496, 180))))

# The shotgun, record 256, walked into from the north: not owned, owned
# with room for its shells, owned at the cap, and not owned at the cap.
def shotgun(tag: String, inv: I.Inventory, +level: L.Level) -> IO(S.State):
  walked(tag, 11n, adding(level, 256, holding(inv, at(level, 816, 700, 270))))

# The chainsaw on its step, strafed past on the key's script: not owned,
# then owned.
def chainsaw(tag: String, inv: I.Inventory, +level: L.Level) -> IO(S.State):
  +s = holding(inv, at(level, 3158, 2176, 180))
  do IO<S.State>:
    a : S.State <- picked(tag, 12n, K.Cmd.demo(0, 4294967272, 0, False{}), s,
      S.Sim.replay(List.append(&2, K.Cmd, List.replicate(K.Cmd, 20n, idle()),
        [K.Cmd.demo(0, 0, 4294967280, False{})]), s))
    picked("-", 1n, K.Cmd.demo(0, 4294967272, 0, False{}), s, a)

def pickups(+level: L.Level) -> IO(Unit):
  do IO<Unit>:
    loose(level)
    box("shell box walk", at(level, 600, 712, 180))
    box("shell box walk short of the cap", holding(stocked(50, 45, 0, 0, 3), at(level, 600, 712, 180)))
    box("shell box walk at the cap", holding(stocked(50, 50, 0, 0, 3), at(level, 600, 712, 180)))
    p : S.State <- backpack("backpack walk", I.Inventory.start(), level)
    p2 : S.State <- backpack("later backpack walk", S.Player.inv(S.State.player(p)), level)
    p3 : S.State <- backpack("later backpack walk at the doubled caps", I.Inventory{100, 0, 0, 0,
      V.Vec.of_list([400, 100, 600, 100], 4), V.Vec.of_list([400, 100, 600, 100], 4), True{}, 3,
      V.Vec.of_list([0, 0, 0, 0, 0, 0], 6), 0, 0}, level)
    g : S.State <- shotgun("shotgun walk", I.Inventory.start(), level)
    g2 : S.State <- shotgun("owned shotgun walk", S.Player.inv(S.State.player(g)), level)
    g3 : S.State <- shotgun("owned shotgun walk at the cap", stocked(50, 50, 0, 0, 7), level)
    g4 : S.State <- shotgun("shotgun walk at the cap", stocked(50, 50, 0, 0, 3), level)
    w : S.State <- chainsaw("chainsaw strafe", I.Inventory.start(), level)
    w2 : S.State <- chainsaw("owned chainsaw strafe", S.Player.inv(S.State.player(w)), level)
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
#|thing 2 type 2005 at 3104.000000 2160.000000 z 194.000000 sector 139 state 21 tics 4294967295 radius 20 height 16 flags 1
#|thing 6 type 2018 at 1664.000000 1088.000000 z -144.000000 sector 130 state 30 tics 5 radius 20 height 16 flags 1
#|thing 29 type 60 at 1184.000000 288.000000 z 60.000000 sector 153 state 16 tics 4294967295 radius 20 height 68 flags 768
#|thing 87 type 5 at 2192.000000 576.000000 z 136.000000 sector 35 state 0 tics 3 radius 20 height 16 flags 33554433
#|thing 245 type 19 at 1248.000000 224.000000 z 16.000000 sector 170 state 6 tics 4294967295 radius 20 height 16 flags 0
#|thing 291 type 2023 at 608.000000 480.000000 z 0.000000 sector 150 state 32 tics 4294967295 radius 20 height 16 flags 8388609
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
#|clip walk tic 9 taken things 180 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 10 taken 140 things 179 ammo 60 0 0 0 caps 200 50 300 50 backpack False weapons 3 flash 6
#|shells walk tic 8 taken things 180 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 9 taken 276 things 179 ammo 50 4 0 0 caps 200 50 300 50 backpack False weapons 3 flash 6
#|- tic 26 taken 207 208 276 things 177 ammo 50 12 0 0 caps 200 50 300 50 backpack False weapons 3 flash 6
#|shells walk at the cap tic 8 taken things 180 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 9 taken things 180 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 26 taken things 180 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|rocket walk tic 8 taken things 180 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 9 taken 279 things 179 ammo 50 0 0 1 caps 200 50 300 50 backpack False weapons 3 flash 6
#|rocket walk at the cap tic 8 taken things 180 ammo 50 0 0 50 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 9 taken things 180 ammo 50 0 0 50 caps 200 50 300 50 backpack False weapons 3 flash 0
#|-
#|shell box walk tic 51 taken things 180 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 52 taken 137 things 179 ammo 50 20 0 0 caps 200 50 300 50 backpack False weapons 3 flash 6
#|-
#|shell box walk short of the cap tic 51 taken things 180 ammo 50 45 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 52 taken 137 things 179 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 flash 6
#|-
#|shell box walk at the cap tic 51 taken things 180 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 52 taken things 180 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|-
#|backpack walk tic 11 taken things 181 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 12 taken 288 things 180 ammo 60 4 20 1 caps 400 100 600 100 backpack True weapons 3 flash 6
#|later backpack walk tic 11 taken things 181 ammo 60 4 20 1 caps 400 100 600 100 backpack True weapons 3 flash 0
#|- tic 12 taken 288 things 180 ammo 70 8 40 2 caps 400 100 600 100 backpack True weapons 3 flash 6
#|later backpack walk at the doubled caps tic 11 taken things 181 ammo 400 100 600 100 caps 400 100 600 100 backpack True weapons 3 flash 0
#|- tic 12 taken 288 things 180 ammo 400 100 600 100 caps 400 100 600 100 backpack True weapons 3 flash 6
#|shotgun walk tic 11 taken things 181 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 12 taken 256 things 180 ammo 50 8 0 0 caps 200 50 300 50 backpack False weapons 7 flash 6
#|owned shotgun walk tic 11 taken things 181 ammo 50 8 0 0 caps 200 50 300 50 backpack False weapons 7 flash 0
#|- tic 12 taken 256 things 180 ammo 50 16 0 0 caps 200 50 300 50 backpack False weapons 7 flash 6
#|owned shotgun walk at the cap tic 11 taken things 181 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 7 flash 0
#|- tic 12 taken things 181 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 7 flash 0
#|shotgun walk at the cap tic 11 taken things 181 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 12 taken 256 things 180 ammo 50 50 0 0 caps 200 50 300 50 backpack False weapons 7 flash 6
#|chainsaw strafe tic 33 taken things 180 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 3 flash 0
#|- tic 34 taken 2 things 179 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 131 flash 6
#|owned chainsaw strafe tic 33 taken things 180 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 131 flash 0
#|- tic 34 taken things 180 ammo 50 0 0 0 caps 200 50 300 50 backpack False weapons 131 flash 0
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
#|blue walk tic 30 831.941818 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.024505 thinkers 9 sector 71 -128.000000 -128.000000 key True things 180 cards 0 flash 0
#|use tic 31 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000 key True things 180 cards 0 flash 0
#|- tic 41 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000 key True things 180 cards 0 flash 0
#|- tic 92 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 9 sector 71 -128.000000 -128.000000 key True things 180 cards 0 flash 0
#|-
#|blue walk with the key tic 30 831.941818 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.024505 thinkers 9 sector 71 -128.000000 -128.000000 key True things 180 cards 1 flash 0
#|use tic 31 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -126.000000 key True things 180 cards 1 flash 0
#|- tic 41 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -106.000000 key True things 180 cards 1 flash 0
#|- tic 92 831.939605 1463.978836 90.000 z -128.000000 floor -128.000000 eye 41.000000 thinkers 10 sector 71 -128.000000 -4.000000 key True things 180 cards 1 flash 0
#|-
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
